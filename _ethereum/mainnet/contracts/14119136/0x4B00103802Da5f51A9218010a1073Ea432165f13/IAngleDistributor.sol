// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./IERC20.sol";

/// @title IAngleDistributor
/// @author Angle Core Team
/// @notice Interface for the `AngleDistributor` contract
interface IAngleDistributor {
    function rewardToken() external view returns (IERC20);

    function delegateGauge() external view returns (address);
}
