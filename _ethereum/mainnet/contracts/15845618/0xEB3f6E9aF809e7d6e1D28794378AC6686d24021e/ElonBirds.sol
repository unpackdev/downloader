// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";

contract ElonBirds is ERC721, Ownable, ReentrancyGuard {
    string private _collectionURI;
    string public baseURI;

    uint256 public constant MAX_SUPPLY = 4200;

    uint256 public price = 0.00 ether;
    uint256 public maxPerWallet = 10;

    bool private _isActive = false;

    mapping(uint256 => string) internal tokenUris;
    mapping(address => uint256) internal walletCap;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    constructor() ERC721("Elon Birds", "EB") {
    }

    function mint(uint256 numberOfTokens) public payable nonReentrant() {
        require(_isActive, "Sale must be active to mint.");
        require(numberOfTokens > 0, "Must mint at least 1 token.");
        require(walletCap[msg.sender] + numberOfTokens <= maxPerWallet, "Purchase would exceed max number of tokens per wallet.");
        require(_tokenSupply.current() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max number of tokens.");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _tokenSupply.increment();
            _mint(msg.sender, _tokenSupply.current());
        }
        walletCap[msg.sender] += numberOfTokens;
    }

    // ============ READ-ONLY FUNCTIONS ============
    function tokenURI(uint256 tokenId)
      public
      view
      virtual
      override
      returns (string memory)
    {
      require(_exists(tokenId), "ERC721Metadata: query for nonexistent token");
      
      // Custom tokenURI exists
      if (bytes(tokenUris[tokenId]).length != 0) {
        return tokenUris[tokenId];
      }
      else {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
      }
    }

    function totalSupply() public view returns (uint256) {
        return _tokenSupply.current();
    }

    function contractURI() public view returns (string memory) {
        return _collectionURI;
    }

    function isActive() external view returns (bool) {
        return _isActive;
    }

    function numMintedForAddress(address addr) external view returns (uint256) {
        return walletCap[addr];
    }

    // ============ ADMIN FUNCTIONS ============
    function mintToAddress(address _to, uint256 numberOfTokens) external onlyOwner {
        require(numberOfTokens > 0, "Must mint at least 1 token.");
        require(_tokenSupply.current() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max number of tokens.");
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _tokenSupply.increment();
            _mint(_to, _tokenSupply.current());
        }
    }

    function startSale() external onlyOwner {
        _isActive = true;
    }

    function endSale() external onlyOwner {
        _isActive = false;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxPerWallet(uint256 _max) external onlyOwner {
        maxPerWallet = _max;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setCollectionURI(string memory collectionURI) internal virtual onlyOwner {
        _collectionURI = collectionURI;
    }

    function setTokenURI(uint256 _tokenId, string memory _uri) external onlyOwner {
        tokenUris[_tokenId] = _uri;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}