{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "sequoia-pqc-app";
  displayName = "Sequoia PQC";
  description = "Command-line OpenPGP tool with post-quantum cryptography support.";
  usage = ''
    Sequoia PQC (`sq`) is a command-line OpenPGP tool with post-quantum
    cryptography support, implementing draft-ietf-openpgp-pqc.

    #### Generate a key

    ```bash
    sq key generate --userid "Alice <alice@example.org>"
    ```

    #### Encrypt a file

    ```bash
    sq encrypt --recipient-cert alice.pgp message.txt
    ```

    #### Decrypt a file

    ```bash
    sq decrypt --recipient-key alice.key message.txt.pgp
    ```

    #### Sign a file

    ```bash
    sq sign --signer-key alice.key message.txt
    ```

    _Available in: shell._
  '';

  links = {
    website = "https://sequoia-pgp.org";
    source = "https://gitlab.com/sequoia-pgp/sequoia-sq";
  };

  ngi.grants = {
    Commons = [
      "Sequoia-PQC"
    ];
  };

  programs = {
    packages = [
      pkgs.mypkgs.sequoia-pqc
    ];

    runtimes.shell = {
      enable = true;
    };
  };

  test = {
    script = ''
      sq version
    '';
  };
}
