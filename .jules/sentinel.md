## 2024-05-18 - Missing crossOrigin on Dynamically Injected Scripts
**Vulnerability:** Dynamically injected third-party scripts via `document.createElement("script")` did not have the `crossOrigin="anonymous"` attribute set.
**Learning:** By default, browsers do not perform CORS checks when executing standard `<script>` tags without `crossOrigin`. This suppresses detailed error reporting to `window.onerror` (showing only "Script error") due to security restrictions and prevents the implementation of Subresource Integrity (SRI) which requires CORS.
**Prevention:** Always add `script.crossOrigin = "anonymous";` when dynamically loading scripts from external domains (CDNs) before injecting them into the DOM.
