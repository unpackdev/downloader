// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IKeeperV2Oracle {
    function current(address, uint, address) external view returns (uint256, uint256);
}