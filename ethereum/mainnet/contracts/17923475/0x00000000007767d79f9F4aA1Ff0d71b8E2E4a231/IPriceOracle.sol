// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IPriceOracle {
    error PoolNotAllowed();
    error PriceIsZero();

    event PoolAdded(address token, address pool);
    event PoolRemoved(address token);

    function getTWAP(address token, uint32 secondsAgo) external view returns (uint256);
}
