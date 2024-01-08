// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IERC20.sol";

interface IPoolFactory {
    event PoolCreated(
        uint256 indexed poolId,
        address indexed addr,
        address indexed creator
    );

    function getFeeInfo() external view returns (address, uint256);

    function getBaseInfo() external view returns (IERC20, uint256);
}
