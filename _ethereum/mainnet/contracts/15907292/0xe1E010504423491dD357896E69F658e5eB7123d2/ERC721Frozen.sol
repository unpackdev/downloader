// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";

/**
 * Override some function from OpenZeppelin ERC721 code to make it untransferable
 */
abstract contract ERC721Frozen is ERC721 {
    modifier isDisabled() {
        revert("ERC721Frozen: this ERC721 is read-only");
        _;
    }

    // Disabled public functions
    function approve(address to, uint256 tokenId) isDisabled public override {}
    function setApprovalForAll(address operator, bool approved) isDisabled public override {}
    function transferFrom(address from, address to, uint256 tokenId) isDisabled public override {}
    function safeTransferFrom(address from, address to, uint256 tokenId) isDisabled public override {}
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) isDisabled public override {}

    // Disabled internal functions
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) isDisabled internal override {}
    function _burn(uint256 tokenId) isDisabled internal override {}
    function _transfer(address from, address to, uint256 tokenId) isDisabled internal override {}
    function _approve(address to, uint256 tokenId) isDisabled internal override {}
    function _setApprovalForAll(address owner, address operator, bool approved) isDisabled internal override {}
    
    /**
     * Override this function as there is no more approval possible, so it's simply spender == owner
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner);
    }
}