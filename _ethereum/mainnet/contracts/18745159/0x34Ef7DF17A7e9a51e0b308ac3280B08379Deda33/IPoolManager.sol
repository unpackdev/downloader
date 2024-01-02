// SPDX-License-Identifier: HORNEY

pragma solidity ^0.8.0;

interface IPoolManager {
    function addPool(address _pool, bool _isLegacy) external;
}
