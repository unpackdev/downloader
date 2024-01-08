// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./ERC721Enumerable.sol";
import "./IHandler.sol";

contract ERC721Base is ERC721Enumerable, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bool maxTotalSet;
    uint256 public price;
    mapping(address => uint256) public discounts;
    uint256 public maxMint;
    uint256 public maxTotal;

    bool public paused = true;
    IHandler public handler;
    bool public handlerLocked;
    mapping (uint256 => uint256) public seeds;

    constructor(string memory _desc, string memory _token, uint256 _price, uint256 _maxTotal, uint256 _maxMint) ERC721(_desc, _token) {
        price = _price;
        maxMint = _maxMint;
        maxTotal = _maxTotal;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        uint256 seed = seeds[tokenId];
        if (seed == 0) return "";
        return handler.tokenURI(tokenId, seed);
    }

    function imageURI(uint256 tokenId) public view returns (string memory) {
        uint256 seed = seeds[tokenId];
        if (seed == 0) return "";
        return handler.imageURI(tokenId, seed);
    }

    function htmlURI(uint256 tokenId) public view returns (string memory) {
        uint256 seed = seeds[tokenId];
        if (seed == 0) return "";
        return handler.htmlURI(tokenId, seed);
    }

    function mint(uint256 amount) payable external {
        _mint(amount, price);
    }

    function mintDiscount(uint256 amount, address erc721, uint256 tokenId) payable external {
        uint256 discount = discounts[erc721];
        require(discount > 0, '!discount');
        require(_owns(erc721, tokenId, msg.sender), '!owner');
        _mint(amount, discount);
    }

    function _mint(uint256 amount, uint256 thePrice) internal {
        require(paused == false, 'paused');
        require(amount > 0 && amount <= maxMint, '!amount');
        require(totalSupply() + amount <= maxTotal, '!noneLeft');
        require(msg.value == amount * thePrice, '!price');
        _sendEth(msg.value);
        for (uint256 i = 0; i < amount; i++) {
            _mintToken();
        }
    }

    function _mintToken() internal returns(uint256 tokenId) {
        _tokenIds.increment();
        tokenId = _tokenIds.current();
        _mint(msg.sender, tokenId);
        seeds[tokenId] = _getRandomValue(tokenId);
    }

    function _getRandomValue(uint256 tokenId) internal view returns(uint256) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender, tokenId)));
    }

    function _owns(address erc721, uint256 id, address _owner) internal view returns(bool) {
        return IERC721(erc721).ownerOf(id) == _owner;
    }

    function setDiscount(address erc721, uint256 discount) external onlyOwner {
        require(erc721 != address(0), '!erc721');
        discounts[erc721] = discount;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function _sendEth(uint256 eth) internal {
	      if (eth > 0) {
            (bool success, ) = owner().call{value: eth}("");
            require(success, '!sendEth');
	      }
    }

   function lockHandler() external onlyOwner {
        handlerLocked = true;
    }

   function setHandler(address _handler) external onlyOwner {
        require(!handlerLocked, '!handlerLocked');
        require(_handler != address(0), '!handler');
        handler = IHandler(_handler);
    }

   function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

   function setMaxTotal(uint256 _maxTotal) external onlyOwner {
        require(maxTotalSet == false && _maxTotal < maxTotal, '!setMaxTotal');
        maxTotalSet = true;
        maxTotal = _maxTotal;
    }

 }
