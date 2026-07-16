## 2024-05-18 - Missing crossOrigin on Dynamically Injected Scripts
**Vulnerability:** Dynamically injected third-party scripts via `document.createElement("script")` did not have the `crossOrigin="anonymous"` attribute set.
**Learning:** By default, browsers do not perform CORS checks when executing standard `<script>` tags without `crossOrigin`. This suppresses detailed error reporting to `window.onerror` (showing only "Script error") due to security restrictions and prevents the implementation of Subresource Integrity (SRI) which requires CORS.
**Prevention:** Always add `script.crossOrigin = "anonymous";` when dynamically loading scripts from external domains (CDNs) before injecting them into the DOM.
## 2026-07-10 - [Unpinned CDN Dependencies]
**Vulnerability:** External JS SDK dependencies were dynamically loaded from jsdelivr using the `@latest` tag.
**Learning:** Loading external scripts using a `@latest` tag exposes the application to supply chain attacks. If a malicious commit or an unexpected breaking change is published to the upstream repository, the app will automatically fetch and execute it without any user intervention.
**Prevention:** Always allow consumers to pin external dependencies via CDNs to a specific version tag or commit hash (e.g., `@1.3.18` instead of `@latest`), though maintaining `@latest` as an optional default provides flexibility.
## 2025-01-01 - [Rejected] Fix Unpinned CDN Dependencies
**Vulnerability:** External JS SDK scripts were being dynamically loaded from CDNs using the `@latest` version tag.
**Learning:** This change was rejected (duplicate of #6). The project maintainers explicitly prefer that users stay on the latest version by default.
**Prevention:** Do not enforce hardcoded version pinning for CDN dependencies. Instead, rely on the existing architecture that allows users to pass a specific version string as an argument if they require strict supply chain security.
