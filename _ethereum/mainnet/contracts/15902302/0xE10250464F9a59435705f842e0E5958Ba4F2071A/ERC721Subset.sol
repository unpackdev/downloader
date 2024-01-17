// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./Ownable.sol";
import "./ERC165.sol";

/*

ERC721Subset creates an ERC721 collection that is a subset of the original one.

- Add tokens of the original collection to the subset using add(tokenId).
- Remove tokens from the subset using remove(tokenId).
- Check if a token is in the subset using exists(tokenId).
- tokenURI(tokenId) is proxied to the original contract tokenURI.

All tokens of the subset are owned by the smart contract and they can NOT be transfered.

Adding items and removing items is implemented as mint and burn, to make it easier for
marketplaces to track them. Since most marketplaces will not hide burned items, a special
tokenURI is used for items that have been removed from the subcollection that displays
an empty (transparent) image.

All ERC721Metadata functions have been implemented to ensure compatibility with 
ERC721-aware marketplaces and apps, but functions related to approvals and transfers will
just revert with an error.

*/

contract ERC721Subset is ERC165, Ownable {
    string constant private _burnedTokenURI = 'data:application/json;base64,eyJkZXNjcmlwdGlvbiI6ICJUaGlzIGl0ZW0gd2FzIGJ1cm5lZCBhbmQgcmVtb3ZlZCBmcm9tIHRoZSB2aXJ0dWFsIGNvbGxlY3Rpb24uIiwiaW1hZ2UiOiJkYXRhOmltYWdlL3BuZztiYXNlNjQsaVZCT1J3MEtHZ29BQUFBTlNVaEVVZ0FBQUFFQUFBQUJDQVlBQUFBZkZjU0pBQUFBQzBsRVFWUUlIV05nQUFJQUFBVUFBWTI3bS9NQUFBQUFTVVZPUks1Q1lJST0iLCJuYW1lIjoiUmVtb3ZlZCBpdGVtIn0=';
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    // vToken name
    string private _name;

    // vToken symbol
    string private _symbol;

    // Virtual tokens
    mapping(uint => bool) private vToken;

    // Original Collection address;
    address private _collection;

    // Number of items in the virtual collection.
    uint private _count = 0;

    constructor(string memory name_, string memory symbol_, address collection_) {
        _name = name_;
        _symbol = symbol_;
        _collection = collection_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function add(uint256 tokenId) public onlyOwner { 
        _mint(tokenId);
    }
    function remove(uint256 tokenId) public onlyOwner { 
        _burn(tokenId);
    }
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function totalSupply() public view returns (uint) {
        return _count;
    }

    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(this)) {
            return totalSupply();
        }
        return uint(0);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        require(vToken[tokenId], "ERC721: invalid token ID");
        return address(this);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function collection() public view returns (address) {
        return _collection;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        if (vToken[tokenId]) {
        return IERC721Metadata(_collection).tokenURI(tokenId);
        } else {
            return _burnedTokenURI;
        }
    }

    function approve(address /*to*/, uint256 /*tokenId*/) public pure {
        revert("ERC721: approve caller is not token owner nor approved for all");
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        _requireMinted(tokenId);
        return address(0);
    }

    function setApprovalForAll(address /* operator */, bool /*approved*/ ) public pure {
        revert("ERC721: approve to caller");
    }

    function isApprovedForAll(address /*owner*/, address /*operator*/) public pure returns (bool) {
        return false;
    }

    function transferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/
    ) public pure {
        revert("ERC721: caller is not token owner nor approved");
    }

    function safeTransferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/
    ) public pure {
        revert("ERC721: caller is not token owner nor approved");
    }

    function safeTransferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/,
        bytes memory /*data*/
    ) public pure {
        revert("ERC721: caller is not token owner nor approved");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return vToken[tokenId] ;
    }

    function _mint(uint256 tokenId) internal { 
        require(!vToken[tokenId], "ERC721: token already minted");
        vToken[tokenId] = true;
        _count++;
        emit Transfer(address(0), address(this), tokenId);
    }

    function _burn(uint256 tokenId) internal {
        require(vToken[tokenId], "ERC721: invalid token ID");
        delete vToken[tokenId];
        _count-- ;
        emit Transfer(address(this), address(0x000000000000000000000000000000000000dEaD), tokenId);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(vToken[tokenId], "ERC721: invalid token ID");
    }
}