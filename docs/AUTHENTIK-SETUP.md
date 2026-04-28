# Authentik Configuration Guide
## WordPress OAuth2/OIDC Integration

This guide walks through configuring Authentik as the identity provider for the
WordPress deployment on Open Telekom Cloud. The cloud-init script installs the
**OpenID Connect Generic** plugin and expects the endpoints and credentials
described here.

---

## Overview — Correct Deployment Order

There is an intentional sequencing dependency: Terraform needs the Authentik
client ID and secret to render the cloud-init script, but Authentik needs the
WordPress redirect URI to create the provider. This looks like a chicken-and-egg
problem, but it is not — **the redirect URI is fully predictable before
WordPress is deployed** because it is derived entirely from `wordpress_domain`,
which you choose upfront:

```
https://<wordpress_domain>/wp-admin/admin-ajax.php?action=openid-connect-authorize
```

The correct order is therefore:

1. **Complete Steps 1–4 of this guide** to configure Authentik, using your
   chosen `wordpress_domain`
2. **Copy the client ID and secret into `terraform.tfvars`** (Step 6)
3. **Run `tofu apply`** to deploy WordPress

Do not run `tofu apply` before completing Authentik configuration.

---

## Prerequisites

- Authentik is running and reachable at your `authentik_base_url`
  (e.g. `https://auth.example.com`)
- You are logged in as an Authentik administrator
- You have decided on your `wordpress_domain` value
  (e.g. `wordpress.example.com`) — WordPress does **not** need to be deployed yet
- DNS for `wordpress_domain` is already configured (or will be before first
  login), pointing at the ELB public IP that Terraform will output

---

## 1 — Create a Property Mapping (Scope)

Authentik needs to expose the `preferred_username` claim that the WordPress
plugin uses as the identity key.

1. Go to **Customisation → Property Mappings**
2. Click **Create** → choose **Scope Mapping**
3. Fill in:

   | Field | Value |
   |---|---|
   | Name | `WordPress Profile` |
   | Scope name | `profile` |
   | Description | `Exposes preferred_username for WordPress` |

4. In the **Expression** box enter:

   ```python
   return {
       "preferred_username": request.user.username,
       "name": request.user.name,
       "given_name": request.user.name.split(" ")[0] if request.user.name else "",
       "family_name": " ".join(request.user.name.split(" ")[1:]) if request.user.name else "",
   }
   ```

5. Click **Save**

> **Note:** If Authentik already includes `preferred_username` in its default
> profile scope mapping you can skip this step. Check under
> **Customisation → Property Mappings** — if a mapping named
> `authentik default OAuth Mapping: OpenID 'profile'` already emits
> `preferred_username`, proceed to Step 2.

---

## 2 — Create an OAuth2/OpenID Provider

1. Go to **Applications → Providers**
2. Click **Create** → choose **OAuth2/OpenID Provider**
3. Configure the **Protocol Settings** tab:

   | Field | Value |
   |---|---|
   | Name | `WordPress` |
   | Authorization flow | `default-provider-authorization-explicit-consent` (or your preferred flow) |
   | Client type | **Confidential** |
   | Client ID | Generate or enter a value — copy this into `authentik_client_id` in `terraform.tfvars` |
   | Client Secret | Auto-generated — copy this into `authentik_client_secret` in `terraform.tfvars` |

4. Configure the **Protocol Settings** continued:

   | Field | Value |
   |---|---|
   | Redirect URIs / Origins | `https://<wordpress_domain>/wp-admin/admin-ajax.php?action=openid-connect-authorize` |
   | Signing Key | `authentik Self-signed Certificate` (or your preferred key) |
   | Subject mode | **Based on the User's Username** |

   > Replace `<wordpress_domain>` with the value of your `wordpress_domain`
   > Terraform variable, e.g. `wordpress.example.com`.

5. Under **Advanced Protocol Settings**:

   | Field | Value |
   |---|---|
   | Access code validity | `minutes=1` |
   | Access Token validity | `minutes=5` |
   | Refresh Token validity | `days=30` |
   | Scopes | Select: `email`, `openid`, `profile` (include the `WordPress Profile` mapping created in Step 1) |
   | Include claims in ID token | ✅ Enabled |

6. Click **Save**

---

## 3 — Create an Application

1. Go to **Applications → Applications**
2. Click **Create**
3. Fill in:

   | Field | Value |
   |---|---|
   | Name | `WordPress` |
   | Slug | `wordpress` |
   | Provider | `WordPress` (the provider created in Step 2) |
   | Launch URL | `https://<wordpress_domain>` |
   | UI Settings → Icon | *(optional)* WordPress logo URL |

4. Click **Save**

---

## 4 — Assign Users or Groups

By default the application is visible to all users. To restrict access:

1. Open the **WordPress** application
2. Go to the **Policy / Group / User Bindings** tab
3. Click **Bind existing Policy / Group / User**
4. Choose **Group** and select the group(s) that should have WordPress access
5. Click **Save**

> Users not in a bound group will be denied at the Authentik consent screen and
> will never reach WordPress.

---

## 5 — Note the Endpoint URLs

The cloud-init script constructs all endpoint URLs from your
`authentik_base_url` variable using the standard Authentik path structure.
Verify these URLs are reachable from your WordPress instances:

| Endpoint | URL |
|---|---|
| Authorisation | `<authentik_base_url>/application/o/authorize/` |
| Token | `<authentik_base_url>/application/o/token/` |
| Userinfo | `<authentik_base_url>/application/o/userinfo/` |
| End session | `<authentik_base_url>/application/o/end-session/` |
| JWKS | `<authentik_base_url>/application/o/wordpress/jwks/` |
| OpenID Config | `<authentik_base_url>/application/o/wordpress/.well-known/openid-configuration` |

You can verify the discovery document is valid by fetching the OpenID Config
URL in a browser or with `curl`:

```bash
curl -s https://auth.example.com/application/o/wordpress/.well-known/openid-configuration | jq .
```

---

## 6 — Update terraform.tfvars

Copy the Client ID and Client Secret from the provider created in Step 2 into
your `terraform.tfvars`:

```hcl
authentik_base_url      = "https://auth.example.com"
authentik_client_id     = "<client-id-from-step-2>"
authentik_client_secret = "<client-secret-from-step-2>"
```

Then re-run:

```bash
tofu apply
```

The cloud-init script writes these values to the WordPress options table on
every instance boot, so existing instances will pick up the change on their
next reboot, or you can force it by running on any instance:

```bash
sudo bash /var/lib/cloud/instance/scripts/part-001
```

---

## 7 — Verify the Integration

1. Open a private/incognito browser window
2. Navigate to `https://<wordpress_domain>/wp-login.php`
3. You should see a **Login with OpenID Connect** button below the standard
   WordPress login form
4. Clicking it redirects to Authentik for authentication
5. After authenticating, Authentik redirects back to WordPress and logs the
   user in, creating a WordPress account if one does not exist

### Troubleshooting

**No "Login with OpenID Connect" button appears**

Check the plugin is active:
```bash
sudo -u www-data wp --path=/var/www/html/wordpress plugin status openid-connect-generic
```

**"Invalid redirect URI" error in Authentik**

Confirm the redirect URI in the Authentik provider (Step 2) matches exactly:
```
https://<wordpress_domain>/wp-admin/admin-ajax.php?action=openid-connect-authorize
```
Note the `https://` scheme — if WordPress is serving HTTP for any reason,
the redirect will not match.

**"preferred_username is missing" or users created with numeric IDs**

The profile scope mapping in Step 1 is not being applied. Open the provider in
Authentik, go to **Advanced Protocol Settings → Scopes**, confirm the
`WordPress Profile` mapping is listed under the `profile` scope.

**Login loop / redirect loop after authenticating**

This is almost always a WordPress `HTTPS` detection issue. Confirm that
`fastcgi_param HTTPS on` is present in the Nginx PHP location block
(it is set by default in the generated config) and that `FORCE_SSL_ADMIN` is
defined as `true` in `wp-config-shared.php`.

**Users can log in but have no roles / are Subscribers only**

Authentik does not map groups to WordPress roles by default. To assign roles
automatically, add a custom claim to the property mapping (Step 1):

```python
return {
    "preferred_username": request.user.username,
    "name": request.user.name,
    # Map Authentik groups to a WordPress role claim
    "wordpress_role": "administrator" if ak_is_group_member(request.user, name="WordPress Admins") else "editor",
}
```

Then in the WordPress OpenID Connect plugin settings (wp-admin →
**Settings → OpenID Connect Generic**), set **User Role** to use the
`wordpress_role` claim. This must be configured manually in the WordPress
admin UI as the plugin's role-mapping field is not exposed via WP-CLI options.

---

## 8 — Optional: Disable WordPress Password Login

Once SSO is confirmed working you can force all logins through Authentik by
adding this to `$WP_CONFIG_DIR/wp-config-shared.php` on the SFS share:

```php
// Disable the standard username/password login form.
// All authentication goes through Authentik OIDC.
add_filter( 'authenticate', function( $user, $username, $password ) {
    if ( $username || $password ) {
        return new WP_Error(
            'authentik_only',
            'Direct login is disabled. Please use the SSO button.'
        );
    }
    return $user;
}, 30, 3 );
```

> **Warning:** Apply this only after confirming at least one administrator
> account can log in via Authentik. Keep a break-glass procedure (e.g. direct
> DB access or a WP-CLI command from an ECS instance) in case Authentik
> becomes unavailable.
