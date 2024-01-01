// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurveRouter {
             
function exchange(
        address[11] calldata _pool,
        uint256[5][5] calldata i,
        uint256 _amountA,
        uint256 _amountB,
        address[5] calldata addresses
    ) external;
}