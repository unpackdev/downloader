// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOnTransfer {
    function onTransfer(address from, address to, uint256 tokenId) external;
}
