// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./IValidator.sol";
import "./RewardsBoosterErrors.sol";

/**
 * @title Asymetrix Protocol V2 ValidatorBalancerWeighted
 * @author Asymetrix Protocol Inc Team
 * @notice A validator that validates staking parameters in time of staking in the Balancer V2 Weighted staking pool on
 *         the RewardsBooster contract.
 */
contract ValidatorBalancerWeighted is IValidator {
    /// @inheritdoc IValidator
    function validateStake(uint8, uint256 _amount) external pure {
        if (_amount == 0) revert RewardsBoosterErrors.InvalidStakeArguments();
    }
}
