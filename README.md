# Hydra provisioner

`hydra-provisioner` is a script that automatically creates and destroys build machines (typically EC2 instances) for a Hydra server based on the state of the Hydra queue runner. For instance, if there are many runnable build steps for a particular system type (e.g. `x86_64-linux`), it will create additional build machines, then destroy them when they are no longer needed. The machines are managed using NixOps.

To run this script:
```
$ hydra-provisioner conf.nix
```
This command should be run periodically (e.g. every 5 minutes). `conf.nix` is a Nix expression containing a specification of when and how to create machines. For example:
```
{

  # Tag used for NixOps deployments created by the provisioner. Useful
  # if you're running multiple provisioners.
  #tag = "hydra-provisioned";

  # The spec must contain one or more sets named systemTypes.<type>,
  # where <type> is a Nix system type such as "x86_64-linux". You 
  # can also list system features (e.g. "x86_64-linux:benchmark"), in 
  # which case only build steps that have "requiredSystemFeatures" set to
  # the listed features will be executed on the machines created here.
  systemTypes.x86_64-linux = {

    # Path to NixOps module defining the deployment for this type.
    nixopsExpr = builtins.toPath ./deployment.nix;

    # The minimum number of machines to keep around for this type.
    #minMachines = 0;

    # The maximum number of machines to provision for this type.
    #maxMachines = 1;

    # Value subtracted from the number of runnables of this type. This
    # is the number of runnables to be performed by non-provisioned
    # machines, before the provisioner kicks in to create more
    # machines.
    #ignoredRunnables = 0;

    # How many machines should be created given the number of
    # runnables. For instance, if there are 10 runnables and
    # runnablesPerMachine is 5, then 2 machines will be created.
    #runnablesPerMachine = 10;

    # How many jobs can be run concurrently on machines of this type.
    #maxJobs = 1;

    # The speed factor.
    #speedFactor = 1;

    # The path of the SSH private key.
    #sshKey = "/var/lib/hydra/queue-runner/.ssh/id_buildfarm";

    # Whether to stop or destroy the machine when it's idle.
    #stopOnIdle = false;

    # Grace period in seconds before an idle machine is stopped or
    # destroyed. Thus, if Hydra load increases in the meantime, the
    # machine can be put back in action. Note that regardless of this 
    # setting, EC2 instances are not stopped or destroyed until their 
    # current hour of execution time has nearly expired.
    #gracePeriod = 0;

  };
  
  # Command for getting the Hydra queue status. Useful if the provisioner 
  # runs on a different machine from the queue runner.
  #sshCommand = ["hydra-queue-runner", "--status"]
  
  # Command for writing the queue runner's machines file. The contents are 
  # passed via stdin.
  #updateCommand = [ "/bin/sh" "-c" "cat > /var/lib/hydra/provisioned.machines" ];
}
```
The NixOps specification (e.g. `deployment.nix`) must declare one machine named `machine`. The provisioner will create a separate NixOps deployment for each machine that it creates. A typical NixOps specification looks like this:
```
# The "type" argument corresponds to the system type (such as 
# "x86_64-linux:benchmark"), and can be used for creating different
# kinds of machines from the same NixOps specification.
{ type, tag, ... }:

{

  machine =
    { config, lib, pkgs, ... }:
    {
      deployment.targetEnv = "virtualbox";
      
      # The queue runner will perform build actions via "nix-store --serve" 
      # on root@<machine>, so this machine needs an authorized key for that.
      users.extraUsers.root.openssh.authorizedKeys.keys = lib.singleton ''
        command="nix-store --serve --write" ssh-dss AAAAB3NzaC1...
      '';
      
      # Currently, Hydra works better with the Nix 1.10 prerelease.
      nix.package = pkgs.nixUnstable;
      
      # Frequent garbage collection is a good idea for build machines.
      nix.gc.automatic = true;
      nix.gc.dates = "*:0/30";
    };

}
```

A real-world configuration (for `hydra.nixos.org`) can be found at https://github.com/NixOS/nixos-org-configurations/tree/master/hydra-provisioner.
