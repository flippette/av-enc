{inputs, ...}: {
  imports = with inputs; [
    git-hooks.flakeModule
  ];

  perSystem = {pkgs, ...}: {
    pre-commit = with pkgs; {
      check.enable = true;
      settings.package = prek;
      settings.hooks = {
        alejandra.enable = true;
        deadnix.enable = true;
        shellcheck.enable = true;
        shfmt.enable = true;
        statix.enable = true;
      };
    };
  };
}
