import boto3

# ── Config ────────────────────────────────────────────────────────────────────

SECURITY_GROUP_ID = "sg-xxxxxxxxxxxxxxxxx"
REGION = "us-east-1"

# IPs to grant access (add/remove as needed)
ALLOWED_IPS = [
    "x.x.x.x",
    "y.y.y.y",
    "z.z.z.z",
]

# Ports to open for the IPs above
PORTS = [
    5432,   # PostgreSQL
    6379,   # Redis
    3306,   # MySQL
    27017,  # MongoDB
    9000,   # MinIO S3
    9001,   # MinIO Console
    1433,   # MSSQL
    8888,   # Jupyter
    4040,   # Spark Job UI
    8080,   # Spark Master UI
    8081,   # Spark Worker 1
    8082,   # Spark Worker 2
    7077,   # Spark submissions
    8998,   # Livy
]

# Rules to always keep (never delete these)
PROTECTED_PORTS = {
    22,    # SSH
    80,    # HTTP
    443,   # HTTPS
}

# ── Client ────────────────────────────────────────────────────────────────────

ec2 = boto3.client("ec2", region_name=REGION)

# ── Helpers ───────────────────────────────────────────────────────────────────

def get_existing_rules():
    sg = ec2.describe_security_groups(GroupIds=[SECURITY_GROUP_ID])
    return sg["SecurityGroups"][0]["IpPermissions"]


def is_protected(rule):
    """Return True if this rule touches SSH, HTTP, or HTTPS — never delete it."""
    from_port = rule.get("FromPort", 0)
    to_port   = rule.get("ToPort", 0)
    # covers single-port rules and ranges that overlap protected ports
    for p in PROTECTED_PORTS:
        if from_port <= p <= to_port:
            return True
    return False


def revoke_unprotected_rules(rules):
    to_revoke = [r for r in rules if not is_protected(r)]
    if not to_revoke:
        print("  Nothing to revoke.")
        return
    ec2.revoke_security_group_ingress(
        GroupId=SECURITY_GROUP_ID,
        IpPermissions=to_revoke,
    )
    print(f"  Revoked {len(to_revoke)} rule(s).")


def add_rules(ips, ports):
    permissions = []
    for port in ports:
        permissions.append({
            "IpProtocol": "tcp",
            "FromPort": port,
            "ToPort": port,
            "IpRanges": [
                {"CidrIp": f"{ip}/32", "Description": f"allowed-{ip}"}
                for ip in ips
            ],
        })
    ec2.authorize_security_group_ingress(
        GroupId=SECURITY_GROUP_ID,
        IpPermissions=permissions,
    )
    print(f"  Added {len(ports)} port(s) × {len(ips)} IP(s) = {len(ports)*len(ips)} rule(s).")


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    print(f"\nSecurity Group: {SECURITY_GROUP_ID}")

    print("\n[1] Fetching existing inbound rules...")
    rules = get_existing_rules()
    print(f"  Found {len(rules)} existing rule(s).")

    print("\n[2] Revoking non-protected rules (keeping SSH/HTTP/HTTPS)...")
    revoke_unprotected_rules(rules)

    print("\n[3] Adding rules for allowed IPs...")
    add_rules(ALLOWED_IPS, PORTS)

    print("\n✅  Done.\n")


if __name__ == "__main__":
    main()
