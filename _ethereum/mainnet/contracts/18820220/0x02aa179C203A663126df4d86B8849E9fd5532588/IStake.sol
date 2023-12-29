// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface IStake {

    function stake(uint256 amount) external;

    function stakeFrom(address sender, uint256 amount) external;

    function getReward(address sender) external view returns (uint256 reward);
}
