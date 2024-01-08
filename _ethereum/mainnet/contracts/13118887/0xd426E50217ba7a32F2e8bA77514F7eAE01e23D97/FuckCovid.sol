// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./IWyvernProxyRegistry.sol";
import "./IFuckCovid.sol";

contract FuckCovid is IFuckCovid, ERC721Enumerable, Ownable {
    using Strings for uint;

    // Incremental id of the next minted token
    uint16 private nextTokenId = 1;

    // TokenURI becomes visible after this timestamp
    uint64 override public timestamp;

    uint16 override public maxTotalSupply;

    string private baseUri;
    string private stubURI;
    string override public contractURI;

    address private proxyRegistry;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        string memory _stubURI,
        string memory _contractURI,
        uint64 _timestamp,
        uint16 _maxTotalSupply,
        address _proxyRegistry
    ) ERC721(_name, _symbol) {
        setTimestamp(_timestamp);
        baseUri = _baseUri;
        stubURI = _stubURI;
        contractURI = _contractURI;
        maxTotalSupply = _maxTotalSupply;
        proxyRegistry = _proxyRegistry;
    }

    /**
    * @dev Get `baseUri` value after the `timestamp`
    * @return the `baseUri` value or an empty string
    */
    function baseURI() public view override returns (string memory) {
        return 
            timestamp <= block.timestamp
                ? baseUri
                : "";
    }

    /**
    * @dev Get a `tokenURI` of a token after the `timestamp`
    * @param `_tokenId` an id whose `tokenURI` will be returned
    * @return `tokenURI` string after the `timstamp` or the `stubURI`
    */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "FuckCovid: URI query for nonexistent token");
        return
            timestamp <= block.timestamp
                ? string(abi.encodePacked(baseUri, _tokenId.toString(), ".json"))
                : stubURI;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address _owner, address _operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        if (address(IWyvernProxyRegistry(proxyRegistry).proxies(_owner)) == _operator) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
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

    function setBaseURI(string memory _baseUri) external override onlyOwner {
        baseUri = _baseUri;
    }

    function setStubURI(string memory _stubURI) external override onlyOwner {
        stubURI = _stubURI;
    }

    function setContractURI(string memory _contractURI) external override onlyOwner {
        contractURI = _contractURI;
    }

    function setTimestamp(uint64 _newTimestamp) public override onlyOwner {
        uint64 _timestamp = timestamp;
        require(
            block.timestamp < _timestamp || _timestamp == 0,
            "FuckCovid: Cannot change the timestamp after the time has passed"
        );
        require(
            block.timestamp < _newTimestamp,
            "FuckCovid: Cannot set the timestamp earlier than the current time"
        );
        timestamp = _newTimestamp;
    }


    function mintToken(address _to) external override onlyOwner returns (uint16) {
        return _mintToken(_to);
    }

    function mintTokens(address _to, uint16 _amount)
        external
        override
        onlyOwner
        returns (uint16)
    {
        return _mintTokens(_to, _amount);
    }

    function _mintToken(address _to) internal returns (uint16 _tokenId) {
        _tokenId = nextTokenId;
        require(
            maxTotalSupply >= _tokenId,
            "FuckCovid: Cannot mint new token, maximum amount created"
        );

        _mint(_to, _tokenId);
        nextTokenId++;
    }

    function _mintTokens(address _to, uint16 _amount) internal returns (uint16 _lastMintedId) {
        _lastMintedId = uint16(totalSupply()) + _amount;
        require(
            maxTotalSupply >= _lastMintedId,
            "FuckCovid: Cannot mint more tokens than the maxTotalSupply"
        );

        for (uint16 _i = nextTokenId; _i <= _lastMintedId; _i++) {
            _mint(_to, _i);
        }
        nextTokenId = _lastMintedId + 1;
    }
}
