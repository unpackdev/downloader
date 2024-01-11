// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./UInt256Set.sol";
import "./AddressSet.sol";

import "./IMarketplace.sol";
import "./ITokenMinter.sol";
import "./ITokenSale.sol";

import "./LibDiamond.sol";

struct FractionalizedTokenData {
    string symbol;
    string name;
    address tokenAddress;
    uint256 tokenId;
    address fractionalizedToken;
    uint256 totalFractions;
}

struct MarketplaceStorage {
    uint256 itemsSold;
    uint256 itemIds;
    mapping(uint256 => IMarketplace.MarketItem) idToMarketItem;
    mapping(uint256 => bool) idToListed;
}

struct TokenMinterStorage {
    address token;
    mapping(uint256 => uint256) tokenAuditHashes;
    mapping(uint256 => string) tokenGiaNumbers;
}

struct ERC1155Storage {
    mapping(uint256 => mapping(address => uint256)) _balances;
    mapping(uint256 => uint256) _totalSupply;
    mapping(address => mapping(address => bool)) _operatorApprovals;

    // mono-uri from erc1155
    string _uri;
    string _uriBase;
    string _symbol;
    string _name;
    address _approvalProxy;
}

struct FractionalizerStorage {
    address fTokenTemplate;
    mapping(address => FractionalizedTokenData) fractionalizedTokens;
    address[] tokenList;
    address[] fractionalizedTokensList;
}

struct MarketUtilsStorage {
    mapping(uint256 => bool) validTokens;
}

struct TokenSaleStorage {
    mapping(address => ITokenSale.TokenSaleEntry) tokenSaleEntries;
}

struct AppStorage {
    // gem pools data
    MarketplaceStorage marketplaceStorage;
    // gem pools data
    TokenMinterStorage tokenMinterStorage;
    // the erc1155 token
    ERC1155Storage erc1155Storage;
    // fractionalizer storage
    FractionalizerStorage fractionalizerStorage;
    // market utils storage
    MarketUtilsStorage marketUtilsStorage;
    // token sale storage
    TokenSaleStorage tokenSaleStorage;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;
    modifier onlyOwner() {
        require(LibDiamond.contractOwner() == msg.sender || address(this) == msg.sender, "ERC1155: only the contract owner can call this function");
        _;
    }
}
