// commit 427ad29973083a8d6910314bbe8eb781e9c80166
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

interface IStargateFactory {
    function getPool(uint256) external view returns (address);
}
