{
  self,
  system,
  config,
  lib,
  mkKernel,
  ...
}: let
  inherit (lib) types;

  kernelName = "julia";
  kernelOptions = {
    config,
    name,
    ...
  }: let
    args = {inherit self system lib config name kernelName;};
    kernelModule = import ./../../kernel.nix args;
    kernelFunc = {
      self,
      system,
      # custom arguments
      pkgs,
      name ? "julia",
      displayName ? "Julia",
      requiredRuntimePackages ? [],
      runtimePackages ? [],
      julia,
      ijuliaRev ? "bHdNn",
      extraJuliaPackages ? [],
      override ? {},
      extraKernelSpc,
    }: let
      inherit (pkgs) writeText;
      inherit (pkgs.lib) optionalString;

      allRuntimePackages = requiredRuntimePackages ++ runtimePackages;

      env = (julia.withPackages.override override) ([
          "IJulia"
        ]
        ++ extraJuliaPackages);

      wrappedEnv =
        pkgs.runCommand "wrapper-${env.name}"
        {nativeBuildInputs = [pkgs.makeWrapper];}
        ''
          mkdir -p $out/bin
          for i in ${env}/bin/*; do
            filename=$(basename $i)
            ln -s ${env}/bin/$filename $out/bin/$filename
            wrapProgram $out/bin/$filename \
              --set PATH "${pkgs.lib.makeSearchPath "bin" allRuntimePackages}"
          done
        '';
    in
      {
        inherit name displayName;
        language = "julia";
        argv = [
          "${wrappedEnv}/bin/julia"
          "-i"
          "--startup-file=yes"
          "--color=yes"
          "${env.projectAndDepot}/depot/packages/IJulia/${ijuliaRev}/src/kernel.jl"
          "{connection_file}"
        ];
        codemirrorMode = "julia";
        logo64 = ./logo-64x64.png;
      }
      // extraKernelSpc;
  in {
    options =
      {
        ijuliaRev = lib.mkOption {
          type = types.str;
          default = "bHdNn";
          description = ''
            IJulia revision
          '';
        };
        julia = lib.mkOption {
          type = types.package;
          default = config.nixpkgs.julia;
          description = ''
            Julia Version
          '';
        };
        extraJuliaPackages = lib.mkOption {
          type = types.listOf types.str;
          default = [];
          description = ''
            Extra Julia packages to install
          '';
        };
        override = lib.mkOption {
          type = types.attrs;
          default = {};
          description = ''
            Override JuliaWithPackages
          '';
        };
      }
      // kernelModule.options;

    config = lib.mkIf config.enable {
      build = mkKernel (kernelFunc config.kernelArgs);
      kernelArgs =
        {
          inherit (config) override extraJuliaPackages ijuliaRev julia;
        }
        // kernelModule.kernelArgs;
    };
  };
in {
  options.kernel.${kernelName} = lib.mkOption {
    type = types.attrsOf (types.submodule kernelOptions);
    default = {};
    example = lib.literalExpression ''
      {
        kernel.${kernelName}."example".enable = true;
      }
    '';
    description = ''
      A ${kernelName} kernel for IPython.
    '';
  };
}
