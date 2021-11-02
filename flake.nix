{
  description = "A library for rendering project templates";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    mach-nix.url = "github:DavHau/mach-nix";

    #
    # Non-nix-provided dependencies
    #
    # python39Packages.jinja2 is at version 3.0.1, we need 3.0.2
    jinja2 = {
      url = "github:pallets/jinja2";
      flake = false;
    };
    dunamai = {
      url = "github:mtkennerly/dunamai";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, mach-nix, ... }@inputs:
    let
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
      pyPackages = pkgs.python39Packages;
      pyBuild = pyPackages.buildPythonPackage;
      updatedJinja2 = pyBuild {
        pname = "Jinja2";
        version = "3.0.2";
        src = inputs.jinja2;
        propagatedBuildInputs = with pyPackages; [ pyyaml markupsafe ];
      };
      dunamai = pyBuild {
        pname = "dunamai";
        version = "1.7.0";
        src = inputs.dunamai;
        format = "pyproject";
        propagatedBuildInputs = with pyPackages; [ poetry ];
      };
      pkgOverride = { ps, lib, stdenv }:
        (final: prev: {
          jinja2 = updatedJinja2;
          dunamai = dunamai;
          pyyaml = pyPackages.pyyaml;
          markupsafe = pyPackages.markupsafe;
          pathspec = pyPackages.pathspec;
          packaging = pyPackages.packaging;
          six = pyPackages.six;
          distlib = pyPackages.distlib;
          virtualenv = pyPackages.virtualenv;
          filelock = pyPackages.filelock;
          requests-toolbelt = pyPackages.requests-toolbelt;
          shellingham = pyPackages.shellingham;
          tomlkit = pyPackages.tomlkit;
          toml = pyPackages.toml;
          #urllib3 = pyPackages.urllib3;
          #cffi = pyPackages.cffi;
          #pycparser = pyPackages.pycparser;
        });

    in {
      # Nixpkgs overlay providing the application
      overlay = (final: prev: {
        copier = mach-nix.lib."x86_64-linux".buildPythonPackage {
          python = "python39";
          pname = "copier";
          version = "5.1.0";
          providers.pyyaml = "nixpkgs";
          providers.markupsafe = "nixpkgs";
          providers.pathspec = "nixpkgs";
          providers.packaging = "nixpkgs";
          providers.six = "nixpkgs";
          providers.distlib = "nixpkgs";
          providers.virtualenv = "nixpkgs";
          providers.filelock = "nixpkgs";
          providers.requests-toolbelt = "nixpkgs";
          providers.shellingham = "nixpkgs";
          providers.tomlkit = "nixpkgs";
          providers.toml = "nixpkgs";
          providers.urllib3 = "nixpkgs";
          providers.cffi = "nixpkgs";
          providers.pycparser = "nixpkgs";
          src = ./.;
          format = "pyproject";
          overridesPost = [
            (pkgOverride {
              ps = pkgs;
              lib = pkgs.lib;
              stdenv = pkgs.stdenv;
            })
          ];
          requirements = ''
            "backports.cached-property"
            colorama
            dunamai
            importlib-metadata
            iteration_utilities
            Jinja2
            jinja2-ansible-filters
            mkdocs-material
            mkdocs-mermaid2-plugin
            mkdocstrings
            packaging
            pathspec
            plumbum
            pydantic
            Pygments
            PyYAML
            pyyaml-include
            questionary
            typing-extensions

            autoflake
            black
            flake8
            flake8-bugbear
            flake8-comprehensions
            flake8-debugger
            mypy
            pexpect
            poethepoet
            pre-commit
            pytest
            pytest-cov
            pytest-xdist
            poetry
          '';
        };
      });
    } // (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        };
      in rec {
        apps = { copier = (flake-utils.lib.mkApp { drv = pkgs.copier; }); };

        defaultApp = apps.copier;
        defaultPackage = pkgs.copier;
      }));
}
