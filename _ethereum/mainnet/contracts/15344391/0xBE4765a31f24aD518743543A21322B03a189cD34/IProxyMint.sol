// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IProxyMint {
    function isStake(uint256 _tokenId) external view returns (bool);
    function hasStake(address minter) external view returns (bool);
}
