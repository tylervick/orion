# Project Log

## 2024-02-04

### Initial thoughts/high-level design

The goal here is to build a WebKit wrapper with Web Extension support. Off the top of my head, I know that the big 3 browsers (Chrome, Firefox, and Safari) all have their own implementations of the Web Extension APIs. (I can add a MDN/caniuse link here later)

Breaking this down into a few components to start:
1. The compiled WebKit framework (via github.com/WebKit/WebKit.git)
2. Orion "front-end" (the AppKit stuff)
  - 2.1 Basic browser UI
    - 2.1.1 address bar, nav buttons, download management, probably gesture support for my own sanity
  - 2.2 Extension UI
    - 2.2.1 Extension management (i.e. install, uninstall)
    - 2.2.2 Browser integration (i.e. toolbar button)
  - 2.3 WebKit configuration
3. Orion "back-end"
  - 3.1. Web Extension Support
    - 3.1.1 API support (i.e. WebKit navigation delegate)
    - 3.1.2 Extension management (i.e. install, uninstall)
    - 3.1.3 Execution environment, observability (console, debugging, etc)


### Project Structure

Given it's AppKit, Xcode is more or less the only option. Following the above structure, there will be a few targets:
- Orion (the main app)
- OrionBridge (the thing that interacts with JS)
- WebKit (the compiled WebKit framework)

I'll start out by just compiling WebKit and embedding it as an "external" framework. A downside of this is that I'll need to manually ensure that the precompiled framework matches the architecture and configuration of the app.
The WebKit repo has xcworkspace/proj files but it'll require some tweaking to get it working as a target dependency.


### Web Extension Support

Since the requirements specifically refer to Mozilla's addon store, I plan to align with Firefox's Web Extension implementation.

Some thoughts/questions:
- What is the required metadata for a given extension? (i.e. manifest.json, v2/v3, etc)
- How should the extension be packaged? (i.e. .xpi, .zip, etc)

