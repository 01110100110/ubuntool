#!/bin/bash

# Backup original PAM configuration files
cp /etc/pam.conf /etc/pam.conf.bak
cp -R /etc/pam.d /etc/pam.d.bak

# Function to rollback changes in case of errors
rollback_changes() {
    echo "Error occurred. Rolling back changes..."
    # Restore original PAM configuration files from backups
    cp /etc/pam.conf.bak /etc/pam.conf
    cp -R /etc/pam.d.bak/* /etc/pam.d/
    # Restart PAM-aware services
    service sshd restart
    service nginx restart
    # Add any other PAM-aware services that need to be restarted
    exit 1
}

# Updating PAM configuration files with sed

# Update /etc/pam.conf
sed -i '/pam_unix.so/d' /etc/pam.conf
{
  echo "auth       required     pam_unix.so"
  echo "account    required     pam_unix.so"
  echo "password   required     pam_unix.so"
  echo "session    required     pam_unix.so"
} >> /etc/pam.conf || rollback_changes

# Update /etc/pam.d/common-auth
sed -i '/pam_faillock.so/d' /etc/pam.d/common-auth
{
  echo "auth       required     pam_faillock.so preauth silent audit deny=3 unlock_time=900"
  echo "auth       [default=die] pam_faillock.so authfail audit deny=3 unlock_time=900"
  echo "auth       sufficient   pam_faillock.so authsucc audit deny=3 unlock_time=900"
} >> /etc/pam.d/common-auth || rollback_changes

# Update /etc/pam.d/common-account
sed -i '/pam_unix.so/d' /etc/pam.d/common-account
echo "account    required     pam_unix.so" >> /etc/pam.d/common-account || rollback_changes

# Update /etc/pam.d/common-password
sed -i '/pam_unix.so/d' /etc/pam.d/common-password
echo "password   required     pam_unix.so" >> /etc/pam.d/common-password || rollback_changes

# Update /etc/pam.d/common-session
sed -i '/pam_unix.so/d' /etc/pam.d/common-session
echo "session    required     pam_unix.so" >> /etc/pam.d/common-session || rollback_changes

# Restart PAM-aware services
service sshd restart || rollback_changes
service nginx restart || rollback_changes
# Add any other PAM-aware services that need to be restarted

# Cleanup backup files
rm /etc/pam.conf.bak
rm -r /etc/pam.d.bak

# PAM configuration for /etc/pam.d/login
sed -i '/pam_securetty.so/d' /etc/pam.d/login
sed -i '/pam_limits.so/d' /etc/pam.d/login
{
  echo 'auth     requisite  pam_securetty.so'
  echo 'session  required   pam_limits.so'
} >> /etc/pam.d/login || rollback_changes

# Control of su in PAM (/etc/pam.d/su)
sed -i '/pam_wheel.so/d' /etc/pam.d/su
echo 'auth     requisite   pam_wheel.so group=wheel debug' >> /etc/pam.d/su || rollback_changes

# Configuration for undefined PAM applications
sed -i '/pam_securetty.so/d' /etc/pam.d/other
sed -i '/pam_unix_auth.so/d' /etc/pam.d/other
sed -i '/pam_warn.so/d' /etc/pam.d/other
sed -i '/pam_deny.so/d' /etc/pam.d/other
sed -i '/pam_unix_acct.so/d' /etc/pam.d/other
sed -i '/pam_unix_passwd.so/d' /etc/pam.d/other
sed -i '/pam_unix_session.so/d' /etc/pam.d/other
{
  echo 'auth     required       pam_securetty.so'
  echo 'auth     required       pam_unix_auth.so'
  echo 'auth     required       pam_warn.so'
  echo 'auth     required       pam_deny.so'
  echo 'account  required       pam_unix_acct.so'
  echo 'account  required       pam_warn.so'
  echo 'account  required       pam_deny.so'
  echo 'password required       pam_unix_passwd.so'
  echo 'password required       pam_warn.so'
  echo 'password required       pam_deny.so'
  echo 'session  required       pam_unix_session.so'
  echo 'session  required       pam_warn.so'
  echo 'session  required       pam_deny.so'
} >> /etc/pam.d/other || rollback_changes

# Successful completion
echo "PAM has been updated successfully."
exit 0
