//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./EnumerableSetUpgradeable.sol";

/// @title ForgeMasterStorage
/// @author Simon Fremaux (@dievardump)
contract ForgeMasterStorage {
    // if creation is locked or not
    bool internal _locked;

    // fee to pay to create a contract
    uint256 internal _fee;

    // how many creations are still free
    uint256 internal _freeCreations;

    // current ERC721 implementation
    address internal _erc721Implementation;

    // current ERC1155 implementation
    // although this won't be used at the start
    address internal _erc1155Implementation;

    // opensea erc721 ProxyRegistry / Proxy contract address
    address internal _openseaERC721ProxyRegistry;

    // opensea erc1155 ProxyRegistry / Proxy contract address
    address internal _openseaERC1155ProxyRegistry;

    // list of all registries created
    EnumerableSetUpgradeable.AddressSet internal _registries;

    // list of all "official" modules
    EnumerableSetUpgradeable.AddressSet internal _modules;

    // slugs used for registries
    mapping(bytes32 => address) internal _slugsToRegistry;
    mapping(address => bytes32) internal _registryToSlug;

    // this is used for the reindexing requests
    mapping(address => uint256) public lastIndexing;

    // Flagging might be used if there  are abuses, and we need a way to "flag" elements
    // in The Graph

    // used to flag a registry
    mapping(address => bool) public flaggedRegistries;

    // used to flag a token in a registry
    mapping(address => mapping(uint256 => bool)) internal _flaggedTokens;

    // gap
    uint256[50] private __gap;
}
