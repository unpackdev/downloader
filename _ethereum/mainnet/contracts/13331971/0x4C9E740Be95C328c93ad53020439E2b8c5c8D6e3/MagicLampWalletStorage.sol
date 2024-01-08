// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MagicLampWalletStorage {
    struct Token {
        uint8 tokenType; // TOKEN_TYPE
        address tokenAddress;
    }

    // Token types
    uint8 internal constant _TOKEN_TYPE_ERC20 = 1;
    uint8 internal constant _TOKEN_TYPE_ERC721 = 2;
    uint8 internal constant _TOKEN_TYPE_ERC1155 = 3;
  
    // Mapping from Host -> ID -> Token(ERC721 or ERC1155) -> IDs
    mapping(address => mapping(uint256 => mapping(address => uint256[]))) internal _erc721ERC1155TokenIds;

    // Mapping from Host -> ID -> Token(ERC20) -> Balance
    mapping(address => mapping(uint256 => mapping(address => uint256))) internal _erc20TokenBalances;

    // Mapping from Host -> ID -> Token(ERC1155) -> Token ID -> Balance
    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => uint256)))) internal _erc1155TokenBalances;

    // Mapping from Host -> ID -> Token(ETH) -> Balance
    mapping(address => mapping(uint256 => uint256)) internal _ethBalances;

    address public magicLampSwap;

    // List of ERC721 tokens which wallet features get supported
    address[] public walletFeatureHosts;

    // Mapping from Host -> bool
    mapping(address => bool) public walletFeatureHosted;

    // Mapping from Host -> ID -> Tokens
    mapping(address => mapping(uint256 => Token[])) internal _tokens;

    // Mapping from Host -> ID -> Locked Time
    mapping(address => mapping(uint256 => uint256)) internal _lockedTimestamps;
}
