pragma solidity ^0.8.6;

// SPDX-License-Identifier: MIT

interface ISmileToken {
    function mint(address to) external returns(uint256 tokenID);
    function balanceOf(address owner) external returns(uint256 balance);
    function safeTransferFrom(address sender, address receiver, uint256 tokenID) external;
    function totalSupply() external returns(uint256 tokens);
    function setTokenUri(uint256 _tokenID, string memory _tokenUri) external;
}