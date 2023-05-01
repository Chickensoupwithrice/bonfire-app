{
  description = "Bonfire self contained build";

  inputs = {
    nixpkgs = { url = "github:NixOS/nixpkgs/nixpkgs-unstable"; };
    flake-utils = { url = "github:numtide/flake-utils"; };
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      # props to hold settings to apply on this file like name and version
      props = import ./props.nix;
      # set elixir nix version
      elixir_nix_version = elixir_version:
        builtins.replaceStrings [ "." ] [ "_" ] "elixir_${elixir_version}";
      erlang_nix_version = erlang_version: "erlangR${erlang_version}";
    in
    flake-utils.lib.eachSystem flake-utils.lib.defaultSystems (system:
      let
        inherit (nixpkgs.lib) optional;
        pkgs = import nixpkgs { inherit system; };

        # project name for mix release
        pname = "bonfire";
        elixir_release = "1.14";
        # version release of erlang
        erlang_release = "25";
        # project version for mix release
        version = "0.4.0-classic-beta.43";

        # use ~r/erlangR[1-9]+/ for specific erlang release version
        beamPackages = pkgs.beam.packagesWith
          pkgs.beam.interpreters.${erlang_nix_version erlang_release};
        # all elixir and erlange packages
        erlang = beamPackages.erlang;
        # use ~r/elixir_1_[1-9]+/ major elixir version
        elixir = beamPackages.${elixir_nix_version elixir_release};
        elixir-ls = beamPackages.elixir_ls.overrideAttrs
          (oldAttrs: rec { elixir = elixir; });
        hex = beamPackages.hex;

        # use rebar from nix instead of fetch externally
        rebar3 = beamPackages.rebar3;
        rebar = beamPackages.rebar;

        lib = pkgs.lib;

        installHook = { release }: ''
          export APP_VERSION="${version}"
          export APP_NAME="${pname}"
          export ELIXIR_RELEASE="${elixir_release}"
          runHook preInstall
          mix release --no-deps-check --path "$out" 
          runHook postInstall
        '';

        # src of the project
        src = ./.;

        mixNixDeps = with pkgs; import ./nix/bonfire-deps.nix { inherit stdenv lib beamPackage; };

        #mix deps
        mixFodDeps = beamPackages.fetchMixDeps {
          pname = "mix-deps-${pname}";
          LANG = "en_US.UTF-8";
          debug = true;
          inherit src version elixir;
          configurePhase = ''
            runHook preConfigure
            export HEX_HOME="$TEMPDIR/.hex";
            export MIX_HOME="$TEMPDIR/.mix";
            export MIX_DEPS_PATH="./deps"; # mix seems to depend on this being in the current directory
            # Rebar
            export REBAR_GLOBAL_CONFIG_DIR="$TMPDIR/rebar3"
            export REBAR_CACHE_DIR="$TMPDIR/rebar3.cache"

            # `just config` stuff so mix knows to find deps
            mkdir -p ./config
            cd config && ln -sfn ../flavours/classic/config/* ./ && ln -sfn ../flavours/classic/config/* ./
            cd ..
            touch ./config/deps.path

            runHook postConfigure
          '';
          installPhase = ''
            runHook preInstall
            mix deps.get --only prod
            ls ./deps
            cp -r --no-preserve=mode,ownership,timestamps ./deps $out
            runHook postInstall
          '';
          # installPhase = fetchMixInstallPhase { mixEnv = "prod"; };
          # nix will complain and tell you the right value to replace this with if deps change
          sha256 = null;
        };

        yarnDeps = pkgs.mkYarnModules {
          pname = "${pname}-yarn-deps";
          inherit version;
          packageJSON = ./assets/package.json;
          yarnLock = ./assets/yarn.lock;
          yarnNix = ./nix/yarn.nix; # <- TODO Needs to be made
          preBuild = ''
            mkdir -p tmp/deps
            cp -r ${mixFodDeps}/ tmp/deps/
          '';
          # TODO
          # Replace the output directory of assets (normally ../../../assets) with ${out}
          # preConfigure = ''
          #   substituteInPlace tsconfig.json --replace "../../../assets" "${out}/priv/static/assets"
          # '';
          # postBuild = ''
          #   echo 'module.exports = {}' > $out/node_modules/flatpickr/dist/postcss.config.js
          # '';
        };

        configureHook = { flavour, MIX_ENV }: ''
          runHook preConfigure
          ${./nix/mix-configure-hook.sh}
          export WITH_DOCKER=no FLAVOUR=${flavour} MIX_ENV=${MIX_ENV}

          # just config (without the mix deps)
          echo "Using flavour '${flavour}' at flavours/${flavour} with env '${MIX_ENV}' with vars from ./flavours/${flavour}/config/${MIX_ENV}/.env "
          mkdir -p ./data
          mkdir -p ./config
          mkdir -p ./flavours/${flavour}/config/prod/
          mkdir -p ./flavours/${flavour}/config/dev/
          cd config && ln -sfn ../flavours/classic/config/* ./ && ln -sfn ../flavours/${flavour}/config/* ./
          cd ..
          touch ./config/deps.path
          mkdir -p ./extensions/
          mkdir -p ./forks/
          mkdir -p ./data/uploads/
          mkdir -p ./priv/static/data
          mkdir -p ./data/search/dev
          ln -sf ./flavours/${flavour} ./data/current_flavour

          # this is needed for projects that have a specific compile step
          # the dependency needs to be compiled in order for the task
          # to be available
          # Phoenix projects for example will need compile.phoenix
          mix do deps.compile --no-deps-check --skip-umbrella-children 

          ls $MIX_DEPS_PATH

          runHook postConfigure
        '';

        # mix release definition
        release-prod = beamPackages.mixRelease {
          inherit src pname version mixFodDeps elixir hex erlang;
          mixEnv = "prod";
          buildInputs = [ pkgs.just ];

          installPhase = installHook { release = "prod"; };
          configurePhase = configureHook { flavour = "classic"; MIX_ENV = "prod"; };
          postBuild = ''
            # export HOME=$TMPDIR
            # export NODE_OPTIONS=--openssl-legacy-provider # required for webpack compatibility with OpenSSL 3 (https://github.com/webpack/webpack/issues/14532)
            # for external task you need a workaround for the no deps check flag
            # https://github.com/phoenixframework/phoenix/issues/2690
            mix do deps.loadpaths --no-deps-check phx.digest
          '';
        };

        release-dev = beamPackages.mixRelease {
          inherit src pname version mixFodDeps elixir;
          mixEnv = "dev";
          enableDebugInfo = true;
          installPhase = installHook { release = "dev"; };
        };
      in
      rec {
        # packages to build
        packages = {
          prod = release-prod;
          dev = release-dev;
          deps = mixNixDeps;
          default = packages.prod;
        };

        # apps to run with nix run
        apps = {
          prod = flake-utils.lib.mkApp {
            name = pname;
            drv = packages.prod;
            exePath = "/bin/prod";
          };
          dev = flake-utils.lib.mkApp {
            name = "${pname}-dev";
            drv = packages.dev;
            exePath = "/bin/dev";
          };
          default = apps.prod;
        };

        # Module for deployment
        nixosModules.bonfire = import ./nix/module.nix;
        nixosModule = nixosModules.bonfire;

        devShells.default = pkgs.mkShell {

          shellHook = ''
            export APP_VERSION="${version}"
            export APP_NAME="${pname}"
            export ELIXIR_MAJOR_RELEASE="${props.elixir_release}"
            export MIX_HOME="$PWD/.cache/mix";
            export HEX_HOME="$PWD/.cache/hex";
            export MIX_PATH="${hex}/lib/erlang/lib/hex/ebin"
            export PATH="$MIX_PATH/bin:$HEX_HOME/bin:$PATH"
            mix local.rebar --if-missing rebar3 ${rebar3}/bin/rebar3;
            mix local.rebar --if-missing rebar ${rebar}/bin/rebar;

            export PGDATA=$PWD/db
            export PGHOST=$PWD/db
            export PGUSERNAME=${props.PGUSERNAME}
            export PGPASS=${props.PGPASS}
            export PGDATABASE=${props.PGDATABASE}
            export POSTGRES_USER=${props.PGUSERNAME}
            export POSTGRES_PASSWORD=${props.PGPASS}
            export POSTGRES_DB=${props.PGDATABASE}
            if [[ ! -d $PGDATA ]]; then
              mkdir $PGDATA
              # comment out if not using CoW fs
              chattr +C $PGDATA
              initdb -D $PGDATA
            fi
          '';

          buildInputs = [
            elixir
            erlang
            rebar3
            rebar
            pkgs.just
            pkgs.yarn
            pkgs.cargo
            pkgs.rustc
            (pkgs.postgresql_12.withPackages (p: [ p.postgis ]))
          ] ++ optional pkgs.stdenv.isLinux
            pkgs.libnotify # For ExUnit Notifier on Linux.
          ++ optional pkgs.stdenv.isLinux
            pkgs.meilisearch # For meilisearch when running linux only
          ++ optional pkgs.stdenv.isLinux
            pkgs.inotify-tools; # For file_system on Linux.
        };
      });
}
