# API Keys Setup

The cloud providers (Gemini, DeepSeek, Grok, Groq) require API keys to function.

## Setting API Keys in Xcode

1. Open the ChatApp project in Xcode
2. Edit Scheme: **Product → Scheme → Edit Scheme** (or ⌘<)
3. Select **Run** in the sidebar
4. Go to the **Arguments** tab
5. Under **Environment Variables**, add the keys you need:

| Variable | Provider |
|----------|----------|
| `GEMINI_API_KEY` | Google Gemini |
| `DEEPSEEK_API_KEY` | DeepSeek |
| `XAI_API_KEY` | xAI Grok |
| `GROQ_API_KEY` | Groq |

These settings are stored in `xcuserdata/` which is gitignored, so your keys won't be committed.

## Getting API Keys

- **Gemini**: https://aistudio.google.com/apikey
- **DeepSeek**: https://platform.deepseek.com/
- **Grok**: https://console.x.ai/
- **Groq**: https://console.groq.com/
