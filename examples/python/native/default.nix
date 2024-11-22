{pkgs, ...}: {
  kernel.python.native-example = {
    enable = true;
    env = pkgs.python312.withPackages (ps:
      with ps; [
        ps.ipykernel
        ps.scipy
        ps.matplotlib
      ]);
  };
}
