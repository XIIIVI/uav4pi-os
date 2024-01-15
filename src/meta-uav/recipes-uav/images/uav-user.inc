inherit extrausers

# Use openssl passwd -6 to hash a password.
#
# Example: openssl passwd -6 test
# Output: $6$Unb4UbwNq.p5wLJC$DGF8oOCUpRuCNrsyoE0T62OkPz.EZscjUWjN01tqmZ5iS89YL9OHhyOtNdh0NcAUMkW3qV62d/cY4ckE0PrLl1
#
# Dollar signs ($) should be escaped with backslash characters (\).

EXTRA_USERS_PARAMS += " useradd -p '#-USER_PASSWORD-#' #-USER_LOGIN-#; "
EXTRA_USERS_PARAMS += " usermod -aG sudo #-USER_LOGIN-#; "
EXTRA_USERS_PARAMS += " usermod -P '#-ROOT_PASSWORD-#' root; "
