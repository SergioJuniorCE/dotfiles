import { type Plugin } from "@opencode-ai/plugin"

interface CrofAiModel {
  id: string
  name: string
  context_length: number
  max_completion_tokens: number
  custom_reasoning: boolean
  pricing: {
    prompt: string
    completion: string
    cache_prompt?: string
  }
}

const VISION_MODELS = new Set([
  "kimi-k2.6", "kimi-k2.6-precision", "kimi-k2.5", "kimi-k2.5-lightning",
  "gemma-4-31b-it", "qwen3.6-27b", "qwen3.5-397b-a17b", "qwen3.5-9b", "qwen3.5-9b-chat",
])

export const CrofAiPlugin: Plugin = async () => {
  return {
    config: async (cfg) => {
      // Create provider if it doesn't exist (self-contained)
      if (!cfg.provider) cfg.provider = {}
      if (!cfg.provider.crofai) {
        cfg.provider.crofai = {
          id: "crofai",
          name: "CrofAI",
          api: "https://crof.ai/v1",
          npm: "@ai-sdk/openai-compatible",
          env: ["CROFAI_API_KEY"],
          models: {},
        }
      }

      const provider = cfg.provider.crofai

      // Always ensure the API base URL is set (needed for multimodal/image routing)
      // When the provider already exists from opencode.jsonc, the guard above
      // skips the defaults, so we set it here explicitly.
      provider.api = "https://crof.ai/v1"

      try {
        const res = await fetch("https://crof.ai/v1/models")
        if (!res.ok) throw new Error(`HTTP ${res.status}`)
        const { data } = (await res.json()) as { data: CrofAiModel[] }

        const models: Record<string, any> = {}
        for (const m of data) {
          const isVision = VISION_MODELS.has(m.id)
          models[m.id] = {
            id: m.id,
            name: m.name.replace(/^[^:]+:\s*/, ""),
            tool_call: true,
            reasoning: !!m.custom_reasoning,
            options: m.custom_reasoning ? { reasoningEffort: "high" } : undefined,
            variants: m.custom_reasoning
              ? {
                  low: { reasoningEffort: "low" },
                  medium: { reasoningEffort: "medium" },
                  high: { reasoningEffort: "high" },
                  max: { reasoningEffort: "high" },
                }
              : undefined,
            attachment: isVision,
            temperature: true,
            modalities: {
              input: isVision ? ["text", "image"] : ["text"],
              output: ["text"],
            },
            limit: {
              context: m.context_length || 0,
              output: m.max_completion_tokens || 0,
            },
            cost: {
              input: parseFloat(m.pricing?.prompt || "0"),
              output: parseFloat(m.pricing?.completion || "0"),
              cache_read: parseFloat(m.pricing?.cache_prompt || "0"),
            },
          }
        }

        provider.models = models
      } catch (err) {
        console.error(`[crofai] Failed to fetch models: ${err}`)
      }
    },
  }
}

export default CrofAiPlugin
