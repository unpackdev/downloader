// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGlobalNftDeployer {
    //********************EVENT*******************************//
    event GlobalNftMinted(uint64 originChain, bool isERC1155, address originAddr, uint256 tokenId, address globalAddr);
    event GlobalNftBurned(uint64 originChain, bool isERC1155, address originAddr, uint256 tokenId, address globalAddr);

    //********************FUNCTION*******************************//
    function calcAddr(uint64 originChain, address originAddr) external view returns (address);

    function tokenURI(address globalNft, uint256 tokenId) external view returns (string memory);

    function isGlobalNft(address collection) external view returns (bool);
}
