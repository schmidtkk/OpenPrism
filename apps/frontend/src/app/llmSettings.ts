export const SETTINGS_KEY = 'openprism-settings-v1';
export const DEFAULT_LLM_ENDPOINT = 'https://api.openai.com/v1/chat/completions';
export const DEFAULT_LLM_MODEL = 'gpt-4o-mini';

export type StoredLLMSettings = {
  llmEndpoint?: string;
  llmApiKey?: string;
  llmModel?: string;
  llmConfigured?: boolean;
};

export const EMPTY_LLM_SETTINGS = {
  llmEndpoint: '',
  llmApiKey: '',
  llmModel: '',
  llmConfigured: false
} as const;

export function normalizeLLMSettings(input?: StoredLLMSettings | null) {
  const llmEndpoint = typeof input?.llmEndpoint === 'string' ? input.llmEndpoint.trim() : '';
  const llmApiKey = typeof input?.llmApiKey === 'string' ? input.llmApiKey.trim() : '';
  const llmModel = typeof input?.llmModel === 'string' ? input.llmModel.trim() : '';
  const explicitConfig = Boolean(input?.llmConfigured);

  // Older builds auto-saved the OpenAI sample values even when the user never configured AI.
  const looksLikeLegacyDefault =
    !explicitConfig &&
    !llmApiKey &&
    llmEndpoint === DEFAULT_LLM_ENDPOINT &&
    llmModel === DEFAULT_LLM_MODEL;

  if (looksLikeLegacyDefault) {
    return { ...EMPTY_LLM_SETTINGS };
  }

  return {
    llmEndpoint,
    llmApiKey,
    llmModel,
    llmConfigured: explicitConfig || Boolean(llmEndpoint || llmApiKey || llmModel)
  };
}

export function readStoredLLMSettings() {
  if (typeof window === 'undefined') return { ...EMPTY_LLM_SETTINGS };
  try {
    const raw = window.localStorage.getItem(SETTINGS_KEY);
    if (!raw) return { ...EMPTY_LLM_SETTINGS };
    return normalizeLLMSettings(JSON.parse(raw) as StoredLLMSettings);
  } catch {
    return { ...EMPTY_LLM_SETTINGS };
  }
}
