{ ... }:

{
  imports = [
    ./ai-agents/gemini-sandboxed.nix
    ./ai-agents/opencode-sandboxed.nix
    ./ai-agents/claude-sandboxed.nix
    ./ai-agents/agy-sandboxed.nix
  ];
}
