// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface INpLiquidityHolder {
    function getToken(address target, uint256 amount) external;
}