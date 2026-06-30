class GROQ_CONFIG {
  // Para producción, usar environment variables o Firebase Remote Config
  static const String API_KEY = 'YOUR_GROQ_API_KEY_HERE';
}

String get GROQ_API_KEY => GROQ_CONFIG.API_KEY;
