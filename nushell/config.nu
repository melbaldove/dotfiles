$env.config = {
  show_banner: false
  hooks: {
    pre_prompt: [{ ||
      try {
        if not ('@direnv@' | path exists) {
          return
        }
        
        @direnv@ export json | from json | default {} | load-env
        if 'ENV_CONVERSIONS' in $env and 'PATH' in $env.ENV_CONVERSIONS {
          $env.PATH = do $env.ENV_CONVERSIONS.PATH.from_string $env.PATH
        }
      } catch {
        # Silently ignore direnv errors
      }
    }]
  }
}

