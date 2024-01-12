// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

// come see us.... >> www.thepariah.xyz

//  ..________............____............._.......__.......____..............._...........__.
//  ./_..__/./_..___...../.__.\____.______(_)___._/./_...../.__.\_________....(_)__.._____/./_
//  ../././.__.\/._.\..././_/./.__.`/.___/./.__.`/.__.\..././_/./.___/.__.\.././._.\/.___/.__/
//  ././././././..__/../.____/./_/././../././_/././././../.____/./.././_/./././..__/./__/./_..
//  /_/./_/./_/\___/../_/....\__,_/_/../_/\__,_/_/./_/../_/.../_/...\____/_/./\___/\___/\__/..
//  ..................................................................../___/.................

// Project Notes:

// Concept art with unique and darker styles inspired by alternative comics or the 80s and 90s
// Hand coloured and distressed to emulate real pulp
// Blend of bespoke, procedural, and programmatic art forms
// Room for future expansion, limited collections, 1/1s, or more

// Supply 2,222
// Original Mint Price 0.03 ETH

// Developed by theblockchain.eth -> Twitter: @tbc_eth
//  .._..._.........._....._............_........_..........._............._..._.....
//  .|.|.|.|........|.|...|.|..........|.|......|.|.........(_)...........|.|.|.|....
//  .|.|_|.|__...___|.|__.|.|.___...___|.|._____|.|__...__._._._.__....___|.|_|.|__..
//  .|.__|.'_.\./._.\.'_.\|.|/._.\./.__|.|/./.__|.'_.\./._`.|.|.'_.\../._.\.__|.'_.\.
//  .|.|_|.|.|.|..__/.|_).|.|.(_).|.(__|...<.(__|.|.|.|.(_|.|.|.|.|.||..__/.|_|.|.|.|
//  ..\__|_|.|_|\___|_.__/|_|\___/.\___|_|\_\___|_|.|_|\__,_|_|_|.|_(_)___|\__|_|.|_|
//  .................................................................................
//  .................................................................................

// Technical Notes:

// Novel approach to transformative, on-going, project delivery
// Retargetable metadata
// Limitless expansion and value without diluting supply
// Parent Child relationship to new sub-collections/editions; extra subset ownerships stays with the token for life
// 721A Batch Minting (thanks Azuki developer team, and community contributors, for this open-sourced project)


contract thePariah is Ownable, ERC721A {
    using Counters for Counters.Counter;

    Counters.Counter private _artSeriesId;
    Counters.Counter private _tokenId;

    struct artSeries { // Struct
        bool active;
        string metadataLocation;
        string artSeriesName;
        uint256 collectionSize;
        uint256 unlockPrice;
        bool locked;
    }

    constructor(uint256 _mintPriceMinusOne, uint256 _mintBatchMaxPlusOne, uint256 _supplyPlusOne) ERC721A("The Pariah", "PARIAH") {
        // 29999999999999999, 6, 2222
        originalTokenMintPriceInWeiMinusOne = _mintPriceMinusOne;
        originalTokenBatchMintMaxPlusOne = _mintBatchMaxPlusOne;
        maximumSupplyPlusOne = _supplyPlusOne;

        // dev mint lazy style
        _mint(msg.sender, 5);
        _mint(msg.sender, 5);
        _mint(msg.sender, 5);
        _mint(msg.sender, 5);
    } 

    bool public mintingActive;
    uint256 public originalTokenMintPriceInWeiMinusOne;
    uint256 public originalTokenBatchMintMaxPlusOne;
    uint256 public maximumSupplyPlusOne;

    mapping(uint256 => artSeries) public artSeriesData;
    mapping(uint256 => uint256) public seriesMintCounts;
    mapping(uint256 => mapping(uint256 => bool)) public tokensUnlockedSeries;
    mapping(uint256 => uint256) public tokensActiveSeries;
    mapping(uint256 => mapping(uint256 => uint256)) public tokenToSeriesToSeriesId;    

    function a_addArtSeries(bool _isActive, string calldata _metadataLocation, string calldata _artSeriesName, uint256 _collectionSize, uint256 _unlockPrice) public onlyOwner {
        artSeriesData[_artSeriesId.current()] = artSeries(_isActive, _metadataLocation, _artSeriesName, _collectionSize, _unlockPrice, false);
        _artSeriesId.increment();
    }

    function a_amendArtSeries(uint256 artSeriedId, bool _isActive, string calldata _metadataLocation, string calldata _artSeriesName, uint256 _collectionSize, uint256 _unlockPrice) public onlyOwner {
        require(!artSeriesData[artSeriedId].locked, "series locked");
        artSeriesData[artSeriedId] = artSeries(_isActive, _metadataLocation, _artSeriesName, _collectionSize, _unlockPrice, false);
    }

    function a_lockArtSeries(uint256 artSeriedId) public onlyOwner {
        artSeries memory updatedArtSeries = artSeriesData[artSeriedId];
        updatedArtSeries.locked = true;
        artSeriesData[artSeriedId] = updatedArtSeries;
    }

    function a_unlockSeriesForToken(uint256 tokenId, uint256 artSeriesId, bool setActive) public payable {
        require(msg.sender == ownerOf(tokenId), "Not authorised");

        uint256 nextSubIdForArtSeries = seriesMintCounts[artSeriesId];
        require(msg.value > artSeriesData[artSeriesId].unlockPrice - 1, "Insufficient Payment");
        require(seriesMintCounts[artSeriesId] < artSeriesData[artSeriesId].collectionSize, "Insufficient Supply");
        require(!tokensUnlockedSeries[artSeriesId][tokenId], "Already Active");

        tokensUnlockedSeries[tokenId][artSeriesId] = true;
        tokenToSeriesToSeriesId[tokenId][artSeriesId] = nextSubIdForArtSeries;

        seriesMintCounts[artSeriesId] = nextSubIdForArtSeries + 1;

        if (setActive) {
            tokensActiveSeries[tokenId] = artSeriesId;
        }
    }

    function a_setActiveSeriesForToken(uint256 tokenId, uint256 artSeriesId) public {
        require(msg.sender == ownerOf(tokenId), "Not authorised");

        if (artSeriesId == 0) {
            tokensActiveSeries[tokenId] = artSeriesId;
        } else {
            require(tokensUnlockedSeries[tokenId][artSeriesId], "Not unlocked");
            tokensActiveSeries[tokenId] = artSeriesId;
        }

    }

    function a_flipMintingState() public onlyOwner {
        mintingActive = !mintingActive;
    }

    function a_mintBatch(uint256 _quantity) public payable {
        require(mintingActive, "Minting Closed");
        require(msg.value > originalTokenMintPriceInWeiMinusOne * _quantity, "Insufficent Payment");
        require((_quantity + totalSupply()) < maximumSupplyPlusOne, "Insufficient Supply");
        if (_quantity < originalTokenBatchMintMaxPlusOne) {
            _mint(msg.sender, _quantity);
        }
    }

    function a_withdrawContractFunds() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        uint256 _activeSeries = tokensActiveSeries[tokenId];

        if (_activeSeries == 0) {
            string memory meta = artSeriesData[_activeSeries].metadataLocation;
            return bytes(meta).length != 0 ? string(abi.encodePacked(meta, _toString(tokenId))) : '';
        } else {
            string memory meta = artSeriesData[_activeSeries].metadataLocation;
            return bytes(meta).length != 0 ? string(abi.encodePacked(meta, _toString(tokenToSeriesToSeriesId[tokenId][_activeSeries]))) : '';
        }

    }


}