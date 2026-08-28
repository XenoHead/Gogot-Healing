# Hermes Settings Export — match this at home

> The "smartness" you noticed is **not just the model**. It's three layers:
> 1. The **model + endpoint** (same weights, same host).
> 2. A **behavioral system prompt** steering rigor (verify before claiming success,
>    use tools, don't fabricate output, finish the job with real execution).
> 3. **Tools** (terminal/file/web) so it can *do* instead of just *claim*.
>
> To reproduce the behavior at home you need all three. The config block below
> covers (1). The system prompt below covers (2). For (3) you need a client that
> gives the model tool access (Hermes desktop app, or a tool-enabled harness).

## 1) Model / provider config (from `config.yaml`)
```yaml
model:
  # NOTE: api_key shown is a placeholder ("ollama") used by the Nous gateway.
  # At home, use YOUR OWN Nous auth / API key — do NOT copy this literally.
  api_key: "<your-nous-api-key-or-oauth>"
  base_url: https://inference-api.nousresearch.com/v1
  default: tencent/hy3:free
  provider: nous
```
Key point: the model is **`tencent/hy3:free` served by Nous** at
`https://inference-api.nousresearch.com/v1`. If your home setup uses a *different*
provider, a local quant (ollama/llama.cpp), or even the same name on another host,
the behavior will differ even though the label matches. **Match the endpoint too.**

## 2) Other relevant `config.yaml` values (verified)
```yaml
agent:
  max_turns: 500
  reasoning_effort: medium
  verbose: false
compression:
  enabled: true
  threshold: 0.5
  target_ratio: 0.2
  protect_first_n: 3
  protect_last_n: 20
memory:
  memory_enabled: true
  memory_char_limit: 2200
  user_profile_enabled: true
  user_char_limit: 1375
toolsets:
  - hermes-cli
  - web
tool_loop_guardrails:
  warnings_enabled: true
  warn_after:
    exact_failure: 2
    same_tool_failure: 3
    idempotent_no_progress: 2
  hard_stop_enabled: false
code_execution:
  max_tool_calls: 50
  timeout: 300
terminal:
  backend: local
  timeout: 180
```
(Streaming is off in this config; `reasoning_effort: medium`. These affect feel.)

## 3) Behavioral system prompt (paste into your client)
The single biggest lever. Without a system prompt, the same model looks aimless.
Use something like:

```
You are a meticulous engineering assistant. Rules:
- NEVER claim a task is done without verifying it with real execution
  (run the command, read the file back, check the output).
- Do NOT fabricate file contents, test results, or API responses. If a tool
  failed, say so honestly.
- Prefer doing over describing: use available tools (file read/write, terminal,
  search) to actually perform the work.
- When editing files, make targeted changes and verify they applied.
- If you are unsure about a user's environment or setup, ask or inspect first.
- Keep responses concise but complete; surface real status, not optimism.
```

## 4) What you can't fully replicate without the Hermes app
- The rich **tool set** (terminal/file/web/execute_code) and the desktop GUI.
- **Skills** (curated workflows) and **persistent memory** of your preferences.
- Secret redaction and pre-exec scanning (security).
- These are what make the *experience* feel sharper. A plain API chat with only
  the system prompt above will be much closer to what you saw here than a bare
  `hy3` call, but still not 1:1.

## 5) Quick checklist to match at home
- [ ] Use model `tencent/hy3:free` via Nous endpoint `https://inference-api.nousresearch.com/v1` (same host as here)
- [ ] Add the behavioral system prompt above
- [ ] Give the model tool access (terminal + file + web) if possible
- [ ] Set `reasoning_effort` to at least `medium`, `max_turns` high (e.g. 500)
- [ ] If latency/verbosity feels off, compare `streaming`, `verbose`, and temperature (this config does not set an explicit temperature)
```
