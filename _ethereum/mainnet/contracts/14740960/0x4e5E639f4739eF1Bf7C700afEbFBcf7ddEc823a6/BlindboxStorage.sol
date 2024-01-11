// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./Counters.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IRand.sol";
import "./INFT.sol";
import "./IDEX.sol";
import "./LPInterface.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * @title DexStorage
 * @dev Defining dex storage for the proxy contract.
 */
///////////////////////////////////////////////////////////////////////////////////////////////////

contract BlindboxStorage {
 using Counters for Counters.Counter;
    using SafeMath for uint256;

    address a;
    address b;
    address c;

    IRand vrf;
    IERC20 ALIA;
    IERC20 ETH;
    IERC20 USD;
    IERC20 MATIC;
    INFT nft;
    IDEX dex;
    address platform;
    IERC20 internal token;
    
    Counters.Counter internal _boxId;

 Counters.Counter public generativeSeriesId;

    struct Attribute {
        string name;
        string uri;
        uint256 rarity;
    }

    struct GenerativeBox {
        string name;
        string boxURI;
        uint256 series; // to track start end Time
        uint256 countNFTs;
        // uint256[] attributes;
        // uint256 attributesRarity;
        bool isOpened;
    }

    struct GenSeries {
        string name;
        string seriesURI;
        string boxName;
        string boxURI;
        uint256 startTime;
        uint256 endTime;
        uint256 maxBoxes;
        uint256 perBoxNftMint;
        uint256 price; // in ALIA
        Counters.Counter boxId; // to track series's boxId (upto minted so far)
        Counters.Counter attrType; // attribute Type IDs
        Counters.Counter attrId; // attribute's ID
        // attributeType => attributeId => Attribute
        mapping ( uint256 => mapping( uint256 => Attribute)) attributes;
        // attributes combination hash => flag
        mapping ( bytes32 => bool) blackList;
    }

    struct NFT {
        // attrType => attrId
        mapping (uint256 => uint256) attribute;
    }

    // seriesId => Series
    mapping ( uint256 => GenSeries) public genSeries;
   mapping ( uint256 => uint256) public genseriesRoyalty;
    mapping ( uint256 => uint256[]) _allowedCurrenciesGen;
    mapping ( uint256 => address) public bankAddressGen;
    mapping ( uint256 => uint256) public baseCurrencyGen;
    mapping (uint256=>string) public genCollection;
    // boxId => attributeType => attributeId => Attribute
    // mapping( uint256 => mapping ( uint256 => mapping( uint256 => Attribute))) public attributes;
    // boxId => Box
    mapping ( uint256 => GenerativeBox) public boxesGen;
    // attributes combination => flag
    // mapping ( bytes => bool) public blackList;
    // boxId => boxOpener => array of combinations to be minted
    // mapping ( uint256 => mapping ( address => bytes[] )) public nftToMint;
    // boxId => owner
    mapping ( uint256 => address ) public genBoxOwner;
    // boxId => NFT index => attrType => attribute
    mapping (uint256 => mapping( uint256 => mapping (uint256 => uint256))) public nftsToMint;
  

    Counters.Counter public nonGenerativeSeriesId;
    // mapping(address => Counters.Counter) public nonGenerativeSeriesIdByAddress;
    struct URI {
        string name;
        string uri;
        uint256 rarity;
        uint256 copies;
    }

    struct NonGenerativeBox {
        string name;
        string boxURI;
        uint256 series; // to track start end Time
        uint256 countNFTs;
        // uint256[] attributes;
        // uint256 attributesRarity;
        bool isOpened;
    }

    struct NonGenSeries {
        string collection;
        string name;
        string seriesURI;
        string boxName;
        string boxURI;
        uint256 startTime;
        uint256 endTime;
        uint256 maxBoxes;
        uint256 perBoxNftMint;
        uint256 price; 
        Counters.Counter boxId; // to track series's boxId (upto minted so far)
        Counters.Counter attrId; 
        // uriId => URI 
        mapping ( uint256 => URI) uris;
    }

    struct IDs {
        Counters.Counter attrType;
        Counters.Counter attrId;
    }

    struct CopiesData{
        
        uint256 total;
        mapping(uint256 => uint256) nftCopies;
    }
    mapping (uint256 => CopiesData) public _CopiesData;
    
    // seriesId => NonGenSeries
    mapping ( uint256 => NonGenSeries) public nonGenSeries;

   mapping ( uint256 => uint256[]) _allowedCurrencies;
   mapping ( uint256 => address) public bankAddress;
   mapping ( uint256 => uint256) public nonGenseriesRoyalty;
   mapping ( uint256 => uint256) public baseCurrency;
    // boxId => IDs
    // mapping (uint256 => IDs) boxIds;
    // boxId => attributeType => attributeId => Attribute
    // mapping( uint256 => mapping ( uint256 => mapping( uint256 => Attribute))) public attributes;
    // boxId => Box
    mapping ( uint256 => NonGenerativeBox) public boxesNonGen;
    // attributes combination => flag
    // mapping ( bytes => bool) public blackList;
    // boxId => boxOpener => array of combinations to be minted
    // mapping ( uint256 => mapping ( address => bytes[] )) public nftToMint;
    // boxId => owner
    mapping ( uint256 => address ) public nonGenBoxOwner;
    // boxId => NFT index => attrType => attribute
    // mapping (uint256 => mapping( uint256 => mapping (uint256 => uint256))) public nfts;
    mapping(string => mapping(bool => uint256[])) seriesIdsByCollection;
    uint256 deployTime;
     LPInterface LPAlia;
    LPInterface LPWETH;
    LPInterface LPMATIC;
     mapping(bytes32 => mapping(uint256 => bool)) _whitelisted;
    mapping(uint256 => bool) _isWhiteListed;
    mapping(address => mapping (uint256=>uint256)) _boxesCrytpoUser;
    mapping( string => mapping (uint256=>uint256)) _boxesNoncryptoUser;
    mapping (uint256 => uint256) _perBoxUserLimit;
    mapping (uint256 => bool) _isCryptoAllowed;
    mapping (uint256 => uint256) _registrationFee;
    mapping (address => mapping(uint256 => bool)) crypoWhiteList;
    mapping (string=> mapping(uint256 => bool)) nonCryptoWhiteList;
}