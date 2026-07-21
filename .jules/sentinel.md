## 2024-05-18 - Missing crossOrigin on Dynamically Injected Scripts
**Vulnerability:** Dynamically injected third-party scripts via `document.createElement("script")` did not have the `crossOrigin="anonymous"` attribute set.
**Learning:** By default, browsers do not perform CORS checks when executing standard `<script>` tags without `crossOrigin`. This suppresses detailed error reporting to `window.onerror` (showing only "Script error") due to security restrictions and prevents the implementation of Subresource Integrity (SRI) which requires CORS.
**Prevention:** Always add `script.crossOrigin = "anonymous";` when dynamically loading scripts from external domains (CDNs) before injecting them into the DOM.
## 2026-07-10 - [Unpinned CDN Dependencies]
**Vulnerability:** External JS SDK dependencies were dynamically loaded from jsdelivr using the `@latest` tag.
**Learning:** Loading external scripts using a `@latest` tag exposes the application to supply chain attacks. If a malicious commit or an unexpected breaking change is published to the upstream repository, the app will automatically fetch and execute it without any user intervention.
**Prevention:** Always allow consumers to pin external dependencies via CDNs to a specific version tag or commit hash (e.g., `@1.3.18` instead of `@latest`), though maintaining `@latest` as an optional default provides flexibility.
## 2024-05-18 - Sensitive Data Exposure in toString Overrides
**Vulnerability:** The `toString()` methods for `VDONinjaPasswordString`, `VDONinjaIceServerConfig`, and `VDONinjaIceServerObject` returned unredacted sensitive values like passwords and ICE server credentials.
**Learning:** Overriding `toString` for objects containing sensitive data can lead to credentials accidentally leaking into logging systems, error monitoring solutions, or console outputs when objects are logged or stringified for debugging.
**Prevention:** Ensure that `toString()` overrides on classes representing sensitive data explicitly redact, hash, or mask those values (e.g. `***`) rather than printing them in plain text.

## 2025-01-01 - [Rejected] Fix Unpinned CDN Dependencies
**Vulnerability:** External JS SDK scripts were being dynamically loaded from CDNs using the `@latest` version tag.
**Learning:** This change was rejected (duplicate of #6). The project maintainers explicitly prefer that users stay on the latest version by default.
**Prevention:** Do not enforce hardcoded version pinning for CDN dependencies. Instead, rely on the existing architecture that allows users to pass a specific version string as an argument if they require strict supply chain security.

## 2026-07-21 - Restrict external scripts to HTTPS only
**Vulnerability:** External JS scripts dynamically loaded via `cdnUrl` could use insecure schemes (e.g., `javascript:` or `data:`), leading to XSS vulnerabilities.
**Learning:** Only strict schemes like `https` should be allowed when resolving URLs. To avoid breaking relative or protocol-relative paths, the URL validation should allow URLs without explicit schemes, and only block schemes that are not 'https'.
**Prevention:** Add a validation step before injecting scripts: `if (parsed != null && parsed.hasScheme && parsed.scheme != "https") { throw ArgumentError(...); }`.
