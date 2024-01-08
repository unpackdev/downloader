// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./IAbstractCooldownStaking.sol";

interface ILiquidityMiningStaking is IAbstractCooldownStaking{

    function rewardPerToken() external view returns (uint256);

    function earned(address _account) external view returns (uint256);

    function stakeFor(address _user, uint256 _amount) external;

    function stakeWithPermit(uint256 _stakingAmount, uint8 _v, bytes32 _r, bytes32 _s) external;

    function stake(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function callGetReward() external;

    function getReward() external;

    function restake() external;

    function exit() external;

    function getAPY() external view returns (uint256);
}
