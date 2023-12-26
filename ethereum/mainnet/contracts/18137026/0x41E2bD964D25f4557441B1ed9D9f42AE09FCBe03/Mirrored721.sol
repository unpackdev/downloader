// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721.sol";
import "./IERC721.sol";

contract Mirrored721 is ERC721 {
    error AlreadyMirrored();
    error NoApprovals();

    address private _contract;

    constructor(
        address contract_,
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {
        _contract = contract_;
    }

    function mirror(uint256 tokenId) public virtual {
        address from = _ownerOf(tokenId);
        address to = _ownerOfMirrored(tokenId);

        if (from == to) revert AlreadyMirrored();

        if (from == address(0)) {
            _mint(to, tokenId);
        } else if (to == address(0)) {
            _burn(tokenId);
        } else {
            _transfer(from, to, tokenId);
        }
    }

    function transferFrom(address, address, uint256 tokenId) public virtual override {
        mirror(tokenId);
    }

    function safeTransferFrom(address, address, uint256 tokenId) public virtual override {
        mirror(tokenId);
    }

    function safeTransferFrom(address, address, uint256 tokenId, bytes memory) public virtual override {
        mirror(tokenId);
    }

    function _mirroredContract() internal view returns (address) {
        return _contract;
    }

    function _ownerOfMirrored(uint256 tokenId) internal view virtual returns (address) {
        try IERC721(_contract).ownerOf(tokenId) returns (address owner) {
            return owner;
        } catch {
            return address(0);
        }
    }

    function approve(address, uint256) public pure override {
        revert NoApprovals();
    }

    function getApproved(uint256) public pure override returns (address) {
        return address(0);
    }

    function setApprovalForAll(address, bool) public pure override {
        revert NoApprovals();
    }

    function isApprovedForAll(address, address) public pure override returns (bool) {
        return false;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
        return spender == ERC721.ownerOf(tokenId);
    }

    function _approve(address, uint256) internal pure override {
        revert NoApprovals();
    }

    function _setApprovalForAll(address, address, bool) internal pure override {
        revert NoApprovals();
    }
}
