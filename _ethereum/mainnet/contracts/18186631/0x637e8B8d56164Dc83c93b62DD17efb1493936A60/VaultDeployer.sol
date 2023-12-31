// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IVaultDeployer.sol";
import "./IVault.sol";
import "./FungibleVestingVault.sol";
import "./MultiVault.sol";
import "./IVaultKey.sol";

contract VaultDeployer is IVaultDeployer {
    enum VaultStatus {
        Inactive,
        Locked,
        Unlocked
    }

    IVaultKey public immutable keyNFT;
    address public immutable vaultFactory;

    event VaultFactoryUpdated(address indexed oldFactory, address indexed newFactory);

    constructor(address _keyNFT, address _vaultFactory) {
        keyNFT = IVaultKey(_keyNFT);
        vaultFactory = _vaultFactory;
    }

    function createVestingVault(
        bool shouldMintKey,
        address beneficiary,
        uint256 unlockTimestamp,
        bytes memory fungibleTokenDeposits
    ) external override onlyFromFactory returns (address) {
        FungibleVestingVault vault = new FungibleVestingVault(vaultFactory, address(keyNFT), beneficiary, unlockTimestamp, fungibleTokenDeposits);
        if (shouldMintKey) {
            keyNFT.mintKey(beneficiary, address(vault));
            vault.mintKey(keyNFT.lastMintedKeyId(beneficiary));
        }
        return address(vault);
    }

    function createBatchVault(
        bool shouldMintKey,
        address beneficiary,
        uint256 unlockTimestamp,
        bytes memory fungibleTokenDeposits,
        bytes memory nonFungibleTokenDeposits,
        bytes memory multiTokenDeposits
    ) external override onlyFromFactory returns (address) {
        MultiVault vault = new MultiVault(
            vaultFactory,
            address(keyNFT),
            beneficiary,
            unlockTimestamp,
            fungibleTokenDeposits,
            nonFungibleTokenDeposits,
            multiTokenDeposits
        );
        if (shouldMintKey) {
            keyNFT.mintKey(beneficiary, address(vault));
            vault.mintKey(keyNFT.lastMintedKeyId(beneficiary));
        }
        return address(vault);
    }

    function mintKey(address vaultAddress) external {
        IVault vault = IVault(vaultAddress);
        address beneficiary = vault.getBeneficiary();
        require(msg.sender == beneficiary, "VaultDeployer: Only beneficiary can mint key");
        keyNFT.mintKey(beneficiary, vaultAddress);
        vault.mintKey(keyNFT.lastMintedKeyId(beneficiary));
    }

    modifier onlyFromFactory() {
        require(msg.sender == vaultFactory, "VaultDeployer: Only callable from factory");
        _;
    }
}
