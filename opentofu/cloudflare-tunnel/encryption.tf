# State and plan files are encrypted at rest with a fresh AES-256 data key that
# scripts/tofu-state-key.sh wraps with the homelab age recipient. Recovery needs
# only the sops age key.
#
# Do not rename the key provider or method: their names are stored in the
# encrypted state metadata and renaming makes the state unreadable.
terraform {
  encryption {
    key_provider "external" "age" {
      command = [
        abspath("${path.root}/../../scripts/tofu-state-key.sh"),
        "--recipient", "age1fwn0l05325gc4p827dgqw5s0k38an0cuum87pj2359ugyd0rhc6s50yqn9",
      ]
    }

    method "aes_gcm" "main" {
      keys = key_provider.external.age
    }

    state {
      method   = method.aes_gcm.main
      enforced = true
    }

    plan {
      method   = method.aes_gcm.main
      enforced = true
    }
  }
}
