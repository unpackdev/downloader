// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

import "./IERC20.sol";

import "./IMasterWombatV3.sol";
import "./IBoostedMultiRewarder.sol";

/**
 * @dev Interface of BoostedMasterWombat
 */
interface IBoostedMasterWombat is IMasterWombatV3 {
    function getSumOfFactors(uint256 pid) external view returns (uint256 sum);

    function basePartition() external view returns (uint16);

    function add(IERC20 _lpToken, IBoostedMultiRewarder _boostedRewarder) external;

    function boostedRewarders(uint256 _pid) external view returns (IBoostedMultiRewarder);

    function setBoostedRewarder(uint256 _pid, IBoostedMultiRewarder _boostedRewarder) external;
}
