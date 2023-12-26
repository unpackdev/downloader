// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

import "./Points.sol";
import "./IUniversalVault.sol";
import "./IRageQuit.sol";
import "./IInstanceRegistry.sol";
import "./IPointsVaultExtension.sol";
import "./EnumerableSet.sol";

contract PointsVaultExtension is Points, IPointsVaultExtension {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private vaultFactorySet;

    constructor(string memory name_, string memory symbol_) Points(name_, symbol_) {}

    modifier onlyValidVault(address vault) {
        if (!isValidVault(vault)) {
            revert InvalidVault(vault);
        }
        _;
    }

    /**
     * @inheritdoc IPointsVaultExtension
     */
    function getVaultFactorySetLength() external view override returns (uint256 length) {
        length = vaultFactorySet.length();
    }

    /**
     * @inheritdoc IPointsVaultExtension
     */
    function getVaultFactoryAtIndex(uint256 index) external view override returns (address factory) {
        factory = vaultFactorySet.at(index);
    }

    /**
     * @inheritdoc IPointsVaultExtension
     */
    function isValidVault(address vault) public view override returns (bool validity) {
        // validate target is created from whitelisted vault factory
        for (uint256 index = 0; index < vaultFactorySet.length(); index++) {
            if (IInstanceRegistry(vaultFactorySet.at(index)).isInstance(vault)) {
                validity = true;
                break;
            }
        }
    }

    /**
     * @inheritdoc IPointsVaultExtension
     */
    function registerVaultFactory(address factory) external onlyOwner {
        if (!vaultFactorySet.add(factory)) {
            revert VaultFactoryAlreadyRegistered(factory);
        }
        emit VaultFactoryRegistered(factory);
    }

    /**
     * @inheritdoc IPointsVaultExtension
     */
    function removeVaultFactory(address factory) external onlyOwner {
        if (!vaultFactorySet.remove(factory)) {
            revert VaultFactoryNotRegistered(factory);
        }
        emit VaultFactoryRemoved(factory);
    }

    /**
     * @inheritdoc IPointsVaultExtension
     */
    function stakeToken(address vault, address token, uint128 amount, bytes calldata permission)
        external
        onlyValidVault(vault)
        preConvertPendingPoints(vault, token)
    {
        tokenStakes[vault][token].amount += amount;

        // Call lock on vault
        IUniversalVault(vault).lock(token, amount, permission);

        emit TokenVaultLocked(vault, token, amount);
    }

    /**
     * @inheritdoc IPointsVaultExtension
     */
    function unstakeToken(address vault, address token, uint128 amount, bytes calldata permission)
        external
        preConvertPendingPoints(vault, token)
    {
        uint128 stakedAmount = tokenStakes[vault][token].amount;
        if (stakedAmount < amount) {
            revert InsufficientTokenBalance(stakedAmount, amount);
        }
        IUniversalVault(vault).unlock(token, amount, permission);
        tokenStakes[vault][token].amount = stakedAmount - amount;

        emit TokenVaultUnlocked(vault, token, amount);
    }

    /**
     * @inheritdoc IRageQuit
     */
    function rageQuit() external {
        for (uint256 i = 0; i < tokenAt.length; i++) {
            address token = tokenAt[i];
            delete tokenStakes[_msgSender()][token];
        }
    }
}
