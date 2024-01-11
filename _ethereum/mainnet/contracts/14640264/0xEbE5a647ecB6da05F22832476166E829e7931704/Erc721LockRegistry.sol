// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

import "./ERC721B.sol";
import "./LockRegistry.sol";
import "./ILockERC721.sol";

abstract contract Erc721LockRegistry is ERC721B, LockRegistry, ILockERC721 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _offset
    ) ERC721B(_name, _symbol, _offset) {}

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721B, IERC721) {
        require(isUnlocked(tokenId), "Token is locked");
        ERC721B.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override(ERC721B, IERC721) {
        require(isUnlocked(tokenId), "Token is locked");
        ERC721B.safeTransferFrom(from, to, tokenId, _data);
    }

    function lockId(uint256 _id) external override {
        require(_exists(_id), "Token !exist");
        _lockId(_id);
    }

    function unlockId(uint256 _id) external override {
        require(_exists(_id), "Token !exist");
        _unlockId(_id);
    }

    function freeId(uint256 _id, address _contract) external override {
        require(_exists(_id), "Token !exist");
        _freeId(_id, _contract);
    }
}
