// SPDX-License-Identifier: MIT
// ForTube2.0 Contracts v1.2

pragma solidity ^0.8.1;

interface IForTube3Token {

    event MiningLog(uint256 indexed tokenId, address to, uint256 miningAmount, uint256 minedAmount, uint256 updatedBlock);

    function mintByTransferring(uint256 tokenId) external;
    function addMining(uint256 tokenId, address from) external;
    function mintByPad(address[] memory owners, uint256[] memory amounts) external;

}