/*

   _____                   _             _____                       _ 
  / ____|                 | |           / ____|                     | |
 | (___  _ __   ___   ___ | | ___   _  | (___   __ _ _   _  __ _  __| |
  \___ \| '_ \ / _ \ / _ \| |/ / | | |  \___ \ / _` | | | |/ _` |/ _` |
  ____) | |_) | (_) | (_) |   <| |_| |  ____) | (_| | |_| | (_| | (_| |
 |_____/| .__/ \___/ \___/|_|\_\\__, | |_____/ \__, |\__,_|\__,_|\__,_|
        | |                      __/ |            | |                  
        |_|                     |___/             |_|                  

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Strings.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Tradable.sol";
import "./ISpookySquad.sol";

contract SpookySquad is ISpookySquad, ERC721Tradable, Ownable {
    using Strings for uint;

    struct MintedAmountData {
        uint16 premintAmount;
        uint16 mainMintAmount;
    }

    mapping(address => MintedAmountData) private mintedAmount;

    uint16 private mainMintTokensAmount = 666;
    // Incremental id of the next minted token
    uint16 private nextTokenId = 1;

    uint64 override public timestamp;
    bool override public visible;

    uint16 override public maxMainMintTokensAmountPerAddress;

    string private baseUri;
    string private stubURI;
    // Link to the metadata of this contracat
    string override public contractURI;
    // The maximum amount of tokens available to mint
    uint16 override public maxTotalSupply;
    uint16 override immutable public premintTokensAmount;
    ERC721 override immutable public dvls;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        string memory _stubURI,
        string memory _contractUri,
        uint64 _timestamp,
        uint16 _maxTotalSupply,
        uint16 _maxMainMintTokensAmountPerAddress,
        address _dvls,
        address _proxyRegistry
    ) ERC721(_name, _symbol) ERC721Tradable(_proxyRegistry) {
        setTimestamp(_timestamp);
        baseUri = _baseUri;
        stubURI = _stubURI;
        contractURI = _contractUri;
        maxTotalSupply = _maxTotalSupply;
        maxMainMintTokensAmountPerAddress = _maxMainMintTokensAmountPerAddress;
        premintTokensAmount = _maxTotalSupply - mainMintTokensAmount;
        dvls = ERC721(_dvls);
    }

    /**
    * @dev Get `baseUri` value after the `timestamp`
    * @return the `baseUri` value or an empty string
    */
    function baseURI() public view override returns (string memory) {
        return visible ? baseUri : "";
    }

    /**
    * @dev Get a `tokenURI` of a token after the `timestamp`
    * @param `_tokenId` an id whose `tokenURI` will be returned
    * @return `tokenURI` string after the `timstamp` or the `stubURI`
    */
    function tokenURI(uint _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "SpookySquad: URI query for nonexistent token");

        // Concatenate the tokenID to the baseURI and show it if the `timestamp` is earlier than `block.timestamp` else show a stub
        return visible ?
            string(abi.encodePacked(baseUri, _tokenId.toString(), ".json")) : stubURI;
    }

    function isMainMintNow() external view override returns (bool) {
        return block.timestamp > timestamp;
    }

    function availableAmountToMint(address _owner) public view override returns (uint16) {
        MintedAmountData memory _minted = mintedAmount[_owner];
        uint16 _mintedAmount;
        uint16 _availableAmount;

        if (block.timestamp > timestamp) {
            _mintedAmount = _minted.mainMintAmount;
            _availableAmount = maxMainMintTokensAmountPerAddress;
        } else {
            _mintedAmount = _minted.premintAmount;
            _availableAmount = uint16(dvls.balanceOf(_owner));
        }
        return _availableAmount > _mintedAmount ? _availableAmount - _mintedAmount : 0;
    }

    function getMintedAmount(address _owner) external view override returns (uint16 premintAmount, uint16 mainMintAmount) {
        MintedAmountData memory _mintedAmount = mintedAmount[_owner];
        premintAmount = _mintedAmount.premintAmount;
        mainMintAmount = _mintedAmount.mainMintAmount;
    }

    /**
    * @dev Get array of tokenNumbers for the _owner
    * @param _owner address to get tokens by
    * @return _tokensIDs array
    */
    function getTokensOfOwner(address _owner)
        external
        view
        override
        returns (uint16[] memory _tokensIDs)
    {
        uint16 _tokenCount = uint16(balanceOf(_owner));
        if (_tokenCount == 0) {
            return new uint16[](0);
        }

        _tokensIDs = new uint16[](_tokenCount);
        for (uint16 _index; _index < _tokenCount; _index++) {
            _tokensIDs[_index] = uint16(tokenOfOwnerByIndex(_owner, _index));
        }
    }

    function mintTokens(address _to, uint16 _amount)
        external
        override
        returns (uint16 _lastMintedId)
    {
        bool _isMainMint = block.timestamp > timestamp;
        _lastMintedId = uint16(totalSupply()) + _amount;
        require(
            (_isMainMint ? maxTotalSupply : premintTokensAmount) >= _lastMintedId,
            "SpookySquad: Cannot mint more tokens than a max amount"
        );

        require(
            owner() == msg.sender || availableAmountToMint(msg.sender) >= _amount,
            "SpookySquad: cannot mint more tokens than the availableAmountToMint"
        );
        if (_isMainMint) {
            mintedAmount[msg.sender].mainMintAmount += _amount;
        } else {
            mintedAmount[msg.sender].premintAmount += _amount;
        }

        for (uint16 i = nextTokenId; i <= _lastMintedId; i++) {
            _mint(_to, i);
        }
        nextTokenId = _lastMintedId + 1;
    }

    function mintBatch(address[] memory _to, uint16[] memory _amounts)
        external
        override
        onlyOwner
        returns (uint16 _lastMintedId)
    {
        require(_to.length == _amounts.length, "SpookySquad: to and amounts length mismatch");

        uint16 _supplyBeforeMint = uint16(totalSupply());
        uint16 _nextTokenId = nextTokenId;
        for (uint16 i; i < _to.length; i++) {
            for (uint16 j; j < _amounts[i]; j++) {
                _mint(_to[i], _nextTokenId + j);
            }
            _nextTokenId += _amounts[i];
        }
        nextTokenId = _nextTokenId;

        _lastMintedId = uint16(totalSupply());
        bool _isMainMint = block.timestamp > timestamp;
        require(
            (_isMainMint ? maxTotalSupply : premintTokensAmount) >= _lastMintedId,
            "SpookySquad: Cannot mint more tokens than a max amount"
        );

        if (_isMainMint) {
            mintedAmount[msg.sender].mainMintAmount += _lastMintedId - _supplyBeforeMint;
        } else {
            mintedAmount[msg.sender].premintAmount += _lastMintedId - _supplyBeforeMint;
        }
    }

    function setVisibility(bool _visible) external override onlyOwner {
        visible = _visible;
    }

    function setBaseURI(string memory _baseUri) external override onlyOwner {
        baseUri = _baseUri;
    }

    function setStubURI(string memory _stubUri) external override onlyOwner {
        stubURI = _stubUri;
    }

    function setContractURI(string memory _contractURI) external override onlyOwner {
        contractURI = _contractURI;
    }

    function setTimestamp(uint64 _newTimestamp) public override onlyOwner {
        uint64 _timestamp = timestamp;
        require(block.timestamp < _timestamp || _timestamp == 0, "SpookySquad: Cannot change the timestamp after the time has passed");
        require(block.timestamp < _newTimestamp, "SpookySquad: Cannot set the timestamp earlier than the current time");

        timestamp = _newTimestamp;
    }

    function setMaxMainMintTokensAmountPerAddress(uint16 _maxMainMintTokensAmountPerAddress) external override onlyOwner {
        maxMainMintTokensAmountPerAddress = _maxMainMintTokensAmountPerAddress;
    }
}
