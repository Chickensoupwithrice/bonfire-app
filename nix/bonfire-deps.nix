{ stdenv, lib, beamPackages, overrides ? (x: y: { }) }:

let
  buildRebar3 = lib.makeOverridable beamPackages.buildRebar3;
  buildMix = lib.makeOverridable beamPackages.buildMix;
  buildErlangMk = lib.makeOverridable beamPackages.buildErlangMk;

  fetchGitMixDep = attrs@{ name, url, rev, ref }: stdenv.mkDerivation {
    inherit name sha256;
    src = builtins.fetchGit attrs;
    nativeBuildInputs = [ beamPackages.elixir ];
    outputs = [ "out" "version" "deps" ];
    # Create a fake .git folder that will be acceptable to Mix's SCM lock check:
    # https://github.com/elixir-lang/elixir/blob/74bfab8ee271e53d24cb0012b5db1e2a931e0470/lib/mix/lib/mix/scm/git.ex#L242
    buildPhase = ''
      mkdir -p .git/objects .git/refs
      echo ${rev} > .git/HEAD
      echo '[remote "origin"]' > .git/config
      echo "    url = ${url}" >> .git/config
    '';
    installPhase = ''
      # The main package
      cp -r . $out
      # Metadata: version
      echo "File.write!(\"$version\", Mix.Project.config()[:version])" | iex -S mix cmd true
      # Metadata: deps as a newline separated string
      echo "File.write!(\"$deps\", Mix.Project.config()[:deps] |> Enum.map(& &1 |> elem(0) |> Atom.to_string()) |> Enum.join(\" \"))" | iex -S mix cmd true
    '';
  };

  self = packages // (overrides self packages);

  packages = with beamPackages; with self; {
    acceptor_pool = buildRebar3 rec {
      name = "acceptor_pool";
      version = "1.0.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0cbcd83fdc8b9ad2eee2067ef8b91a14858a5883cb7cd800e6fcd5803e158788";
      };

      beamDeps = [ ];
    };

    activity_pub = buildMix rec {
      name = "activity_pub";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/activity_pub";
        rev = "69981799b741e8d81dcaf989ab1757afe0d669d4";
        ref = "develop";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    argon2_elixir = buildMix rec {
      name = "argon2_elixir";
      version = "3.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "c08feae0ee0292165d1b945003363c7cd8523d002e0483c627dfca930291dd73";
      };

      beamDeps = [ comeonin elixir_make ];
    };

    arrows = buildMix rec {
      name = "arrows";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/arrows";
        rev = "2482f0b33f966db602fcbad68c756aa643f0f8af";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bamboo = buildMix rec {
      name = "bamboo";
      version = "2.3.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "dd0037e68e108fd04d0e8773921512c940e35d981e097b5793543e3b2f9cd3f6";
      };

      beamDeps = [ hackney jason mime plug ];
    };

    bamboo_campaign_monitor = buildMix rec {
      name = "bamboo_campaign_monitor";
      version = "0.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "5b60a27ab2b8596f274f22d3cb8bd8d8f3865667f1ec181bfa6635aa7646d79a";
      };

      beamDeps = [ bamboo hackney plug ];
    };

    bamboo_mailjet = buildMix rec {
      name = "bamboo_mailjet";
      version = "0.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "cb213439a14dfe0f8a54dbcb7b40790399d5207025378b64d9717271072e8427";
      };

      beamDeps = [ bamboo ];
    };

    bamboo_postmark = buildMix rec {
      name = "bamboo_postmark";
      version = "1.0.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "443b3fb9e00a5d092ccfc91cfe3dbecab2a931114d4dc5e1e70f28f6c640c63d";
      };

      beamDeps = [ bamboo hackney plug ];
    };

    bamboo_sendcloud = buildMix rec {
      name = "bamboo_sendcloud";
      version = "0.2.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "37e35b408394f1be2f3cefb3fd3064527e92bfd8e6e5a546aaad705f105b405a";
      };

      beamDeps = [ bamboo hackney plug poison ];
    };

    bamboo_ses = buildMix rec {
      name = "bamboo_ses";
      version = "0.3.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "c3f9f58501106fdfba7d85de909bf3b5b02aae09b98080b94528fb607669658f";
      };

      beamDeps = [ bamboo ex_aws jason mail ];
    };

    bamboo_smtp = buildMix rec {
      name = "bamboo_smtp";
      version = "4.2.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "28cac2ec8adaae02aed663bf68163992891a3b44cfd7ada0bebe3e09bed7207f";
      };

      beamDeps = [ bamboo gen_smtp ];
    };

    bamboo_sparkpost = buildMix rec {
      name = "bamboo_sparkpost";
      version = "2.0.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "a89a1c29e122270e50c53c77e091d885c40bebb689f8904572c38b299649bebf";
      };

      beamDeps = [ bamboo ];
    };

    bandit = buildMix rec {
      name = "bandit";
      version = "0.7.7";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "772f0a32632c2ce41026d85e24b13a469151bb8cea1891e597fb38fde103640a";
      };

      beamDeps = [ hpax plug telemetry thousand_island websock ];
    };

    benchee = buildMix rec {
      name = "benchee";
      version = "1.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "7da57d545003165a012b587077f6ba90b89210fd88074ce3c60ce239eb5e6d93";
      };

      beamDeps = [ deep_merge statistex ];
    };

    benchee_html = buildMix rec {
      name = "benchee_html";
      version = "1.0.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "5280af9aac432ff5ca4216d03e8a93f32209510e925b60e7f27c33796f69e699";
      };

      beamDeps = [ benchee benchee_json ];
    };

    benchee_json = buildMix rec {
      name = "benchee_json";
      version = "1.0.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "da05d813f9123505f870344d68fb7c86a4f0f9074df7d7b7e2bb011a63ec231c";
      };

      beamDeps = [ benchee jason ];
    };

    rinpatch_blurhash = buildMix rec {
      name = "rinpatch_blurhash";
      version = "0.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "19911a5dcbb0acb9710169a72f702bce6cb048822b12de566ccd82b2cc42b907";
      };

      beamDeps = [ mogrify ];
    };

    bonfire = buildMix rec {
      name = "bonfire";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_spark";
        rev = "c23ebed967df0e5f0b0df6962e0ec1715b082cd8";
        ref = "main";
        sha256 = "";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_boundaries = buildMix rec {
      name = "bonfire_boundaries";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_boundaries";
        rev = "7850a185366b560c3aea8f389659bf648e735d59";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_common = buildMix rec {
      name = "bonfire_common";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_common";
        rev = "d6a15e41d279b9faf5581c31e1ffc9aa39a0f202";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_data_access_control = buildMix rec {
      name = "bonfire_data_access_control";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_data_access_control";
        rev = "cfdaff2686cbb83256555f1744a6427182786600";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_data_activity_pub = buildMix rec {
      name = "bonfire_data_activity_pub";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_data_activity_pub";
        rev = "0f1a72f5785354c609e13ec0395fe84d3a57b72e";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_data_assort = buildMix rec {
      name = "bonfire_data_assort";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_data_assort";
        rev = "49094f262d3295f36a649575e6c7b4786834f04c";
        ref = "master";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_data_edges = buildMix rec {
      name = "bonfire_data_edges";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_data_edges";
        rev = "40ca9d2ccefa8a884e95ab4e5674d2eb01ed5f1f";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_data_identity = buildMix rec {
      name = "bonfire_data_identity";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_data_identity";
        rev = "beed7c1af9ce96b7ce66771e956c85956ae72e95";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_data_shared_user = buildMix rec {
      name = "bonfire_data_shared_user";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_data_shared_user";
        rev = "e13c0f406f9e7bdc606e3cfce941bbbb01590947";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_data_social = buildMix rec {
      name = "bonfire_data_social";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_data_social";
        rev = "c2e974ff3e345a88043e1a00d91f4ef37296a1f9";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_ecto = buildMix rec {
      name = "bonfire_ecto";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_ecto";
        rev = "2b4b4118af9e807b50a84247815fb861710de44f";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_editor_ck = buildMix rec {
      name = "bonfire_editor_ck";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_editor_ck";
        rev = "faebe9302e0b46f2ce6506737a76df51e7432afb";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_editor_quill = buildMix rec {
      name = "bonfire_editor_quill";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_editor_quill";
        rev = "a6b9d4e9b1171457c52f8c5ea6a6e51cceac7cf1";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_encrypt = buildMix rec {
      name = "bonfire_encrypt";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_encrypt";
        rev = "5cb383903a09afcd7dfaadcadc14e2b2ee342ace";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_epics = buildMix rec {
      name = "bonfire_epics";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_epics";
        rev = "ebd5cb33affd1e9bb6d8d4076040839e81074d92";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_fail = buildMix rec {
      name = "bonfire_fail";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_fail";
        rev = "ba8908aa793e0c67d6360ae87b3543cef131d2f5";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_federate_activitypub = buildMix rec {
      name = "bonfire_federate_activitypub";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_federate_activitypub";
        rev = "bfeb8433b1cf0e867e9a3f612bc7af70702e36ed";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_files = buildMix rec {
      name = "bonfire_files";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_files";
        rev = "c406ed66a839842413096d05a2e6bfa7ba133cc6";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_invite_links = buildMix rec {
      name = "bonfire_invite_links";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_invite_links";
        rev = "609ba5b5dcf02b5fc134e3f49fe8714158f8e9f1";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_mailer = buildMix rec {
      name = "bonfire_mailer";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_mailer";
        rev = "43c2c96d298c8173413b62a170ff6d93db35b4b8";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_me = buildMix rec {
      name = "bonfire_me";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_me";
        rev = "4d047cd25b05d9e2de80e73a8b2870305683f89b";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_pages = buildMix rec {
      name = "bonfire_pages";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_pages";
        rev = "12e5964bf110e63c262263e878ba556b69d78c44";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_search = buildMix rec {
      name = "bonfire_search";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_search";
        rev = "3081b6cd938d2c9ef4be1a999bff8fc7274abea0";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_social = buildMix rec {
      name = "bonfire_social";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_social";
        rev = "941617a1fa31c52c8030c76c1d9887c16e3dcaa6";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_tag = buildMix rec {
      name = "bonfire_tag";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_tag";
        rev = "8e043fc42fa006931b56be41a80fc554bc8e299c";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_ui_common = buildMix rec {
      name = "bonfire_ui_common";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_ui_common";
        rev = "2ab9f187d61fe69c63757bf07a604c6db9b7467e";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_ui_me = buildMix rec {
      name = "bonfire_ui_me";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_ui_me";
        rev = "607894990cd2e62ba6af47c797444523fa0ca2da";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bonfire_ui_social = buildMix rec {
      name = "bonfire_ui_social";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/bonfire_ui_social";
        rev = "4a66ab4b882f3d271664045dd409c3fce359ae67";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    bunt = buildMix rec {
      name = "bunt";
      version = "0.2.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "a330bfb4245239787b15005e66ae6845c9cd524a288f0d141c148b02603777a5";
      };

      beamDeps = [ ];
    };

    cachex = buildMix rec {
      name = "cachex";
      version = "3.6.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "ebf24e373883bc8e0c8d894a63bbe102ae13d918f790121f5cfe6e485cc8e2e2";
      };

      beamDeps = [ eternal jumper sleeplocks unsafe ];
    };

    castore = buildMix rec {
      name = "castore";
      version = "1.0.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "b4951de93c224d44fac71614beabd88b71932d0b1dea80d2f80fb9044e01bbb3";
      };

      beamDeps = [ ];
    };

    certifi = buildRebar3 rec {
      name = "certifi";
      version = "2.9.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "266da46bdb06d6c6d35fde799bcb28d36d985d424ad7c08b5bb48f5b5cdd4641";
      };

      beamDeps = [ ];
    };

    chameleon = buildMix rec {
      name = "chameleon";
      version = "2.5.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "f3559827d8b4fe53a44e19e56ae94bedd36a355e0d33e18067b8abc37ec428db";
      };

      beamDeps = [ ];
    };

    ts_chatterbox = buildRebar3 rec {
      name = "ts_chatterbox";
      version = "0.13.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "b93d19104d86af0b3f2566c4cba2a57d2e06d103728246ba1ac6c3c0ff010aa7";
      };

      beamDeps = [ hpack ];
    };

    circular_buffer = buildMix rec {
      name = "circular_buffer";
      version = "0.4.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "633ef2e059dde0d7b89bbab13b1da9d04c6685e80e68fbdf41282d4fae746b72";
      };

      beamDeps = [ ];
    };

    cldr_utils = buildMix rec {
      name = "cldr_utils";
      version = "2.22.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "ea14e8a6aa89ffd59a5d49baebe7ebf852cc024ac50dc2b3dabcd3786eeed657";
      };

      beamDeps = [ castore certifi decimal ];
    };

    combine = buildMix rec {
      name = "combine";
      version = "0.10.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1b1dbc1790073076580d0d1d64e42eae2366583e7aecd455d1215b0d16f2451b";
      };

      beamDeps = [ ];
    };

    comeonin = buildMix rec {
      name = "comeonin";
      version = "5.3.3";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "3e38c9c2cb080828116597ca8807bb482618a315bfafd98c90bc22a821cc84df";
      };

      beamDeps = [ ];
    };

    cowboy = buildErlangMk rec {
      name = "cowboy";
      version = "2.9.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "2c729f934b4e1aa149aff882f57c6372c15399a20d54f65c8d67bef583021bde";
      };

      beamDeps = [ cowlib ranch ];
    };

    cowboy_telemetry = buildRebar3 rec {
      name = "cowboy_telemetry";
      version = "0.4.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "7d98bac1ee4565d31b62d59f8823dfd8356a169e7fcbb83831b8a5397404c9de";
      };

      beamDeps = [ cowboy telemetry ];
    };

    cowlib = buildRebar3 rec {
      name = "cowlib";
      version = "2.11.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "2b3e9da0b21c4565751a6d4901c20d1b4cc25cbb7fd50d91d2ab6dd287bc86a9";
      };

      beamDeps = [ ];
    };

    credo = buildMix rec {
      name = "credo";
      version = "1.7.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "6839fcf63d1f0d1c0f450abc8564a57c43d644077ab96f2934563e68b8a769d7";
      };

      beamDeps = [ bunt file_system jason ];
    };

    css_colors = buildMix rec {
      name = "css_colors";
      version = "0.2.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "20375fba1657ad6a5ccfa5c056471bd1e251c93a865663752b88c1b182b8228f";
      };

      beamDeps = [ ecto ];
    };

    ctx = buildRebar3 rec {
      name = "ctx";
      version = "0.6.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "a14ed2d1b67723dbebbe423b28d7615eb0bdcba6ff28f2d1f1b0a7e1d4aa5fc2";
      };

      beamDeps = [ ];
    };

    db_connection = buildMix rec {
      name = "db_connection";
      version = "2.5.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "c92d5ba26cd69ead1ff7582dbb860adeedfff39774105a4f1c92cbb654b55aa2";
      };

      beamDeps = [ telemetry ];
    };

    decimal = buildMix rec {
      name = "decimal";
      version = "2.0.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "34666e9c55dea81013e77d9d87370fe6cb6291d1ef32f46a1600230b1d44f577";
      };

      beamDeps = [ ];
    };

    decorator = buildMix rec {
      name = "decorator";
      version = "1.4.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0a07cedd9083da875c7418dea95b78361197cf2bf3211d743f6f7ce39656597f";
      };

      beamDeps = [ ];
    };

    deep_merge = buildMix rec {
      name = "deep_merge";
      version = "1.0.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "ce708e5f094b9cd4e8f2be4f00d2f4250c4095be93f8cd6d018c753894885430";
      };

      beamDeps = [ ];
    };

    dog_sketch = buildMix rec {
      name = "dog_sketch";
      version = "0.1.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "d6c6102a7434a8f49e4368eb3ba01c8eaf1ea455463fb4f74735844a51d9a0d8";
      };

      beamDeps = [ ];
    };

    earmark = buildMix rec {
      name = "earmark";
      version = "1.4.37";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "d86d5e12868db86d5321b00e62a4bbcb4150346e4acc9a90a041fb188a5cb106";
      };

      beamDeps = [ earmark_parser ];
    };

    earmark_parser = buildMix rec {
      name = "earmark_parser";
      version = "1.4.31";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "317d367ee0335ef037a87e46c91a2269fef6306413f731e8ec11fc45a7efd059";
      };

      beamDeps = [ ];
    };

    ecto = buildMix rec {
      name = "ecto";
      version = "3.10.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "d2ac4255f1601bdf7ac74c0ed971102c6829dc158719b94bd30041bbad77f87a";
      };

      beamDeps = [ decimal jason telemetry ];
    };

    ecto_dev_logger = buildMix rec {
      name = "ecto_dev_logger";
      version = "0.9.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "2e8bc98b4ae4fcc7108896eef7da5a109afad829f4fb2eb46d677fdc9101c2d5";
      };

      beamDeps = [ ecto jason ];
    };

    ecto_erd = buildMix rec {
      name = "ecto_erd";
      version = "0.5.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "b9364408964cbace48dfb26499420a8bc91ba0915c1c90239c5fe99bdca9cb6c";
      };

      beamDeps = [ ecto html_entities ];
    };

    ecto_materialized_path = buildMix rec {
      name = "ecto_materialized_path";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/ecto_materialized_path";
        rev = "f7de0e44e4e8b46fa5e8b8c23234e51e8b54159e";
        ref = "HEAD";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    ecto_psql_extras = buildMix rec {
      name = "ecto_psql_extras";
      version = "0.7.11";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "def61f1f92d4f40d51c80bbae2157212d6c0a459eb604be446e47369cbd40b23";
      };

      beamDeps = [ ecto_sql postgrex table_rex ];
    };

    ecto_ranked = buildMix rec {
      name = "ecto_ranked";
      version = "0.5.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "7f9e119539aca2cf6d98916409e592c884f89069014b7731db1f42483da7e192";
      };

      beamDeps = [ ecto_sql ];
    };

    ecto_shorts = buildMix rec {
      name = "ecto_shorts";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/ecto_shorts";
        rev = "0328fa4f8149a6dc526600726beb40072c6ead5e";
        ref = "refactor/attempt1";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    ecto_sparkles = buildMix rec {
      name = "ecto_sparkles";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/ecto_sparkles";
        rev = "ec98f30e8d6d9a0804bab8d4d625a3b3b9e82f9a";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    ecto_sql = buildMix rec {
      name = "ecto_sql";
      version = "3.10.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "f6a25bdbbd695f12c8171eaff0851fa4c8e72eec1e98c7364402dda9ce11c56b";
      };

      beamDeps = [ db_connection ecto postgrex telemetry ];
    };

    elixir_make = buildMix rec {
      name = "elixir_make";
      version = "0.7.6";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "5a0569756b0f7873a77687800c164cca6dfc03a09418e6fcf853d78991f49940";
      };

      beamDeps = [ castore ];
    };

    email_checker = buildMix rec {
      name = "email_checker";
      version = "0.2.4";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "e4ac0e5eb035dce9c8df08ebffdb525a5d82e61dde37390ac2469222f723e50a";
      };

      beamDeps = [ ];
    };

    emote = buildMix rec {
      name = "emote";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/emote";
        rev = "2b7368ad6ecfdb420caa843c06750eb3cb0d61f3";
        ref = "master";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    eqrcode = buildMix rec {
      name = "eqrcode";
      version = "0.1.10";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "da30e373c36a0fd37ab6f58664b16029919896d6c45a68a95cc4d713e81076f1";
      };

      beamDeps = [ ];
    };

    eternal = buildMix rec {
      name = "eternal";
      version = "1.2.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "2c9fe32b9c3726703ba5e1d43a1d255a4f3f2d8f8f9bc19f094c7cb1a7a9e782";
      };

      beamDeps = [ ];
    };

    ex2ms = buildMix rec {
      name = "ex2ms";
      version = "1.6.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "a7192899d84af03823a8ec2f306fa858cbcce2c2e7fd0f1c49e05168fb9c740e";
      };

      beamDeps = [ ];
    };

    ex_aws = buildMix rec {
      name = "ex_aws";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/ex_aws";
        rev = "a3b23ffad937e5153ce6aafaa1cfeff9748b2c81";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    ex_aws_s3 = buildMix rec {
      name = "ex_aws_s3";
      version = "2.4.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "85dda6e27754d94582869d39cba3241d9ea60b6aa4167f9c88e309dc687e56bb";
      };

      beamDeps = [ ex_aws sweet_xml ];
    };

    ex_cldr = buildMix rec {
      name = "ex_cldr";
      version = "2.36.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "5a56c66cd61ebde42277baa828cd1587959b781ac7e2aee135328a78a4de3fe9";
      };

      beamDeps = [ cldr_utils decimal gettext jason nimble_parsec ];
    };

    ex_cldr_languages = buildMix rec {
      name = "ex_cldr_languages";
      version = "0.3.3";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "22fb1fef72b7b4b4872d243b34e7b83734247a78ad87377986bf719089cc447a";
      };

      beamDeps = [ ex_cldr jason ];
    };

    ex_cldr_plugs = buildMix rec {
      name = "ex_cldr_plugs";
      version = "1.2.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "c99fa57e265e1746262d09f2f6612164c9706b612a546854f75122c7c14c72c9";
      };

      beamDeps = [ ex_cldr gettext jason plug ];
    };

    ex_doc = buildMix rec {
      name = "ex_doc";
      version = "0.29.4";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "2c6699a737ae46cb61e4ed012af931b57b699643b24dabe2400a8168414bc4f5";
      };

      beamDeps = [ earmark_parser makeup_elixir makeup_erlang ];
    };

    ex_machina = buildMix rec {
      name = "ex_machina";
      version = "2.7.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "419aa7a39bde11894c87a615c4ecaa52d8f107bbdd81d810465186f783245bf8";
      };

      beamDeps = [ ecto ecto_sql ];
    };

    ex_ulid = buildMix rec {
      name = "ex_ulid";
      version = "0.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "a2befd477aebc4639563de7e233e175cacf8a8f42c8f6778c88d60c13bf20860";
      };

      beamDeps = [ ];
    };

    ex_unit_notifier = buildMix rec {
      name = "ex_unit_notifier";
      version = "1.2.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "f38044c9d50de68ad7f0aec4d781a10d9f1c92c62b36bf0227ec0aaa96aee332";
      };

      beamDeps = [ ];
    };

    expo = buildMix rec {
      name = "expo";
      version = "0.4.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "2ff7ba7a798c8c543c12550fa0e2cbc81b95d4974c65855d8d15ba7b37a1ce47";
      };

      beamDeps = [ ];
    };

    exqlite = buildMix rec {
      name = "exqlite";
      version = "0.11.9";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "2b73f700c5afcc7aee72d73e7dd8aa0bbe4d0747e7453c0089bbf647f46cf657";
      };

      beamDeps = [ db_connection elixir_make ];
    };

    faker = buildMix rec {
      name = "faker";
      version = "0.17.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "a7d4ad84a93fd25c5f5303510753789fc2433ff241bf3b4144d3f6f291658a6a";
      };

      beamDeps = [ ];
    };

    fast_ngram = buildMix rec {
      name = "fast_ngram";
      version = "1.2.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "90c949c5b00314d8117a5bf2fbf6a05ef945ce4cad66a47bc26f8d9ec30dc1bd";
      };

      beamDeps = [ ];
    };

    fetch_favicon = buildMix rec {
      name = "fetch_favicon";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/fetch_favicon";
        rev = "a7568365c499c720f041ee5d03d411e9f89e953a";
        ref = "master";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    file_info = buildMix rec {
      name = "file_info";
      version = "0.0.4";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "50e7ad01c2c8b9339010675fe4dc4a113b8d6ca7eddce24d1d74fd0e762781a5";
      };

      beamDeps = [ mimetype_parser ];
    };

    file_system = buildMix rec {
      name = "file_system";
      version = "0.2.10";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "41195edbfb562a593726eda3b3e8b103a309b733ad25f3d642ba49696bf715dc";
      };

      beamDeps = [ ];
    };

    flexto = buildMix rec {
      name = "flexto";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/flexto";
        rev = "44273bc9e530ea9752f534a46836475af12e0355";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    floki = buildMix rec {
      name = "floki";
      version = "0.34.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "26b9d50f0f01796bc6be611ca815c5e0de034d2128e39cc9702eee6b66a4d1c8";
      };

      beamDeps = [ ];
    };

    flow = buildMix rec {
      name = "flow";
      version = "0.15.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "d7ecbd4dd38a188494bc996d5014ef8335f436a0b262140a1f6441ae94714581";
      };

      beamDeps = [ gen_stage ];
    };

    furlex = buildMix rec {
      name = "furlex";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/furlex";
        rev = "934666935cdb28c7bf504e4e20230ca4433f02eb";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    gen_smtp = buildRebar3 rec {
      name = "gen_smtp";
      version = "1.2.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "5ee0375680bca8f20c4d85f58c2894441443a743355430ff33a783fe03296779";
      };

      beamDeps = [ ranch ];
    };

    gen_stage = buildMix rec {
      name = "gen_stage";
      version = "0.14.3";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "8453e2289d94c3199396eb517d65d6715ef26bcae0ee83eb5ff7a84445458d76";
      };

      beamDeps = [ ];
    };

    gestalt = buildMix rec {
      name = "gestalt";
      version = "1.0.3";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "29dbb4b04c30dbeb86f9b94c9404955891aa78806427ef626783d7c3f0ec9ebe";
      };

      beamDeps = [ ];
    };

    gettext = buildMix rec {
      name = "gettext";
      version = "0.22.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "ad105b8dab668ee3f90c0d3d94ba75e9aead27a62495c101d94f2657a190ac5d";
      };

      beamDeps = [ expo ];
    };

    git_cli = buildMix rec {
      name = "git_cli";
      version = "0.3.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "78cb952f4c86a41f4d3511f1d3ecb28edb268e3a7df278de2faa1bd4672eaf9b";
      };

      beamDeps = [ ];
    };

    glob_ex = buildMix rec {
      name = "glob_ex";
      version = "0.1.3";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "95759df4fef86d3df54e72bae653e2de49c951a0da979a2fff0ab544a182e3f9";
      };

      beamDeps = [ ];
    };

    gproc = buildRebar3 rec {
      name = "gproc";
      version = "0.8.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "580adafa56463b75263ef5a5df4c86af321f68694e7786cb057fd805d1e2a7de";
      };

      beamDeps = [ ];
    };

    grpcbox = buildRebar3 rec {
      name = "grpcbox";
      version = "0.16.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "294df743ae20a7e030889f00644001370a4f7ce0121f3bbdaf13cf3169c62913";
      };

      beamDeps = [ acceptor_pool chatterbox ctx gproc ];
    };

    grumble = buildMix rec {
      name = "grumble";
      version = "0.1.3";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "a7a089e5a145e072d0227012002970e85eeb52031f0d01be14c129f649283d0c";
      };

      beamDeps = [ recase ];
    };

    hackney = buildRebar3 rec {
      name = "hackney";
      version = "1.18.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "a4ecdaff44297e9b5894ae499e9a070ea1888c84afdd1fd9b7b2bc384950128e";
      };

      beamDeps = [ certifi idna metrics mimerl parse_trans ssl_verify_fun unicode_util_compat ];
    };

    hpack_erl = buildRebar3 rec {
      name = "hpack_erl";
      version = "0.2.3";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "06f580167c4b8b8a6429040df36cc93bba6d571faeaec1b28816523379cbb23a";
      };

      beamDeps = [ ];
    };

    hpax = buildMix rec {
      name = "hpax";
      version = "0.1.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "2c87843d5a23f5f16748ebe77969880e29809580efdaccd615cd3bed628a8c13";
      };

      beamDeps = [ ];
    };

    html_entities = buildMix rec {
      name = "html_entities";
      version = "0.5.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "c53ba390403485615623b9531e97696f076ed415e8d8058b1dbaa28181f4fdcc";
      };

      beamDeps = [ ];
    };

    html_query = buildMix rec {
      name = "html_query";
      version = "0.7.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "3c9655d6788af2ec9beff7a7e34ea83f045a0d4c5d983fd3899f27684e3ea354";
      };

      beamDeps = [ floki jason moar ];
    };

    html_sanitize_ex = buildMix rec {
      name = "html_sanitize_ex";
      version = "1.4.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "aef6c28585d06a9109ad591507e508854c5559561f950bbaea773900dd369b0e";
      };

      beamDeps = [ mochiweb ];
    };

    http_signatures = buildMix rec {
      name = "http_signatures";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/http_signatures";
        rev = "44887c7f7f87c73b2cd7b10d4109cd9d9368f7e8";
        ref = "master";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    httpoison = buildMix rec {
      name = "httpoison";
      version = "2.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "fc455cb4306b43827def4f57299b2d5ac8ac331cb23f517e734a4b78210a160c";
      };

      beamDeps = [ hackney ];
    };

    iconify_ex = buildMix rec {
      name = "iconify_ex";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/iconify_ex";
        rev = "20dc8732f646138263704a6be5779696cb3b82dd";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    idna = buildRebar3 rec {
      name = "idna";
      version = "6.1.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "92376eb7894412ed19ac475e4a86f7b413c1b9fbb5bd16dccd57934157944cea";
      };

      beamDeps = [ unicode_util_compat ];
    };

    inflex = buildMix rec {
      name = "inflex";
      version = "2.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "14c17d05db4ee9b6d319b0bff1bdf22aa389a25398d1952c7a0b5f3d93162dd8";
      };

      beamDeps = [ ];
    };

    jason = buildMix rec {
      name = "jason";
      version = "1.4.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "79a3791085b2a0f743ca04cec0f7be26443738779d09302e01318f97bdb82121";
      };

      beamDeps = [ decimal ];
    };

    jumper = buildMix rec {
      name = "jumper";
      version = "1.0.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "318c59078ac220e966d27af3646026db9b5a5e6703cb2aa3e26bcfaba65b7433";
      };

      beamDeps = [ ];
    };

    linkify = buildMix rec {
      name = "linkify";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/linkify";
        rev = "35d86ff2187a17b6d01bb60fe6bb4da7018dfbe1";
        ref = "master";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    live_select = buildMix rec {
      name = "live_select";
      version = "1.0.3";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "93370ad594d3575e010aabc2c5a557e69f3ca552916acf1ae4a5915c35be0055";
      };

      beamDeps = [ phoenix phoenix_html phoenix_live_view ];
    };

    mail = buildMix rec {
      name = "mail";
      version = "0.2.3";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "932b398fa9c69fdf290d7ff63175826e0f1e24414d5b0763bb00a2acfc6c6bf5";
      };

      beamDeps = [ ];
    };

    makeup = buildMix rec {
      name = "makeup";
      version = "1.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0a45ed501f4a8897f580eabf99a2e5234ea3e75a4373c8a52824f6e873be57a6";
      };

      beamDeps = [ nimble_parsec ];
    };

    makeup_diff = buildMix rec {
      name = "makeup_diff";
      version = "0.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "186bad5bb433a8afeb16b01423950e440072284a4103034ca899180343b9b4ac";
      };

      beamDeps = [ makeup ];
    };

    makeup_eex = buildMix rec {
      name = "makeup_eex";
      version = "0.1.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "d111a0994eaaab09ef1a4b3b313ef806513bb4652152c26c0d7ca2be8402a964";
      };

      beamDeps = [ makeup makeup_elixir makeup_html nimble_parsec ];
    };

    makeup_elixir = buildMix rec {
      name = "makeup_elixir";
      version = "0.16.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "e127a341ad1b209bd80f7bd1620a15693a9908ed780c3b763bccf7d200c767c6";
      };

      beamDeps = [ makeup nimble_parsec ];
    };

    makeup_erlang = buildMix rec {
      name = "makeup_erlang";
      version = "0.1.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "174d0809e98a4ef0b3309256cbf97101c6ec01c4ab0b23e926a9e17df2077cbb";
      };

      beamDeps = [ makeup ];
    };

    makeup_graphql = buildMix rec {
      name = "makeup_graphql";
      version = "0.1.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "3390ab04ba388d52a94bbe64ef62aa4d7923ceaffac43ec948f58f631440e8fb";
      };

      beamDeps = [ makeup nimble_parsec ];
    };

    makeup_html = buildMix rec {
      name = "makeup_html";
      version = "0.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0ca44e7dcb8d933e010740324470dd8ec947243b51304bd34b8165ef3281edc2";
      };

      beamDeps = [ makeup ];
    };

    makeup_js = buildMix rec {
      name = "makeup_js";
      version = "0.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "3f0c1a5eb52c9737b1679c926574e83bb260ccdedf08b58ee96cca7c685dea75";
      };

      beamDeps = [ makeup ];
    };

    makeup_json = buildMix rec {
      name = "makeup_json";
      version = "0.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "7b79e8bf88ca9e2f7757c167feac2385479e1b773f37390b8e1b8ff014d4e7ca";
      };

      beamDeps = [ makeup nimble_parsec ];
    };

    makeup_sql = buildMix rec {
      name = "makeup_sql";
      version = "0.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "556e23ff88ad2fb8c44e393467cfba0c4f980cbe90316deaf48a1362f58cd118";
      };

      beamDeps = [ makeup nimble_parsec ];
    };

    meck = buildRebar3 rec {
      name = "meck";
      version = "0.9.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "81344f561357dc40a8344afa53767c32669153355b626ea9fcbc8da6b3045826";
      };

      beamDeps = [ ];
    };

    metrics = buildRebar3 rec {
      name = "metrics";
      version = "1.0.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "69b09adddc4f74a40716ae54d140f93beb0fb8978d8636eaded0c31b6f099f16";
      };

      beamDeps = [ ];
    };

    mime = buildMix rec {
      name = "mime";
      version = "2.0.3";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "27a30bf0db44d25eecba73755acf4068cbfe26a4372f9eb3e4ea3a45956bff6b";
      };

      beamDeps = [ ];
    };

    mimerl = buildRebar3 rec {
      name = "mimerl";
      version = "1.2.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "f278585650aa581986264638ebf698f8bb19df297f66ad91b18910dfc6e19323";
      };

      beamDeps = [ ];
    };

    mimetype_parser = buildMix rec {
      name = "mimetype_parser";
      version = "0.1.3";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "7d8f80c567807ce78cd93c938e7f4b0a20b1aaaaab914bf286f68457d9f7a852";
      };

      beamDeps = [ ];
    };

    mix_test_interactive = buildMix rec {
      name = "mix_test_interactive";
      version = "1.2.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "f49f2a70d00aee93418506dde4d95387fe56bdba501ef9d2aa06ea07d4823508";
      };

      beamDeps = [ file_system typed_struct ];
    };

    mix_test_watch = buildMix rec {
      name = "mix_test_watch";
      version = "1.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "52b6b1c476cbb70fd899ca5394506482f12e5f6b0d6acff9df95c7f1e0812ec3";
      };

      beamDeps = [ file_system ];
    };

    moar = buildMix rec {
      name = "moar";
      version = "1.36.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "aacb10446a8007586d7698e168ce398e2102fb659fcf00ea3a5252072fbf86ff";
      };

      beamDeps = [ ];
    };

    mochiweb = buildRebar3 rec {
      name = "mochiweb";
      version = "2.22.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "cbbd1fd315d283c576d1c8a13e0738f6dafb63dc840611249608697502a07655";
      };

      beamDeps = [ ];
    };

    mock = buildMix rec {
      name = "mock";
      version = "0.3.7";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "4da49a4609e41fd99b7836945c26f373623ea968cfb6282742bcb94440cf7e5c";
      };

      beamDeps = [ meck ];
    };

    mogrify = buildMix rec {
      name = "mogrify";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/chaskiq/mogrify.git";
        rev = "48e237d2332d24ddf5996f78b13d8bc97221b094";
        ref = "identify-option";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    neotoma = buildRebar3 rec {
      name = "neotoma";
      version = "1.7.3";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "2da322b9b1567ffa0706a7f30f6bbbde70835ae44a1050615f4b4a3d436e0f28";
      };

      beamDeps = [ ];
    };

    neuron = buildMix rec {
      name = "neuron";
      version = "5.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "23cddb0e0dd9c0eea247bc5b4bc3e1f8b52dbaf63f1637623920ec0b2385b6ce";
      };

      beamDeps = [ httpoison jason ];
    };

    nimble_options = buildMix rec {
      name = "nimble_options";
      version = "0.5.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "4da7f904b915fd71db549bcdc25f8d56f378ef7ae07dc1d372cbe72ba950dce0";
      };

      beamDeps = [ ];
    };

    nimble_parsec = buildMix rec {
      name = "nimble_parsec";
      version = "1.3.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "7977f183127a7cbe9346981e2f480dc04c55ffddaef746bd58debd566070eef8";
      };

      beamDeps = [ ];
    };

    nodeinfo = buildMix rec {
      name = "nodeinfo";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/nodeinfo";
        rev = "ff647cc079a4ecdb11a83eeb54915841e754b404";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    oban = buildMix rec {
      name = "oban";
      version = "2.15.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "22e181c540335d1dd5c995be00435927075519207d62b3de32477d95dbf9dfd3";
      };

      beamDeps = [ ecto_sql jason postgrex telemetry ];
    };

    observer_cli = buildMix rec {
      name = "observer_cli";
      version = "1.7.4";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "50de6d95d814f447458bd5d72666a74624eddb0ef98bdcee61a0153aae0865ff";
      };

      beamDeps = [ recon ];
    };

    opentelemetry = buildRebar3 rec {
      name = "opentelemetry";
      version = "1.3.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "8e09edc26aad11161509d7ecad854a3285d88580f93b63b0b1cf0bac332bfcc0";
      };

      beamDeps = [ opentelemetry_api opentelemetry_semantic_conventions ];
    };

    opentelemetry_api = buildMix rec {
      name = "opentelemetry_api";
      version = "1.2.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "6d7a27b7cad2ad69a09cabf6670514cafcec717c8441beb5c96322bac3d05350";
      };

      beamDeps = [ opentelemetry_semantic_conventions ];
    };

    opentelemetry_cowboy = buildRebar3 rec {
      name = "opentelemetry_cowboy";
      version = "0.2.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "21ba198dd51294211a498dee720a30d2c2cb4d35ddc843d84f2d4e0a9681be49";
      };

      beamDeps = [ cowboy_telemetry opentelemetry_api opentelemetry_telemetry telemetry ];
    };

    opentelemetry_ecto = buildMix rec {
      name = "opentelemetry_ecto";
      version = "1.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "9c65ae4b19ea0770dc70cd2c6065b9e88bd888bd26bf987955ec76e946c3e082";
      };

      beamDeps = [ opentelemetry_api opentelemetry_process_propagator telemetry ];
    };

    opentelemetry_exporter = buildRebar3 rec {
      name = "opentelemetry_exporter";
      version = "1.4.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "d23ba198d6d22eff32d88b045165aa990ea89b9934ee8b337feb834c2c4d315b";
      };

      beamDeps = [ grpcbox opentelemetry opentelemetry_api tls_certificate_check ];
    };

    opentelemetry_liveview = buildMix rec {
      name = "opentelemetry_liveview";
      version = "1.0.0-rc.4";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "e06ab69da7ee46158342cac42f1c22886bdeab53e8d8c4e237c3b3c2cf7b815d";
      };

      beamDeps = [ opentelemetry_api opentelemetry_telemetry telemetry ];
    };

    opentelemetry_oban = buildMix rec {
      name = "opentelemetry_oban";
      version = "1.0.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "59ac755f441c8a95d0204f73ef8c168e96a8eaca3abb7bf8adb9b9960a27003f";
      };

      beamDeps = [ oban opentelemetry_api opentelemetry_telemetry telemetry ];
    };

    opentelemetry_phoenix = buildMix rec {
      name = "opentelemetry_phoenix";
      version = "1.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "5a38537aedc5d568590e8be9ffe481d668cba4ffd25f06fe2d33c11296d7855f";
      };

      beamDeps = [ nimble_options opentelemetry_api opentelemetry_process_propagator opentelemetry_semantic_conventions opentelemetry_telemetry plug telemetry ];
    };

    opentelemetry_process_propagator = buildMix rec {
      name = "opentelemetry_process_propagator";
      version = "0.2.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "04db13302a34bea8350a13ed9d49c22dfd32c4bc590d8aa88b6b4b7e4f346c61";
      };

      beamDeps = [ opentelemetry_api ];
    };

    opentelemetry_semantic_conventions = buildMix rec {
      name = "opentelemetry_semantic_conventions";
      version = "0.2.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "d61fa1f5639ee8668d74b527e6806e0503efc55a42db7b5f39939d84c07d6895";
      };

      beamDeps = [ ];
    };

    opentelemetry_telemetry = buildMix rec {
      name = "opentelemetry_telemetry";
      version = "1.0.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "3401d13a1d4b7aa941a77e6b3ec074f0ae77f83b5b2206766ce630123a9291a9";
      };

      beamDeps = [ opentelemetry_api telemetry telemetry_registry ];
    };

    orion = buildMix rec {
      name = "orion";
      version = "1.0.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "118dee33b850f9990da5dd5c41ba877d1920c3480a05188a6cd0d3b49e5c978e";
      };

      beamDeps = [ dog_sketch orion_collector phoenix_live_view ];
    };

    orion_collector = buildMix rec {
      name = "orion_collector";
      version = "1.0.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0bc55e6b934b0cb467b57e46ef2301e728fe09837d3bcb13713b9e92be2c0b36";
      };

      beamDeps = [ dog_sketch ex2ms ];
    };

    pages = buildMix rec {
      name = "pages";
      version = "0.12.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "02c69c18220bc7fefb8cb5fd7d43677b8b44299e9eddd09e82f21e6b2017bd01";
      };

      beamDeps = [ gestalt html_query jason moar phoenix phoenix_live_view ];
    };

    paginator = buildMix rec {
      name = "paginator";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/paginator";
        rev = "e442821dfa2d89ddf20af5c485f9c1f649255cdc";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    pane = buildMix rec {
      name = "pane";
      version = "0.4.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "27a292ca86f52d4777422930c17fd4a12eaa930d86a6193665c452f94a04ff8a";
      };

      beamDeps = [ ];
    };

    parse_trans = buildRebar3 rec {
      name = "parse_trans";
      version = "3.3.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "07cd9577885f56362d414e8c4c4e6bdf10d43a8767abb92d24cbe8b24c54888b";
      };

      beamDeps = [ ];
    };

    pbkdf2_elixir = buildMix rec {
      name = "pbkdf2_elixir";
      version = "2.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "bf8aa304bd2b47ed74de6e5eb4c6b7dc766b936a0a86d643ada89657c715f525";
      };

      beamDeps = [ comeonin ];
    };

    periscope = buildMix rec {
      name = "periscope";
      version = "0.5.6";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "4ebef141e4bdffa5c30e76cd2a301c837dada02f6605aa2bfe3bc1425ea689c4";
      };

      beamDeps = [ ];
    };

    phoenix = buildMix rec {
      name = "phoenix";
      version = "1.7.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1ebca94b32b4d0e097ab2444a9742ed8ff3361acad17365e4e6b2e79b4792159";
      };

      beamDeps = [ castore jason phoenix_pubsub phoenix_template phoenix_view plug plug_cowboy plug_crypto telemetry websock_adapter ];
    };

    phoenix_ecto = buildMix rec {
      name = "phoenix_ecto";
      version = "4.4.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "09864e558ed31ee00bd48fcc1d4fc58ae9678c9e81649075431e69dbabb43cc1";
      };

      beamDeps = [ ecto phoenix_html plug ];
    };

    phoenix_gon = buildMix rec {
      name = "phoenix_gon";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/phoenix_gon";
        rev = "bbdc8dc4112124bb43be9a77a57a02c27c3ccec4";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    phoenix_html = buildMix rec {
      name = "phoenix_html";
      version = "3.3.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "bed1906edd4906a15fd7b412b85b05e521e1f67c9a85418c55999277e553d0d3";
      };

      beamDeps = [ plug ];
    };

    phoenix_live_dashboard = buildMix rec {
      name = "phoenix_live_dashboard";
      version = "0.7.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0e5fdf063c7a3b620c566a30fcf68b7ee02e5e46fe48ee46a6ec3ba382dc05b7";
      };

      beamDeps = [ ecto ecto_psql_extras mime phoenix_live_view telemetry_metrics ];
    };

    phoenix_live_reload = buildMix rec {
      name = "phoenix_live_reload";
      version = "1.4.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "9bffb834e7ddf08467fe54ae58b5785507aaba6255568ae22b4d46e2bb3615ab";
      };

      beamDeps = [ file_system phoenix ];
    };

    phoenix_live_view = buildMix rec {
      name = "phoenix_live_view";
      version = "0.18.18";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "a5810d0472f3189ede6d2a95bda7f31c6113156b91784a3426cb0ab6a6d85214";
      };

      beamDeps = [ jason phoenix phoenix_html phoenix_template phoenix_view telemetry ];
    };

    phoenix_pubsub = buildMix rec {
      name = "phoenix_pubsub";
      version = "2.1.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "81367c6d1eea5878ad726be80808eb5a787a23dee699f96e72b1109c57cdd8d9";
      };

      beamDeps = [ ];
    };

    phoenix_template = buildMix rec {
      name = "phoenix_template";
      version = "1.0.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "157dc078f6226334c91cb32c1865bf3911686f8bcd6bcff86736f6253e6993ee";
      };

      beamDeps = [ phoenix_html ];
    };

    phoenix_view = buildMix rec {
      name = "phoenix_view";
      version = "2.0.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "a929e7230ea5c7ee0e149ffcf44ce7cf7f4b6d2bfe1752dd7c084cdff152d36f";
      };

      beamDeps = [ phoenix_html phoenix_template ];
    };

    plug = buildMix rec {
      name = "plug";
      version = "1.14.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "842fc50187e13cf4ac3b253d47d9474ed6c296a8732752835ce4a86acdf68d13";
      };

      beamDeps = [ mime plug_crypto telemetry ];
    };

    plug_cowboy = buildMix rec {
      name = "plug_cowboy";
      version = "2.6.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "de36e1a21f451a18b790f37765db198075c25875c64834bcc82d90b309eb6613";
      };

      beamDeps = [ cowboy cowboy_telemetry plug ];
    };

    plug_crypto = buildMix rec {
      name = "plug_crypto";
      version = "1.2.5";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "26549a1d6345e2172eb1c233866756ae44a9609bd33ee6f99147ab3fd87fd842";
      };

      beamDeps = [ ];
    };

    plug_http_validator = buildMix rec {
      name = "plug_http_validator";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/plug_http_validator";
        rev = "dbc277f8a328bc44107174fb1770b1376337697a";
        ref = "pr-naive-datetime";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    pointers = buildMix rec {
      name = "pointers";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/pointers";
        rev = "8d589f1f2716a0a5e33ee9a41c3d25896365f68b";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    pointers_ulid = buildMix rec {
      name = "pointers_ulid";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/pointers_ulid";
        rev = "1b4eae0fbbc4c308d798294f4f6f3b81e22d8cbc";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    poison = buildMix rec {
      name = "poison";
      version = "5.0.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "11dc6117c501b80c62a7594f941d043982a1bd05a1184280c0d9166eb4d8d3fc";
      };

      beamDeps = [ decimal ];
    };

    postgrex = buildMix rec {
      name = "postgrex";
      version = "0.17.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "14b057b488e73be2beee508fb1955d8db90d6485c6466428fe9ccf1d6692a555";
      };

      beamDeps = [ db_connection decimal jason ];
    };

    pseudo_gettext = buildMix rec {
      name = "pseudo_gettext";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/tmbb/pseudo_gettext";
        rev = "295afac289d1bf3d4e0fe5cbe8490a5a7f2eebb1";
        ref = "HEAD";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    puid = buildMix rec {
      name = "puid";
      version = "2.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0e95c81ae845411ea4fe551693b75389eb24a3fbd741537b1f91edbd55c53da0";
      };

      beamDeps = [ ];
    };

    ranch = buildRebar3 rec {
      name = "ranch";
      version = "1.8.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "49fbcfd3682fab1f5d109351b61257676da1a2fdbe295904176d5e521a2ddfe5";
      };

      beamDeps = [ ];
    };

    recase = buildMix rec {
      name = "recase";
      version = "0.7.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "36f5756a9f552f4a94b54a695870e32f4e72d5fad9c25e61bc4a3151c08a4e0c";
      };

      beamDeps = [ ];
    };

    recode = buildMix rec {
      name = "recode";
      version = "0.4.4";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "30cec2addb1a406a6cee83b83af5d028ac41171f094e96e84f384aba88f11b7c";
      };

      beamDeps = [ bunt glob_ex rewrite ];
    };

    recon = buildMix rec {
      name = "recon";
      version = "2.5.3";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "6c6683f46fd4a1dfd98404b9f78dcabc7fcd8826613a89dcb984727a8c3099d7";
      };

      beamDeps = [ ];
    };

    rewrite = buildMix rec {
      name = "rewrite";
      version = "0.6.3";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "e0b0e3b6bbeddce9e16e04fb9b024fd82cd75369bd94bc27351458303e831bc2";
      };

      beamDeps = [ glob_ex sourceror ];
    };

    scribe = buildMix rec {
      name = "scribe";
      version = "0.10.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "3829da9c6a28b2105f0ec50e40f447bf768fb7d96717fbfceb602573f1a3c62e";
      };

      beamDeps = [ pane ];
    };

    sentry = buildMix rec {
      name = "sentry";
      version = "8.0.6";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "051a2d0472162f3137787c7c9d6e6e4ef239de9329c8c45b1f1bf1e9379e1883";
      };

      beamDeps = [ hackney jason plug plug_cowboy ];
    };

    seo = buildMix rec {
      name = "seo";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/seo";
        rev = "497543df4310d2236cf505c30829ffb48de0c65d";
        ref = "HEAD";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    simple_slug = buildMix rec {
      name = "simple_slug";
      version = "0.1.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "477c19c7bc8755a1378bdd4ec591e4819071c72353b7e470b90329e63ef67a72";
      };

      beamDeps = [ ];
    };

    sleeplocks = buildRebar3 rec {
      name = "sleeplocks";
      version = "1.1.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "9fe5d048c5b781d6305c1a3a0f40bb3dfc06f49bf40571f3d2d0c57eaa7f59a5";
      };

      beamDeps = [ ];
    };

    slime = buildMix rec {
      name = "slime";
      version = "1.3.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "303b58f05d740a5fe45165bcadfe01da174f1d294069d09ebd7374cd36990a27";
      };

      beamDeps = [ neotoma ];
    };

    sobelow = buildMix rec {
      name = "sobelow";
      version = "0.12.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "2f0b617dce551db651145662b84c8da4f158e7abe049a76daaaae2282df01c5d";
      };

      beamDeps = [ jason ];
    };

    solid = buildMix rec {
      name = "solid";
      version = "0.14.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "5fda2b9176d7a71f52cca7f694d8ca75aed3f1b5b76dd175ada30b2756f96bae";
      };

      beamDeps = [ nimble_parsec ];
    };

    sourceror = buildMix rec {
      name = "sourceror";
      version = "0.12.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "7ad74ade6fb079c71f29fae10c34bcf2323542d8c51ee1bcd77a546cfa89d59c";
      };

      beamDeps = [ ];
    };

    ssl_verify_fun = buildRebar3 rec {
      name = "ssl_verify_fun";
      version = "1.1.6";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "bdb0d2471f453c88ff3908e7686f86f9be327d065cc1ec16fa4540197ea04680";
      };

      beamDeps = [ ];
    };

    statistex = buildMix rec {
      name = "statistex";
      version = "1.0.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "ff9d8bee7035028ab4742ff52fc80a2aa35cece833cf5319009b52f1b5a86c27";
      };

      beamDeps = [ ];
    };

    surface = buildMix rec {
      name = "surface";
      version = "0.10.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "2cbf3217c1184980a058edc33f9fd8e47c67ebe0c46c2c6448e663eee095dc82";
      };

      beamDeps = [ jason phoenix_live_view sourceror ];
    };

    sweet_xml = buildMix rec {
      name = "sweet_xml";
      version = "0.7.3";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "e110c867a1b3fe74bfc7dd9893aa851f0eed5518d0d7cad76d7baafd30e4f5ba";
      };

      beamDeps = [ ];
    };

    table_rex = buildMix rec {
      name = "table_rex";
      version = "3.1.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "678a23aba4d670419c23c17790f9dcd635a4a89022040df7d5d772cb21012490";
      };

      beamDeps = [ ];
    };

    telemetry = buildRebar3 rec {
      name = "telemetry";
      version = "1.2.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "dad9ce9d8effc621708f99eac538ef1cbe05d6a874dd741de2e689c47feafed5";
      };

      beamDeps = [ ];
    };

    telemetry_metrics = buildMix rec {
      name = "telemetry_metrics";
      version = "0.6.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "7be9e0871c41732c233be71e4be11b96e56177bf15dde64a8ac9ce72ac9834c6";
      };

      beamDeps = [ telemetry ];
    };

    telemetry_poller = buildRebar3 rec {
      name = "telemetry_poller";
      version = "1.0.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "b3a24eafd66c3f42da30fc3ca7dda1e9d546c12250a2d60d7b81d264fbec4f6e";
      };

      beamDeps = [ telemetry ];
    };

    telemetry_registry = buildMix rec {
      name = "telemetry_registry";
      version = "0.3.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "6d0ca77b691cf854ed074b459a93b87f4c7f5512f8f7743c635ca83da81f939e";
      };

      beamDeps = [ telemetry ];
    };

    temp = buildMix rec {
      name = "temp";
      version = "0.4.7";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "6af19e7d6a85a427478be1021574d1ae2a1e1b90882586f06bde76c63cd03e0d";
      };

      beamDeps = [ ];
    };

    tesla = buildMix rec {
      name = "tesla";
      version = "1.6.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "3593ac332caebb2850876116047a2051867e319d7cf3bf1c71be68dc099a6f21";
      };

      beamDeps = [ castore hackney jason mime poison telemetry ];
    };

    text = buildMix rec {
      name = "text";
      version = "0.2.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "5ca265ba24bd2f00ab647dd524305e24cc17224b4f0052f169ff488013888bc3";
      };

      beamDeps = [ flow ];
    };

    text_corpus_udhr = buildMix rec {
      name = "text_corpus_udhr";
      version = "0.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "056a0b6a804ef03070f89b9b2e09d3271539654f4e2c30bb7d229730262f3fb8";
      };

      beamDeps = [ text ];
    };

    thousand_island = buildMix rec {
      name = "thousand_island";
      version = "0.6.7";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "541a5cb26b88adf8d8180b6b96a90f09566b4aad7a6b3608dcac969648cf6765";
      };

      beamDeps = [ telemetry ];
    };

    timex = buildMix rec {
      name = "timex";
      version = "3.7.11";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "8b9024f7efbabaf9bd7aa04f65cf8dcd7c9818ca5737677c7b76acbc6a94d1aa";
      };

      beamDeps = [ combine gettext tzdata ];
    };

    tls_certificate_check = buildRebar3 rec {
      name = "tls_certificate_check";
      version = "1.17.4";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "faf16168b340d965da7b7dd20b73301d24bff925fb4218bb1d6cc54aa41875ad";
      };

      beamDeps = [ ssl_verify_fun ];
    };

    twinkle_star = buildMix rec {
      name = "twinkle_star";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/twinkle_star";
        rev = "627a29bc426313c4d680803792b77eb8921c4e9d";
        ref = "HEAD";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    typed_struct = buildMix rec {
      name = "typed_struct";
      version = "0.3.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "c50bd5c3a61fe4e198a8504f939be3d3c85903b382bde4865579bc23111d1b6d";
      };

      beamDeps = [ ];
    };

    tzdata = buildMix rec {
      name = "tzdata";
      version = "1.1.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "a69cec8352eafcd2e198dea28a34113b60fdc6cb57eb5ad65c10292a6ba89787";
      };

      beamDeps = [ hackney ];
    };

    unicode_util_compat = buildRebar3 rec {
      name = "unicode_util_compat";
      version = "0.7.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "25eee6d67df61960cf6a794239566599b09e17e668d3700247bc498638152521";
      };

      beamDeps = [ ];
    };

    unsafe = buildMix rec {
      name = "unsafe";
      version = "1.0.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "6c7729a2d214806450d29766abc2afaa7a2cbecf415be64f36a6691afebb50e5";
      };

      beamDeps = [ ];
    };

    untangle = buildMix rec {
      name = "untangle";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/untangle";
        rev = "79e3ae8120bf42c06a0cd1d63f6ea85455c641c1";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    uuid = buildMix rec {
      name = "uuid";
      version = "1.1.8";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "c790593b4c3b601f5dc2378baae7efaf5b3d73c4c6456ba85759905be792f2ac";
      };

      beamDeps = [ ];
    };

    verbs = buildMix rec {
      name = "verbs";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/shannonwells/verbs_ex";
        rev = "4b27067385390d4d2063ec1a09f9d96b97ed9a73";
        ref = "HEAD";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    versioce = buildMix rec {
      name = "versioce";
      version = "2.0.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "b2112ce621cd40fe23ad957a3dd82bccfdfa33c9a7f1e710a44b75ae772186cc";
      };

      beamDeps = [ git_cli ];
    };

    voodoo = buildMix rec {
      name = "voodoo";

      src = fetchGitMixDep {
        name = "${name}";
        url = "https://github.com/bonfire-networks/voodoo";
        rev = "a5065ccf0bf13dbacdaa128b93f6c721d21c3806";
        ref = "main";
      };
      version = builtins.readFile src.version;
      # Interection of all of the packages mix2nix found and those
      # declared in the package:
      beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
    };

    waffle = buildMix rec {
      name = "waffle";
      version = "1.1.7";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "e97e7b10b7f380687b5dc5e65b391538a802eff636605ad183e0bed29b45b0ef";
      };

      beamDeps = [ ex_aws ex_aws_s3 hackney sweet_xml ];
    };

    wallaby = buildMix rec {
      name = "wallaby";
      version = "0.30.3";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "40844afbf3bf6933f21406bdba2c59042ea0983b7a2533a51f46d372d79bc400";
      };

      beamDeps = [ ecto_sql httpoison jason phoenix_ecto web_driver_client ];
    };

    web_driver_client = buildMix rec {
      name = "web_driver_client";
      version = "0.2.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "83cc6092bc3e74926d1c8455f0ce927d5d1d36707b74d9a65e38c084aab0350f";
      };

      beamDeps = [ hackney jason tesla ];
    };

    websock = buildMix rec {
      name = "websock";
      version = "0.5.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "b51ac706df8a7a48a2c622ee02d09d68be8c40418698ffa909d73ae207eb5fb8";
      };

      beamDeps = [ ];
    };

    websock_adapter = buildMix rec {
      name = "websock_adapter";
      version = "0.5.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "16318b124effab8209b1eb7906c636374f623dc9511a8278ad09c083cea5bb83";
      };

      beamDeps = [ bandit plug plug_cowboy websock ];
    };

    zest = buildMix rec {
      name = "zest";
      version = "0.1.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "ebe2d6acf615de286e45846a3d6daf72d7c20f2c5eefada6d8a1729256a3974a";
      };

      beamDeps = [ ];
    };
  };
in
self

