// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";

contract Coronation {
    address public constant CROWN_CONTRACT_ADDRESS = 0x60E4d786628Fea6478F785A6d7e704777c86a7c6;
    uint256 public constant CROWN_TOKEN_ID = 24762;

    // Mapping from NFT address and ID to knight status
    mapping(address => mapping(uint256 => bool)) private _isKnight;
    // Mapping from NFT address and ID to banished status
    mapping(address => mapping(uint256 => bool)) private _isBanished;

    function doesOwnCrown(address account) public view returns (bool) {
        IERC721 crownContract = IERC721(CROWN_CONTRACT_ADDRESS);
        return crownContract.ownerOf(CROWN_TOKEN_ID) == account;
    }

    function addKnight(address nftAddress, uint256 tokenId) public {
        require(doesOwnCrown(msg.sender), "Only the Crown owner can add knights");
        _isKnight[nftAddress][tokenId] = true;
    }

    function removeKnight(address nftAddress, uint256 tokenId) public {
        require(doesOwnCrown(msg.sender), "Only the Crown owner can remove knights");
        _isKnight[nftAddress][tokenId] = false;
    }

    function isKnight(address nftAddress, uint256 tokenId) public view returns (bool) {
        return _isKnight[nftAddress][tokenId];
    }

    function banish(address nftAddress, uint256 tokenId) public {
        require(doesOwnCrown(msg.sender), "Only the Crown owner can banish");
        _isBanished[nftAddress][tokenId] = true;
    }

    function isBanished(address nftAddress, uint256 tokenId) public view returns (bool) {
        return _isBanished[nftAddress][tokenId];
    }
}