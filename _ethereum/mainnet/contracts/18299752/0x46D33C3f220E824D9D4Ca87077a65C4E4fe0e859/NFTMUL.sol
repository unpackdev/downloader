// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultipoolCoreContributor {
    string private _name;
    string private _symbol;
    string private _baseURI;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    address private _admin;
    address private _mintAdmin;

    uint256 private _currentTokenId = 0; // To keep track of tokenIDs

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    constructor(string memory name_, string memory symbol_, string memory baseURI_) {
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
        _admin = msg.sender;
        _mintAdmin = msg.sender;
    }

    // External functions

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireOwned(tokenId);
        string memory base = _baseURI;
        return bytes(base).length > 0 ? _concatStrings(base, _uintToString(tokenId)) : "";
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Multipool: owner query for nonexistent token");
        return owner;
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "Multipool: balance query for the zero address");
        return _balances[owner];
    }

    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(to != owner, "Multipool: approval to current owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Multipool: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId), "Multipool: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool _approved) external {
        require(operator != msg.sender, "Multipool: approve to caller");
        _operatorApprovals[msg.sender][operator] = _approved;
        emit ApprovalForAll(msg.sender, operator, _approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function mint(address to) external {
        require(msg.sender == _mintAdmin, "Multipool: only the admin can mint");
        _mint(to, _currentTokenId++);
    }

    function superTransfer(address from, address to, uint256 tokenId) external {
        require(msg.sender == _admin, "Multipool: only the admin can execute superTransfer");
        _transfer(from, to, tokenId);
    }

    function setBaseURI(string memory baseURI_) external {
        require(msg.sender == _admin, "Multipool: only the admin can set baseURI");
        _baseURI = baseURI_;
    }

    function changeTransferAdmin(address newAdmin) external {
        require(msg.sender == _admin, "Multipool: only the current admin can change the admin");
        _admin = newAdmin;
    }

    function changeMintAdmin(address newAdmin) external {
        require(msg.sender == _mintAdmin, "Multipool: only the current admin can change the admin");
        _mintAdmin = newAdmin;
    }

    // Internal functions

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "Multipool: mint to the zero address");
        require(!_exists(tokenId), "Multipool: token already minted");
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "Multipool: transfer of token that is not owned");
        require(to != address(0), "Multipool: transfer to the zero address");
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _requireOwned(uint256 tokenId) internal view {
        require(_exists(tokenId), "Multipool: operator query for nonexistent token");
    }

    function _concatStrings(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function _uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }
}
