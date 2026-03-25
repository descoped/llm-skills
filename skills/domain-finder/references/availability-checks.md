# Availability Checks

How to verify domain and name availability across registrars, package registries, and platforms.

## Domain Availability via whois

### Important: Use the correct whois server

The default macOS `whois` often queries IANA first, which returns registry info instead of domain availability. **Always specify the whois server directly** with `-h` for reliable results.

### Whois Servers and "Not Found" Patterns

| TLD | Whois server | "Not found" indicator |
|-----|-------------|----------------------|
| `.com` | `whois.verisign-grs.com` | `No match for domain` |
| `.net` | `whois.verisign-grs.com` | `No match for domain` |
| `.org` | `whois.publicinterestregistry.org` | `Domain not found` |
| `.no` | `whois.norid.no` | `% No match` |
| `.io` | `whois.nic.io` | `NOT FOUND` |
| `.dev` | `whois.nic.google` | `Domain not found` |
| `.app` | `whois.nic.google` | `Domain not found` |
| `.ai` | `whois.nic.ai` | `NOT FOUND` |
| `.co` | `whois.nic.co` | `No Data Found` |
| `.me` | `whois.nic.me` | `NOT FOUND` |

### The Script

Default TLD is `.com`. Use per-domain timeouts to avoid hanging on unresponsive whois servers:

```bash
# Single TLD check (default: .com)
WHOIS_SERVER="whois.verisign-grs.com"
TLD="com"

for domain in candidate1 candidate2 candidate3; do
  result=$(timeout 5 whois -h "$WHOIS_SERVER" "${domain}.${TLD}" 2>/dev/null | grep -iE "No match|NOT FOUND|No Data Found|Domain not found|No entries found|AVAILABLE|Status: free|is free")
  if [ -n "$result" ]; then
    echo "AVAILABLE: ${domain}.${TLD}"
  fi
done
```

For checking multiple TLDs in one pass:

```bash
check_tld() {
  local domain="$1" tld="$2" server="$3"
  result=$(timeout 5 whois -h "$server" "${domain}.${tld}" 2>/dev/null | grep -ciE "No match|NOT FOUND|No Data Found|Domain not found|No entries found")
  [ "$result" -gt 0 ] && echo "AVAILABLE: ${domain}.${tld}"
}

for domain in candidate1 candidate2 candidate3; do
  check_tld "$domain" "com" "whois.verisign-grs.com"
  check_tld "$domain" "no"  "whois.norid.no"
  check_tld "$domain" "org" "whois.publicinterestregistry.org"
  check_tld "$domain" "net" "whois.verisign-grs.com"
done
```

### RDAP Alternative

Some newer TLDs use RDAP instead of whois. If whois returns nothing useful, try:

```bash
curl -s "https://rdap.org/domain/${domain}.TLD" 2>/dev/null | grep -q '"errorCode"' && echo "AVAILABLE" || echo "TAKEN"
```

### Rate Limiting

- **Batch size:** 20-25 domains per batch to avoid rate limits
- **Pause between batches:** 2-3 seconds (`sleep 2` between batches)
- **If you get errors:** reduce to 10-15 per batch
- **Some registrars block after ~50 queries:** switch to a different DNS-based check if needed

### DNS Fallback

If whois is rate-limited, a quick DNS check can pre-filter (though it's not definitive — parked domains have DNS records):

```bash
dig +short "${domain}.TLD" A 2>/dev/null | grep -q '.' && echo "HAS DNS (likely taken)" || echo "NO DNS (possibly available)"
```

---

## Package Registry Checks

For developer tools, the package name matters as much as the domain. Check these registries:

### npm

```bash
npm view PACKAGE_NAME 2>/dev/null && echo "TAKEN on npm" || echo "AVAILABLE on npm"
```

### PyPI

```bash
curl -s -o /dev/null -w "%{http_code}" "https://pypi.org/pypi/PACKAGE_NAME/json" | grep -q "404" && echo "AVAILABLE on PyPI" || echo "TAKEN on PyPI"
```

### crates.io (Rust)

```bash
curl -s -o /dev/null -w "%{http_code}" "https://crates.io/api/v1/crates/PACKAGE_NAME" | grep -q "404" && echo "AVAILABLE on crates.io" || echo "TAKEN on crates.io"
```

### Go modules

```bash
curl -s -o /dev/null -w "%{http_code}" "https://pkg.go.dev/github.com/ORG/PACKAGE_NAME" | grep -q "404" && echo "AVAILABLE" || echo "TAKEN"
```

---

## GitHub Organization / Username

```bash
curl -s -o /dev/null -w "%{http_code}" "https://github.com/NAME" | grep -q "404" && echo "AVAILABLE on GitHub" || echo "TAKEN on GitHub"
```

---

## Batch Check Script

Combine all checks for developer-focused projects:

```bash
# Map TLD to whois server
whois_server() {
  case "$1" in
    com|net) echo "whois.verisign-grs.com" ;;
    org)     echo "whois.publicinterestregistry.org" ;;
    no)      echo "whois.norid.no" ;;
    io)      echo "whois.nic.io" ;;
    dev|app) echo "whois.nic.google" ;;
    ai)      echo "whois.nic.ai" ;;
    co)      echo "whois.nic.co" ;;
    me)      echo "whois.nic.me" ;;
    *)       echo "whois.iana.org" ;;
  esac
}

check_name() {
  local name="$1"
  local tld="${2:-com}"
  local server
  server=$(whois_server "$tld")
  local results=""

  # Domain
  avail=$(timeout 5 whois -h "$server" "${name}.${tld}" 2>/dev/null | grep -ciE "No match|NOT FOUND|No Data Found|Domain not found|No entries found|AVAILABLE|Status: free|is free")
  [ "$avail" -gt 0 ] && results="${results} domain:yes" || results="${results} domain:no"

  # npm
  npm view "$name" 2>/dev/null >/dev/null && results="${results} npm:no" || results="${results} npm:yes"

  # PyPI
  code=$(curl -s -o /dev/null -w "%{http_code}" "https://pypi.org/pypi/${name}/json")
  [ "$code" = "404" ] && results="${results} pypi:yes" || results="${results} pypi:no"

  # GitHub
  code=$(curl -s -o /dev/null -w "%{http_code}" "https://github.com/${name}")
  [ "$code" = "404" ] && results="${results} github:yes" || results="${results} github:no"

  echo "${name}.${tld} ${results}"
}

for name in candidate1 candidate2 candidate3; do
  check_name "$name" "com"
done
```

---

## Caveats

- **whois says available ≠ registrable** — some domains are reserved, premium-priced, or in redemption period
- **DNS exists ≠ taken** — some registrars set up DNS for parked/available domains
- **Package registries are first-come** — availability can change between checking and registering
- **Trademark risk** — domain availability says nothing about trademark conflicts. Always recommend the user do a separate trademark search for their final pick.
