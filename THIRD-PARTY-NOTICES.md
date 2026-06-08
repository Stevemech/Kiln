# Third-Party Notices

The Kiln binary is a standalone executable produced with `bun build --compile`. It **bundles**
the JavaScript dependencies listed below, and **invokes** two external programs at runtime that
it does NOT bundle (the `opencode` CLI, and your chosen model backend). Their licenses and
copyright notices are preserved here and apply to the corresponding portions of the distribution.

Kiln itself is distributed under the terms in `LICENSE` (which also reproduces the full opencode
and LM Studio SDK license texts).

## Runtime (not bundled — invoked from your system)

- **opencode** — https://opencode.ai — **MIT License** (Copyright © 2025 opencode). Kiln spawns
  the `opencode` CLI for the agent loop; it is installed separately and runs as its own process.
- **Bun** — https://bun.sh — **MIT License**. The compiled binary embeds the Bun runtime.
- Your **model backend** (LM Studio, Ollama, or another OpenAI-compatible server) is separate
  software under its own license, run by you.

## Bundled JavaScript dependencies

| Package | License |
| --- | --- |
| `@opencode-ai/sdk` | MIT |
| `@lmstudio/sdk` | Apache-2.0 |
| `ollama` | MIT |
| `ink` | MIT |
| `react` | MIT |
| `marked` | MIT |
| `marked-terminal` | MIT |
| `cli-highlight` | ISC |

Plus their transitive dependencies (e.g. `cross-spawn`, `ws`, `yoga-layout`, `react-reconciler`,
`chalk`), all under permissive licenses (MIT / ISC / Apache-2.0 / BSD).

### MIT License (applies to the MIT-licensed packages above and their MIT transitive deps)

```
Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

### Apache-2.0 (`@lmstudio/sdk`)

Licensed under the Apache License, Version 2.0: https://www.apache.org/licenses/LICENSE-2.0
Distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND.

### ISC (`cli-highlight`)

```
Permission to use, copy, modify, and/or distribute this software for any purpose with or without
fee is hereby granted, provided that the above copyright notice and this permission notice appear
in all copies. THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE.
```

A full, per-package machine-readable inventory can be regenerated from a source checkout with a
license tool (e.g. `bunx license-checker-rseidelsohn --production`).
