// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ICurve3PoolStrategyStorage {
    function pool() external view returns (address);

    function gauge() external view returns (address);

    function mintr() external view returns (address);

    function index() external view returns (uint256);
}
