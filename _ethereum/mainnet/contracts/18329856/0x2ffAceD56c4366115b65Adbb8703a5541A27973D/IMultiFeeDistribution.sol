// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;
pragma abicoder v2;

import "./LockedBalance.sol";
import "./IFeeDistribution.sol";

interface IMultiFeeDistribution is IFeeDistribution {
    function stake(uint256 amount, address onBehalfOf, uint256 typeIndex) external;

    function lockInfo(address user) external view returns (LockedBalance[] memory);

    function defaultLockIndex(address _user) external view returns (uint256);

    function autoRelockDisabled(address user) external view returns (bool);

    function totalBalance(address user) external view returns (uint256);

    function withdrawExpiredLocksFor(address _address) external returns (uint256);

    function claimableRewards(address account) external view returns (IFeeDistribution.RewardData[] memory rewards);

    function setDefaultRelockTypeIndex(uint256 _index) external;

    function stakingToken() external view returns (address);
}