## 2024-05-18 - Missing crossOrigin on Dynamically Injected Scripts
**Vulnerability:** Dynamically injected third-party scripts via `document.createElement("script")` did not have the `crossOrigin="anonymous"` attribute set.
**Learning:** By default, browsers do not perform CORS checks when executing standard `<script>` tags without `crossOrigin`. This suppresses detailed error reporting to `window.onerror` (showing only "Script error") due to security restrictions and prevents the implementation of Subresource Integrity (SRI) which requires CORS.
**Prevention:** Always add `script.crossOrigin = "anonymous";` when dynamically loading scripts from external domains (CDNs) before injecting them into the DOM.
## 2026-07-11 - Unpinned Third-Party Script Dependencies
**Vulnerability:** Dynamically injected third-party scripts were loading from unpinned URLs like `@latest` and raw unpkg domain.
**Learning:** Loading external libraries without pinning versions leaves the codebase open to supply-chain attacks, where an attacker could update the library upstream or hijack the "latest" tag to serve malicious code.
**Prevention:** Pin all third party JS libraries to a specific verified version (e.g., `@1.3.18`) and consider using SRI hashes.
