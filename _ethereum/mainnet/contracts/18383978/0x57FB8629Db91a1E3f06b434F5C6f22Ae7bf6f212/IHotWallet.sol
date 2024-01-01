// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IHotWallet {
    function getHotWallet(address coldWallet) external view returns (address);

    function balanceOf(address contractAddress, address owner) external view returns (uint256);

    function ownerOf(address contractAddress, uint256 tokenId) external view returns (address);
}
