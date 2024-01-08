/*


 ██▓     ██▓ ██▓       ▓█████▄ ▓█████ ██▒   █▓ ██▓ ██▓      ██████ 
▓██▒    ▓██▒▓██▒       ▒██▀ ██▌▓█   ▀▓██░   █▒▓██▒▓██▒    ▒██    ▒ 
▒██░    ▒██▒▒██░       ░██   █▌▒███   ▓██  █▒░▒██▒▒██░    ░ ▓██▄   
▒██░    ░██░▒██░       ░▓█▄   ▌▒▓█  ▄  ▒██ █░░░██░▒██░      ▒   ██▒
░██████▒░██░░██████▒   ░▒████▓ ░▒████▒  ▒▀█░  ░██░░██████▒▒██████▒▒
░ ▒░▓  ░░▓  ░ ▒░▓  ░    ▒▒▓  ▒ ░░ ▒░ ░  ░ ▐░  ░▓  ░ ▒░▓  ░▒ ▒▓▒ ▒ ░
░ ░ ▒  ░ ▒ ░░ ░ ▒  ░    ░ ▒  ▒  ░ ░  ░  ░ ░░   ▒ ░░ ░ ▒  ░░ ░▒  ░ ░
  ░ ░    ▒ ░  ░ ░       ░ ░  ░    ░       ░░   ▒ ░  ░ ░   ░  ░  ░  
    ░  ░ ░      ░  ░      ░       ░  ░     ░   ░      ░  ░      ░  
                        ░                 ░                        

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Strings.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Tradable.sol";
import "./Withdrawable.sol";
import "./ILilDevils.sol";

contract LilDevils is ILilDevils, ERC721Tradable, Ownable, Withdrawable {
    using Strings for uint;

    enum Stage {
        Presale,
        BeforeSale,
        Sale
    }
    Stage public stage;

    // Incremental id of the next minted token
    uint16 private nextTokenId = 1;

    // A tokenURI becomes visible after this timestamp
    uint64 override public timestamp;

    // Price for the first `presaleAmount` tokens
    uint16 override public constant presaleAmount = 665;
    uint16 override public maxBuyTokensAmountPerTime;
    // Price to call `buyToken` and `buyTokens` before `presaleAmount` value is reached
    uint override public presalePrice;
    // Price to call `buyToken` and `buyTokens` after `timestampStartSale`
    uint override public salePrice;

    string private baseUri;
    string private stubURI;
    // Link to the metadata of this contracat
    string override public contractURI;
    // The maximum amount of tokens available to mint
    uint16 override public maxTotalSupply;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        string memory _stubURI,
        string memory _contractUri,
        uint64 _timestamp,
        uint16 _maxTotalSupply,
        uint16 _maxBuyTokensAmountPerTime,
        uint _presalePrice,
        uint _salePrice,
        address _proxyRegistry
    ) ERC721(_name, _symbol) ERC721Tradable(_proxyRegistry) {
        setTimestamp(_timestamp);
        baseUri = _baseUri;
        stubURI = _stubURI;
        contractURI = _contractUri;
        maxTotalSupply = _maxTotalSupply;
        maxBuyTokensAmountPerTime = _maxBuyTokensAmountPerTime;
        presalePrice = _presalePrice;
        salePrice = _salePrice;
    }

    /**
    * @dev Get `baseUri` value after the `timestamp`
    * @return the `baseUri` value or an empty string
    */
    function baseURI() public view override returns (string memory) {
        return timestamp <= block.timestamp ? baseUri : "";
    }

    /**
    * @dev Get a `tokenURI` of a token after the `timestamp`
    * @param `_tokenId` an id whose `tokenURI` will be returned
    * @return `tokenURI` string after the `timstamp` or the `stubURI`
    */
    function tokenURI(uint _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "LilDevils: URI query for nonexistent token");

        // Concatenate the tokenID to the baseURI and show it if the `timestamp` is earlier than `block.timestamp` else show a stub
        return timestamp <= block.timestamp ?
            string(abi.encodePacked(baseUri, _tokenId.toString(), ".json")) : stubURI;
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

    function buyToken(address _to)
        external
        payable
        override
        returns (uint16)
    {
        _checkTokensBeforeBuy(1);

        return _mintToken(_to);
    }

    function buyTokens(address _to, uint16 _amount)
        external
        payable
        override
        returns (uint16)
    {
        _checkTokensBeforeBuy(_amount);

        return _mintTokens(_to, _amount);
    }

    function mintToken(address _to)
        external
        override
        onlyOwner
        returns (uint16)
    {
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

    function startSale() external override onlyOwner {
        require(stage == Stage.BeforeSale, "LilDevils: Cannot start sale not before awaiting for it");
        stage = Stage.Sale;
    }

    function setSalePrice(uint _salePrice) external override onlyOwner {
        salePrice = _salePrice;
    }

    function setPresalePrice(uint _presalePrice) external override onlyOwner {
        presalePrice = _presalePrice;
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

    function increaseMaxTotalSupply(uint16 _maxTotalSupply) external override onlyOwner {
        require(_maxTotalSupply > maxTotalSupply, "LilDevils: new maxTotalSupply has to be greater than current");
        maxTotalSupply = _maxTotalSupply;
    }

    function setTimestamp(uint64 _newTimestamp) public override onlyOwner {
        uint64 _timestamp = timestamp;
        require(block.timestamp < _timestamp || _timestamp == 0, "LilDevils: Cannot change the timestamp after the time has passed");
        require(block.timestamp < _newTimestamp, "LilDevils: Cannot set the timestamp earlier than the current time");

        timestamp = _newTimestamp;
    }

    function setMaxBuyTokensAmountPerTime(uint16 _maxBuyTokensAmountPerTime) external override onlyOwner {
        maxBuyTokensAmountPerTime = _maxBuyTokensAmountPerTime;
    }

    function _checkTokensBeforeBuy(uint16 _amount) private {
        Stage _stage = stage;

        require(_stage != Stage.BeforeSale, "LilDevils: Cannot buy tokens during awaiting start of the sale");
        require(_amount <= maxBuyTokensAmountPerTime, "LilDevils: Cannot buy tokens more than maxBuyTokensAmountPerTime");
        require(
            _stage == Stage.Sale || totalSupply() + _amount <= presaleAmount,
            "LilDevils: Cannot buy more than presaleAmount tokens durng the presale period"
        );
        require(
            msg.value >= _amount * (_stage == Stage.Sale ? salePrice : presalePrice),
            "LilDevils: Not enough ETH to buy this NFT"
        );
    }

    function _mintToken(address _to)
        private
        returns (uint16 _tokenId)
    {
        _tokenId = nextTokenId;
        require(maxTotalSupply >= _tokenId, "LilDevils: Cannot mint new token, maximum amount created");

        _mint(_to, _tokenId);
        nextTokenId++;

        if (stage == Stage.Presale && _tokenId >= presaleAmount) {
            stage = Stage.BeforeSale;
        }
    }

    function _mintTokens(address _to, uint16 _amount)
        private
        returns (uint16 _lastMintedId)
    {
        _lastMintedId = uint16(totalSupply()) + _amount;
        require(maxTotalSupply >= _lastMintedId, "LilDevils: Cannot mint more tokens than the maxTotalSupply");

        for (uint16 _i = nextTokenId; _i <= _lastMintedId; _i++) {
            _mint(_to, _i);
        }
        nextTokenId = _lastMintedId + 1;

        if (stage == Stage.Presale && _lastMintedId >= presaleAmount) {
            stage = Stage.BeforeSale;
        }
    }
}
