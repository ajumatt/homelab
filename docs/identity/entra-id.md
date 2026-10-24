# Entra ID and hybrid identity

The on-prem domain (`home.lan`) syncs to a Microsoft Entra ID tenant on the free tier. Users sign in to Windows with their domain account and get a cloud identity under the public domain (`example.com`) with MFA.

## Tenant setup

1. Created the tenant from an existing Azure subscription.
2. Created two cloud-only accounts before anything else: a day-to-day admin and a break-glass Global Admin. Both have MFA. Neither syncs from AD, so a broken sync or a dead DC can't lock me out of the tenant.
3. Verified `example.com` in Entra with a TXT record in Cloudflare.
4. Added `example.com` as a UPN suffix in AD (Active Directory Domains and Trusts) so users can have `user@example.com` sign-in names.

## Cloud Sync

Uses Entra Cloud Sync, not the older Entra Connect Sync. Classic Connect was tried first on DC01 and never worked cleanly. It was removed completely (ADSync service and its gMSA gone) before Cloud Sync went in, since the two shouldn't run against the same objects.

- Provisioning agent installed on DC02.
- Password hash sync on.
- Scoping is by security group ("Entra Sync Users"), not by OU. Cloud Sync supports one or the other per configuration, never both.
- OU structure `OU=Entra Sync` with a `Workstations` child for computers.
- Rolled out with a single pilot account first, then switched real users' UPNs to `@example.com` and added them to the group.
- Service accounts (for example the SavaPage LDAP bind account) stay out of scope.

Because scoping is group-based, a user or computer moved into the right OU still doesn't sync until it's added to the group:

```powershell
Add-ADGroupMember "Entra Sync Users" -Members (Get-ADComputer PC-NAME)
```

New domain joins land in `CN=Computers`. Redirect them so they're at least in the right place:

```powershell
redircmp "OU=Workstations,OU=Entra Sync,DC=home,DC=lan"
```

### Problems hit

- The pilot account came across disabled. It had failed the domain password policy when created. Fixing the password and re-enabling it in AD fixed the cloud side on the next cycle.
- Device objects returned ResourceNotFound in Provision on demand, and the Device tab was missing. Device sync is a separate switch under the configuration's Properties > Basics and it's off by default. A missing Device tab is the tell; check that before chasing scoping or replication.

## Hybrid join

Cloud Sync handles Microsoft Entra hybrid join now, so Connect wasn't needed for devices either. Agent version has to be 1.1.1107 or later:

```powershell
(Get-Item "C:\Program Files\Microsoft Azure AD Connect Provisioning Agent\AADConnectProvisioningAgent.exe").VersionInfo.ProductVersion
```

Steps:

1. Create the service connection point (SCP) in the forest with Microsoft's `ConfigureSCP.ps1` (from the Cloud Sync device sync page on Microsoft Learn). Check whether one already exists first, since an earlier Connect attempt can leave one behind:

```powershell
$cfg = (Get-ADRootDSE).configurationNamingContext
Get-ADObject -Filter * -SearchBase "CN=Device Registration Configuration,CN=Services,$cfg" -Properties keywords |
  Select Name, keywords
```

2. Turn on device sync in the Cloud Sync configuration.
3. Put the computer in the sync group.
4. On the PC, run the Automatic-Device-Join task (Task Scheduler > Microsoft > Windows > Workplace Join) from an admin prompt, or just sign out and in.
5. Wait for Cloud Sync to copy the computer object, then sign out and in again.
6. Check `dsregcmd /status`: `AzureAdJoined : YES`, `DomainJoined : YES`, `AzureAdPrt : YES`.

The order matters. The task's first run reads the SCP and writes a self-signed certificate to the computer object's `userCertificate` attribute. Sync has to carry that certificate to Entra before the second run can register the device. If a PC ever falls out of hybrid join (`dsregcmd /leave`), the same task rejoins it.

Several PCs are hybrid joined and show in Entra as Microsoft Entra hybrid joined.

## Nextcloud SSO (in progress)

Nextcloud signs in through Entra with the `user_oidc` app instead of standing up Authentik. It's free on Entra ID Free; Intune and Conditional Access would need P1 licenses.

Done so far:

- App registration with a redirect URI to Nextcloud, a client secret (expiry date tracked, because SSO breaks the day it expires), Graph delegated permissions `openid`, `profile`, `email` with admin consent, and optional ID token claims `email` and `upn`.
- Users' AD `mail` attribute filled in so the email claim isn't empty.
- Enterprise app set to Assignment required, with users assigned one by one (the free tier can't assign groups to apps). Without this, every account in the tenant could sign in, break-glass included.
- `user_oidc` installed:

```bash
qm guest exec 104 -- docker exec --user www-data nextcloud-aio-nextcloud php occ app:install user_oidc
qm guest exec 104 -- docker exec --user www-data nextcloud-aio-nextcloud php occ user:list
```

Still to decide: how Entra sign-ins map to existing Nextcloud accounts. Nextcloud can't rename a user. If an SSO login lands on a new username, it gets an empty account and the files stay in the old one. If existing accounts hold files, each person signs in once with SSO and then:

```bash
occ files:transfer-ownership <old-user> <new-user>
```

Local admin login stays enabled until SSO is proven. It's the way back in.

## Open

- Second provisioning agent on DC01 so sync survives DC02 or pve2 being down.
- Disable and remove the pilot account from the sync group.
- Finish the Nextcloud mapping and provider config.
- Decide Authentik: drop it, or keep it in front of LDAP and forward-auth apps with Entra as its upstream.
