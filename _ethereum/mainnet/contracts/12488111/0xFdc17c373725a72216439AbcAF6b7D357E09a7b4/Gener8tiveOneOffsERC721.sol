//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ERC721URIStorage.sol";
import "./ERC721Holder.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract Gener8tiveOneOffsERC721 is ERC721URIStorage, ERC721Holder, Ownable
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    // =======================================================
    // EVENTS
    // =======================================================
    event TokenMinted(uint256 tokenIndex);
    event TokenUriUpdated(uint256 tokenId, string uri);
    event TokenPriceChanged(uint256 tokenId, uint256 price);
    event TokenPurchased(uint256 tokenId, uint256 price, address newOwner);

    // =======================================================
    // STATE
    // =======================================================
    Counters.Counter public tokenId;
    mapping(uint256 => TokenData) public tokenData;
    
    bool purchasingEnabled = true;

    // =======================================================
    // STRUCTS & ENUMS
    // =======================================================
    struct TokenData {
        uint256 price;
        string name;
        uint128 width;
        uint128 height;
        string imgType;
    }

    // =======================================================
    // CONSTRUCTOR
    // =======================================================
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {

    }

    // =======================================================
    // ADMIN
    // =======================================================
    function withdrawFunds(address payable recipient, uint256 amount)
        public
        onlyOwner
    {
        recipient.transfer(amount);
    }

    function applyHandbrake()
        public
        onlyOwner
    {
        purchasingEnabled = false;
    }

    function releaseHandbrake()
        public
        onlyOwner
    {
        purchasingEnabled = true;
    }

    function updateTokenURI(uint256 _tokenId, string memory _newTokenURI)
        public
        onlyOwner
    {
        super._setTokenURI(_tokenId,  _newTokenURI);
        emit TokenUriUpdated(_tokenId, _newTokenURI);
    }

    function changeTokenPrice(uint256 _tokenId, uint256 _newPrice)
        public
        onlyOwner
    {
        tokenData[_tokenId].price = _newPrice;
        emit TokenPriceChanged(_tokenId, _newPrice);
    }

    function mint(string memory _tokenUri,
        uint256 _price,
        string memory _name,
        uint128 _width,
        uint128 _height,
        string memory _imgType
    )
        external
        onlyOwner
    {
        super._safeMint(msg.sender, tokenId.current());
        super._setTokenURI(tokenId.current(), _tokenUri);
        
        tokenData[tokenId.current()] = TokenData({
            price: _price,
            name: _name,
            width: _width,
            height: _height,
            imgType: _imgType
        });

        tokenId.increment();

        emit TokenMinted(tokenId.current() - 1);
    }

    // =======================================================
    // PUBLIC API
    // =======================================================
    function getTokenData(uint256 _tokenId)
        public
        view
        returns(TokenData memory data,
            string memory tokenMetadataUri,
            address tokenOwner,
            bool availableForPurchase)
    {
        // check if the token exists
        require(_exists(_tokenId), "Requested token does not exist yet");

        data = tokenData[_tokenId];

        tokenMetadataUri = tokenURI(_tokenId);
        tokenOwner = ownerOf(_tokenId);
        availableForPurchase = ownerOf(_tokenId) == owner() ? true : false;
    }

    // allow direct purchasing of token; tokens can only be purchased from owner
    function purchaseToken(uint256 _tokenId)
        public
        payable
    {
        // check purchasing handbrake
        require(purchasingEnabled, "Purchasing is currently disabled");

        // ensure the token exists
        require(_exists(_tokenId), "Requested token does not exist yet");

        // ensure token is owned by the owner
        require(ownerOf(_tokenId) == owner(), "Token has already been sold");

        // ensure sufficient funds were sent
        require(msg.value >= tokenData[_tokenId].price, "Insufficient ETH sent");

        _transfer(owner(), msg.sender, _tokenId);

        emit TokenPurchased(_tokenId, tokenData[_tokenId].price, msg.sender);
    }
}