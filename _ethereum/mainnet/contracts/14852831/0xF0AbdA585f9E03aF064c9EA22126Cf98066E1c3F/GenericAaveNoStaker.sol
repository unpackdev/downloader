// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "./GenericAaveUpgradeable.sol";

/// @title GenericAaveNoStaker
/// @author  Angle Core Team
/// @notice Only deposit onto Aave lendingPool with no staking
/// @dev In this implementation, we just have to override the base functions with constant amounts as nothing is
/// staked in an external contract
contract GenericAaveNoStaker is GenericAaveUpgradeable {
    // ================================ Constructor ================================

    /// @notice Wrapper on top of the `initializeAave` method
    function initialize(
        address _strategy,
        string memory name,
        bool _isIncentivised,
        address[] memory governorList,
        address guardian,
        address[] memory keeperList
    ) external {
        initializeAave(_strategy, name, _isIncentivised, governorList, guardian, keeperList);
    }

    // =========================== Virtual Functions ===============================

    function _stake(uint256) internal override returns (uint256) {}

    function _unstake(uint256 amount) internal pure override returns (uint256) {
        return amount;
    }

    /// @notice Gets current staked balance (e.g 0 if nothing is staked)
    function _stakedBalance() internal pure override returns (uint256) {
        return 0;
    }

    /// @notice Get stakingAPR after staking an additional `amount`: in this case since nothing
    /// is staked, it simply returns 0
    function _stakingApr(uint256) internal pure override returns (uint256) {
        return 0;
    }
}
