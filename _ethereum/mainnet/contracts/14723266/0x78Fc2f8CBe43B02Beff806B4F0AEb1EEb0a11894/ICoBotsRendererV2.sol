// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

struct Attribute {
    string trait_type;
    string value;
}

struct TokenData {
    string image;
    string description;
    string name;
    Attribute[] attributes;
}

interface ICoBotsRendererV2 {
    function tokenURI(uint256 tokenId, uint8 seed)
        external
        view
        returns (string memory);

    function tokenData(uint256 tokenId, uint8 seed)
        external
        view
        returns (TokenData memory);
}
