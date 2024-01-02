// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "IERC721.sol";

import "ConfigKeys.sol";

import "IBatchVaultPriceOracle.sol";
import "IRateManager.sol";
import "IMotherboard.sol";
import "ISafetyCheck.sol";
import "IGyroConfig.sol";
import "IVaultRegistry.sol";
import "IAssetRegistry.sol";
import "IReserveManager.sol";
import "IReserve.sol";
import "IGYDToken.sol";
import "IFeeHandler.sol";
import "IGydRecovery.sol";
import "IPAMM.sol";
import "IReserveStewardshipIncentives.sol";
import "IVault.sol";

/// @notice Defines helpers to allow easy access to common parts of the configuration
library ConfigHelpers {
    function getRootPriceOracle(IGyroConfig gyroConfig)
        internal
        view
        returns (IBatchVaultPriceOracle)
    {
        return IBatchVaultPriceOracle(gyroConfig.getAddress(ConfigKeys.ROOT_PRICE_ORACLE_ADDRESS));
    }

    function getPAMM(IGyroConfig gyroConfig) internal view returns (IPAMM) {
        return IPAMM(gyroConfig.getAddress(ConfigKeys.PAMM_ADDRESS));
    }

    function getRootSafetyCheck(IGyroConfig gyroConfig) internal view returns (ISafetyCheck) {
        return ISafetyCheck(gyroConfig.getAddress(ConfigKeys.ROOT_SAFETY_CHECK_ADDRESS));
    }

    function getVaultRegistry(IGyroConfig gyroConfig) internal view returns (IVaultRegistry) {
        return IVaultRegistry(gyroConfig.getAddress(ConfigKeys.VAULT_REGISTRY_ADDRESS));
    }

    function getAssetRegistry(IGyroConfig gyroConfig) internal view returns (IAssetRegistry) {
        return IAssetRegistry(gyroConfig.getAddress(ConfigKeys.ASSET_REGISTRY_ADDRESS));
    }

    function getReserveManager(IGyroConfig gyroConfig) internal view returns (IReserveManager) {
        return IReserveManager(gyroConfig.getAddress(ConfigKeys.RESERVE_MANAGER_ADDRESS));
    }

    function getReserve(IGyroConfig gyroConfig) internal view returns (IReserve) {
        return IReserve(gyroConfig.getAddress(ConfigKeys.RESERVE_ADDRESS));
    }

    function getGYDToken(IGyroConfig gyroConfig) internal view returns (IGYDToken) {
        return IGYDToken(gyroConfig.getAddress(ConfigKeys.GYD_TOKEN_ADDRESS));
    }

    function getFeeHandler(IGyroConfig gyroConfig) internal view returns (IFeeHandler) {
        return IFeeHandler(gyroConfig.getAddress(ConfigKeys.FEE_HANDLER_ADDRESS));
    }

    function getMotherboard(IGyroConfig gyroConfig) internal view returns (IMotherboard) {
        return IMotherboard(gyroConfig.getAddress(ConfigKeys.MOTHERBOARD_ADDRESS));
    }

    function getGydRecovery(IGyroConfig gyroConfig) internal view returns (IGydRecovery) {
        return IGydRecovery(gyroConfig.getAddress(ConfigKeys.GYD_RECOVERY_ADDRESS));
    }

    function getReserveStewardshipIncentives(IGyroConfig gyroConfig)
        internal
        view
        returns (IReserveStewardshipIncentives)
    {
        return
            IReserveStewardshipIncentives(
                gyroConfig.getAddress(ConfigKeys.STEWARDSHIP_INC_ADDRESS)
            );
    }

    function getBalancerVault(IGyroConfig gyroConfig) internal view returns (IVault) {
        return IVault(gyroConfig.getAddress(ConfigKeys.BALANCER_VAULT_ADDRESS));
    }

    function getGlobalSupplyCap(IGyroConfig gyroConfig) internal view returns (uint256) {
        return gyroConfig.getUint(ConfigKeys.GYD_GLOBAL_SUPPLY_CAP, type(uint256).max);
    }

    function getStewardshipIncMinCollateralRatio(IGyroConfig gyroConfig)
        internal
        view
        returns (uint256)
    {
        return gyroConfig.getUint(ConfigKeys.STEWARDSHIP_INC_MIN_CR);
    }

    function getStewardshipIncMaxHealthViolations(IGyroConfig gyroConfig)
        internal
        view
        returns (uint256)
    {
        return gyroConfig.getUint(ConfigKeys.STEWARDSHIP_INC_MAX_VIOLATIONS);
    }

    function getStewardshipIncDuration(IGyroConfig gyroConfig) internal view returns (uint256) {
        return gyroConfig.getUint(ConfigKeys.STEWARDSHIP_INC_DURATION);
    }

    function getGovTreasuryAddress(IGyroConfig gyroConfig) internal view returns (address) {
        return gyroConfig.getAddress(ConfigKeys.GOV_TREASURY_ADDRESS);
    }

    function getRateManager(IGyroConfig gyroConfig) internal view returns (IRateManager) {
        return IRateManager(gyroConfig.getAddress(ConfigKeys.RATE_MANAGER_ADDRESS));
    }
}
