// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NFT {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    constructor() {
        emit Transfer(address(0), address(0xf), 0);
    }
    
    function name() external pure returns (string memory) {
        return "\u6797\u4f5b\u94a7";
    }

    function symbol() external pure returns (string memory) {
        return "F";
    }

    function tokenURI(uint256 tokenId) external pure returns (string memory) {
        return "data:application/json;base64,eyJuYW1lIjoi5LiA5YiHIiwiZGVzY3JpcHRpb24iOiLkuIDliIfmmK/kuIDliIfvvIzlrZjlnKjlj4jkuI3lrZjlnKjvvIzlvIDlp4vnu5PmnZ/lj4jmnKrlvIDlp4vnu5PmnZ8iLCJpbWFnZSI6ImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjRiV3h1Y3owaWFIUjBjRG92TDNkM2R5NTNNeTV2Y21jdk1qQXdNQzl6ZG1jaUlIZHBaSFJvUFNJMU1USWlJR2hsYVdkb2REMGlOVEV5SWo0OGRHVjRkQ0I0UFNJMU1DVWlJSGs5SWpVd0pTSWdabTl1ZEMxemFYcGxQU0l6TUNJZ2RHVjRkQzFoYm1Ob2IzSTlJbTFwWkdSc1pTSSs1YnlBNWFlTElDQWc1cDZYNUwyYjZaS25JQ0FnNUxpQTVZaUhJQ0FnNTd1VDVwMmZQQzkwWlhoMFBqd3ZjM1puUGc9PSJ9";
    }
    
    function balanceOf(address owner) external pure returns (uint256) {
        return 1;
    }

    function ownerOf(uint256 tokenId) external pure returns (address) {
        return address(0xf);
    }

    function getApproved(uint256 tokenId) external pure returns (address) {
        return address(0);
    }

    function isApprovedForAll(address owner, address operator) external pure returns (bool) {
        return false;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC165 ||
               interfaceId == _INTERFACE_ID_ERC721 ||
               interfaceId == _INTERFACE_ID_ERC721_METADATA;
    }
}