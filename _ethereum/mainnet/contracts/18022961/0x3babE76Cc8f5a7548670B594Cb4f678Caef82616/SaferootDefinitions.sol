// SaferootDefinitions.sol
pragma solidity ^0.8.20;

uint256 constant TokenType_ERC20 = 0;
uint256 constant TokenType_ERC721 = 1;
uint256 constant TokenType_ERC1155 = 2;

struct SafeguardEntry {
    uint8 tokenType;
    address contractAddress;
    uint256 tokenId;
}
