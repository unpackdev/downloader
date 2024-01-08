// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface ILPTokenSharePool {

    function stakeLP(address staker, address from, uint256 amount, uint term) external;
}