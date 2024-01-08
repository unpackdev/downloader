// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author jpegmint.xyz

import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./Context.sol";
import "./ERC165.sol";

/**
 */
contract ERC721Virtual is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to minted bool status
    mapping(uint256 => bool) private _mintedTokens;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Owners can have max 1 of virutal tokens.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721Virtual: balance query for the zero address");
        return 1;
    }

    /**
     * @dev Owner is always tokenId -> address
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        require(tokenId != 0, "ERC721Virtual: owner query for nonexistent token");
        return address(uint160(tokenId));
    }

    /**
     @dev Returns whether the token is minted or virtual
     */
    function isMinted(uint256 tokenId) public view virtual returns (bool) {
        return _mintedTokens[tokenId];
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return "";
    }

    /**
     * @dev Force use of this ownerOf function
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721Virtual: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721Virtual: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }
    
    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address, address, uint256) public virtual override {
        revert("ERC721Virtual: Virtual tokens can not be transferred");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address, address, uint256, bytes memory) public virtual override {
        revert("ERC721Virtual: Virtual tokens can not be transferred");
    }

    /**
     * @dev Virtual tokens always exist either as virtual or minted
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId != 0;
    }

    /**
     * @dev Force use of this ownerOf function
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721Virtual: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`. safeMint not implemented as tokens are
     * not transferrable and virtual.
     */
    function _mint(address to) internal virtual {
        uint256 tokenId = uint256(uint160(to));
        require(to != address(0), "ERC721Virtual: mint to the zero address");
        require(!isMinted(tokenId), "ERC721Virtual: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _mintedTokens[tokenId] = true;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     */
    function _burn(uint256 tokenId) internal virtual {
        require(isMinted(tokenId), "ERC721Virtual: token not minted");
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0), tokenId);
        _mintedTokens[tokenId] = false;

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    
    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index == 0, "ERC721Virtual: owner index out of bounds");
        return uint256(uint160(owner));
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return type(uint160).max;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < totalSupply(), "ERC721Virtual: global index out of bounds");
        return index + 1;
    }
}
