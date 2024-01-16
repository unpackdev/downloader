// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "./Ownable.sol";

import "./ISavingsVaultViews.sol";
import "./IJobConfig.sol";
import "./INotionalV2.sol";

/// @title JobConfig functions
/// @notice Contains function for configuring phuture jobs
contract JobConfig is IJobConfig, Ownable {
    /// @inheritdoc IJobConfig
    uint public constant SCALING_STEPS = 3;
    /// @inheritdoc IJobConfig
    uint public constant SCALING_PERCENTAGE = 3000;
    /// @inheritdoc IJobConfig
    HarvestingSpecification public harvestingSpecification;
    /// @inheritdoc IJobConfig
    ISavingsVaultViews public savingsVaultViews;

    constructor(ISavingsVaultViews _savingsVaultViews) {
        savingsVaultViews = _savingsVaultViews;
        harvestingSpecification = HarvestingSpecification.SCALED_AMOUNT;
    }

    /// @inheritdoc IJobConfig
    function setSavingsVaultViews(ISavingsVaultViews _savingsVaultViews) external onlyOwner {
        savingsVaultViews = _savingsVaultViews;
    }

    /// @inheritdoc IJobConfig
    function setHarvestingAmountSpecification(HarvestingSpecification _harvestingSpecification) external onlyOwner {
        harvestingSpecification = _harvestingSpecification;
    }

    /// @inheritdoc IJobConfig
    function getDepositedAmount(address _savingsVault) external view returns (uint) {
        if (harvestingSpecification == HarvestingSpecification.MAX_AMOUNT) {
            return type(uint).max;
        } else if (harvestingSpecification == HarvestingSpecification.MAX_DEPOSITED_AMOUNT) {
            return savingsVaultViews.getMaxDepositedAmount(_savingsVault);
        } else if (harvestingSpecification == HarvestingSpecification.SCALED_AMOUNT) {
            uint amount = savingsVaultViews.getMaxDepositedAmount(_savingsVault);
            if (amount == 0) {
                return amount;
            }
            return savingsVaultViews.scaleAmount(_savingsVault, amount, SCALING_PERCENTAGE, SCALING_STEPS);
        }
        return 0;
    }
}
