// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Moonies.sol";
import "./IERC721.sol";
import "./Ownable.sol";

contract ERC721InteractProxy is IERC721, Ownable {
    Moonies public tokenContract;
    mapping(bytes4 => bool) internal supportedInterfaces;
    constructor() IERC721() {
        supportedInterfaces[0x80ac58cd] = true;
    }

    function setContract(address _address) public onlyOwner {
        tokenContract = Moonies(_address);
    }

    function balanceOf(address owner)
        external
        view
        override
        returns (uint256 balance)
    {
        return tokenContract.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId)
        external
        view
        override
        returns (address owner)
    {
        return tokenContract.ownerOf(tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override {
        tokenContract.safeTransferFrom(from, to, tokenId, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        tokenContract.safeTransferFrom(from, to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        tokenContract.transferFrom(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) external override {
        tokenContract.approve(to, tokenId);
    }

    function setApprovalForAll(address to, bool approved) external override {
        tokenContract.setApprovalForAll(to, approved);
    }

    function getApproved(uint256 tokenId)
        external
        view
        override
        returns (address)
    {
        return tokenContract.getApproved(tokenId);
    }

    function isApprovedForAll(address owner, address operator)
        external
        view
        override
        returns (bool)
    {
        return tokenContract.isApprovedForAll(owner, operator);
    }

    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return supportedInterfaces[interfaceId];
    }
}
