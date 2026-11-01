# Loaded last by pgAdmin (/etc/pgadmin/config_system.py), after the
# PGADMIN_CONFIG_* environment variables.
import os

# Bedrock is the only way in: the internal email/password login is off and the
# login page is skipped. PGADMIN_DEFAULT_EMAIL/PASSWORD in the Secret are only
# used once, to create pgAdmin's internal setup user on an empty data volume.
AUTHENTICATION_SOURCES = ['oauth2']
OAUTH2_AUTO_LOGIN = True
OAUTH2_AUTO_CREATE_USER = True

OAUTH2_CONFIG = [{
    'OAUTH2_NAME': 'bedrock',
    'OAUTH2_DISPLAY_NAME': 'Bedrock',
    'OAUTH2_CLIENT_ID': 'pBgGuDgDfWVJIGRKwKqrevgwAQhTrYTI',
    # From the SOPS-encrypted pgadmin-secret (see deployment.yaml).
    'OAUTH2_CLIENT_SECRET': os.environ['OAUTH2_CLIENT_SECRET'],
    'OAUTH2_SERVER_METADATA_URL': 'https://bedrock.lucawahlen.com/api/auth/.well-known/openid-configuration',
    # pgAdmin only calls the userinfo endpoint when it is named here; it does
    # not use userinfo_endpoint from the discovery document. Bedrock returns
    # email (and the role claim) from userinfo, not in the ID token, so without
    # this the login fails with "Could not extract username from OIDC claims".
    'OAUTH2_USERINFO_ENDPOINT': 'https://bedrock.lucawahlen.com/api/auth/oauth2/userinfo',
    'OAUTH2_SCOPE': 'openid profile email roles',
    'OAUTH2_USERNAME_CLAIM': 'email',
    'OAUTH2_CHALLENGE_METHOD': 'S256',
    'OAUTH2_RESPONSE_TYPE': 'code',
    # Only users holding this Bedrock role may sign in.
    'OAUTH2_ADDITIONAL_CLAIMS': {'urn:bedrock:roles': ['pgadmin-access']},
    'OAUTH2_LOGOUT_URL': 'https://bedrock.lucawahlen.com/api/auth/oauth2/end-session?id_token_hint={id_token}',
    'OAUTH2_ICON': 'fa-key',
}]
