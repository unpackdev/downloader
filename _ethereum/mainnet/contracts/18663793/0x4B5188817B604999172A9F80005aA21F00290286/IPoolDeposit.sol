// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

struct Contribution {
    address contributor;
    uint256 amount;
} 

interface IPoolDeposit {

    event Deposit(uint256 indexed id, address indexed trader, uint256 amount, uint256 indexed poolId);
    event PooledDeposit(uint256 indexed id, uint256 amount);
    
    function individualDeposit(address contributor, uint256 amount) external;
    function pooledDeposit(Contribution[] calldata contributions) external;
}
