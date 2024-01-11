/// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

interface IBaseRewardPool {
    function pid() external view returns (uint256);

    function stakeFor(address _for, uint256 _amount) external returns (bool);
}
