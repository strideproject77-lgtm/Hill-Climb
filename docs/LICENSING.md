# Licensing and distribution

## Project license

Stride's original code is intended to use **GPL-2.0-or-later**. The repository's `LICENSE` contains the GNU GPL version 2 text; files marked `SPDX-License-Identifier: GPL-2.0-or-later` may be used under GPL version 2 or, at the recipient's option, any later GPL version.

## Reusing Husk

Husk identifies its own project code as GPL-2.0-or-later. Before importing any file:

1. Confirm the file's SPDX identifier and copyright header.
2. Preserve the original notices.
3. Add a clear modification notice and date when modifying an upstream file.
4. Record the upstream repository, exact commit/revision, file path and changes in `THIRD_PARTY_NOTICES.md`.
5. Review all linked libraries and build-time tools separately.

Do not assume every file in Husk has the same license. ATL, AOSP, QEMU, StikJIT and other dependencies have distinct terms.

## Distribution

When distributing a GPL-covered Stride build, provide recipients the complete corresponding source under the applicable GPL terms, including the source and scripts required to build and install the distributed executable. Do not add restrictions that remove recipients' GPL rights.

Keeping a repository private during development is different from distributing an executable. A private repository does not itself satisfy or trigger every public distribution obligation; obligations depend on what is copied, modified and conveyed to others.

## Explicit exclusions

Stride's current design excludes QEMU and a full Android guest. This avoids importing those components, but does not automatically make every other runtime dependency compatible. Each component still needs a license review.

## Important

This file is project compliance documentation, not legal advice. Before distributing an IPA that combines independently licensed runtimes, obtain qualified legal review.
