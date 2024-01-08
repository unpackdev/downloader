// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract Fields {
    event TokenCreated(uint256 tokenId, address to);
    event MintFor(
        address to,
        uint256 amount,
        uint256 tokenId,
        uint16 proto,
        uint256 serialNumber,
        string tokenURI
    );

    string public _baseTokenURI;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SET_URI_ROLE = keccak256("SET_URI_ROLE");
}
