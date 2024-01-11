// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;

interface IRegistry {
    event NewVaultRelease(
        uint256 indexed vault_release_id,
        address template,
        string api_version
    );

    event NewVault(
        address indexed token,
        uint256 indexed vault_id,
        address vault,
        string api_version
    );

    event NewExperimentalVault(
        address indexed token,
        address indexed deployer,
        address vault,
        string api_version
    );

    event VaultTagged(address vault, string tag);
}
