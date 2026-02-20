Great questions! Let me look up the latest info on both.Here's a comprehensive breakdown for your team:

---

## 🌐 Argos Translate

**Languages supported:** Around **30 languages** with direct translation packages available. These include Arabic, Azerbaijani, Catalan, Chinese, Czech, Danish, Dutch, English, Esperanto, Finnish, French, German, Greek, Hebrew, Hindi, Hungarian, Indonesian, Irish, Italian, Japanese, Korean, Persian, Polish, Portuguese, Russian, Slovak, Spanish, Swedish, Turkish, and Ukrainian. It can also pivot through intermediate languages (e.g., Spanish → English → French) to support more pairs, though with some quality trade-off.

**Platform compatibility for your stack:**

| Platform | Compatible? | Notes |
|---|---|---|
| **Flutter** | ❌ No native plugin | It's Python-based; no Flutter SDK exists |
| **Swift (iOS)** | ❌ No | Python-only library |
| **Kotlin (Android)** | ❌ No | Python-only library |
| **Next.js (Web)** | ⚠️ Indirect only | You'd need to self-host it as a backend API (via LibreTranslate which runs on top of Argos), then call it from your Next.js app |

**Bottom line on Argos:** It's not directly embeddable in mobile or frontend apps. The practical path for your stack is to host **LibreTranslate** (which wraps Argos) on a server and use its REST API — free if self-hosted, zero per-call cost.

---

## 📱 Google ML Kit Translation

**Languages supported:** More than 50 languages, powered by the same models used by Google Translate's offline mode. It works entirely on-device after downloading language packs (~30MB each).

**Platform compatibility for your stack:**

| Platform | Compatible? | Notes |
|---|---|---|
| **Flutter** | ✅ Yes | Use the `google_mlkit_translation` package on pub.dev |
| **Swift (iOS)** | ✅ Yes | Native ML Kit iOS SDK supported |
| **Kotlin (Android)** | ✅ Yes | Native ML Kit Android SDK supported |
| **Next.js (Web)** | ❌ No | ML Kit was built only for mobile platforms (iOS and Android); web is not supported |

**Important notes:**
- All translations happen **on-device** — no internet needed after the initial language pack download, and no API costs ever.
- ML Kit's translation models are trained to translate to and from English, so direct translation between two non-English languages (e.g., French → Japanese) may go through English internally, which can affect quality.
- Each language model is about **30MB**, so you'll want to download them on demand rather than bundling them all.

---

## 🧭 Recommendation for Your Stack

Given you have Flutter, Swift, Kotlin, and Next.js, here's a practical hybrid approach:

**For mobile (Flutter/Swift/Kotlin):** Use **Google ML Kit** — it's free, offline, and has official support for all three.

**For Next.js (web):** Self-host **LibreTranslate** (backed by Argos Translate) on a cheap VPS or a free-tier cloud instance, and call it via REST API. This keeps costs at zero.

This way you get completely free translation across all your platforms with no per-call fees. Want help with the integration code for any of these?