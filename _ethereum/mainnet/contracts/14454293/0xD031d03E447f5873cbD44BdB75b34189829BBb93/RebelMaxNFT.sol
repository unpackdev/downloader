pragma solidity ^0.8.0;

// SPDX-License-Identifier: LGPL-3.0-or-later

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./SafeMath.sol";


contract RebelMaxNFT is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {
  using SafeMath for uint256;

  // Private Sale Addresses
  mapping(address => bool) private _privateAddresses;
  mapping(address => uint256) private _privateReserved;


  // Base URI
  string private _baseURIValue;
  bool public sealedMetadata = false;

  uint256 public totalReserved = 0;
  uint256 public constant TOTAL_TOKEN_LIMIT = 6666; 

  uint256 private constant PROMO_TOKENS = 6;
  uint256 public constant TOKEN_LIMIT = TOTAL_TOKEN_LIMIT - PROMO_TOKENS; 
  uint256 private _tokenPrice;
  uint256 private _tokenPricePrivate;
  uint256 private _maxTokensAtOnce = 40;

  bool public publicSale = false;
  bool public privateSale = false;
  
  

  uint internal nonce = 0;
  uint[TOKEN_LIMIT] internal indices;

  address private _rebelMaxTreasury = 0xb429358e239c50A5c1909553Dd2d97aC1D8965F4; 

  address payable private fee1Address = payable(0x6561Eb4C094a7970DE12DC895391ef20e5fA231B);// 10%;    
  address payable private fee2Address = payable(_rebelMaxTreasury); // 90%

  constructor()
    ERC721("Rebel Max NFT", "MAX")
  {
    
    _tokenPricePrivate = 0;
    setTokenPrice(25000000000000000);


    // Starting with placeholder metadata
    setBaseURI("ipfs://bafybeidejqgvac2pujml4kevrrbe3r6z3rbdufb6y3xbirhszmqtiopcby/");

    

  }

  


  // Required overrides from parent contracts
  function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
    return string(abi.encodePacked(super.tokenURI(tokenId), ""));
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }


  // _tokenPrice
  function getTokenPrice() public view returns(uint256) {
    return _tokenPrice;
  }

  function getTokenPricePrivate() public view returns(uint256) {
    return _tokenPricePrivate;
  }

  function setTokenPrice(uint256 _price) public onlyOwner {
    _tokenPrice = _price;
  }


  // _paused
  function togglePaused() public onlyOwner {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  /*
   * Seals the Metadata 
  */
  function sealMetadata() public onlyOwner {
    sealedMetadata = true;
  }


  // _maxTokensAtOnce
  function getMaxTokensAtOnce() public view returns (uint256) {
    return _maxTokensAtOnce;
  }

  function setMaxTokensAtOnce(uint256 _count) public onlyOwner {
    _maxTokensAtOnce = _count;
  }


  // Team and Public sales
  function enablePublicSale() public onlyOwner {
    publicSale = true;
  }

  function disablePublicSale() public onlyOwner {
    publicSale = false;
  }

  function enablePrivateSale() public onlyOwner {
    privateSale = true;
  }

  function disablePrivateSale() public onlyOwner {
    privateSale = false;
  }


  function setBaseURI(string memory baseURI) public onlyOwner {
      require(!sealedMetadata, "Metadata is sealed forever.");
      _baseURIValue = baseURI;
  }


  // Token URIs
  function _baseURI() internal override view returns (string memory) {
    return _baseURIValue;
  }

  // Pick a random index
  function randomIndex() internal returns (uint256) {
    require(totalSupply()>=6, "Contract not fully initialized.");
    uint256 totalSize = TOKEN_LIMIT - (totalSupply() - PROMO_TOKENS);
    uint256 index = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % totalSize;
    uint256 value = 0;

    if (indices[index] != 0) {
      value = indices[index];
    } else {
      value = index;
    }

    if (indices[totalSize - 1] == 0) {
      indices[index] = totalSize - 1;
    } else {
      indices[index] = indices[totalSize - 1];
    }

    nonce++;

    return value.add(1);
  }


  // Minting single or multiple tokens
  function _mintWithRandomTokenId(address _to) private {
    uint _tokenID = randomIndex();
    _safeMint(_to, _tokenID);
  }

  function mintMultipleTokens(uint256 _amount) public payable nonReentrant whenNotPaused {
    require(totalSupply().add(_amount) <= TOTAL_TOKEN_LIMIT, "Purchase would exceed max supply of NFTs");
    require(publicSale, "Public sale must be active");
    require(_amount <= _maxTokensAtOnce, "Too many tokens at once");
    require(getTokenPrice().mul(_amount) == msg.value, "Insufficient funds to purchase");

    for(uint256 i = 0; i < _amount; i++) {
      _mintWithRandomTokenId(msg.sender);
    }
  }

  

  function mintMultipleTokensForInternalPrivateSale() external onlyOwner {
    uint256 startIndex = TOTAL_TOKEN_LIMIT - PROMO_TOKENS + 1;
    
    for(uint256 i = 0; i < PROMO_TOKENS; i++) {
      _safeMint(_rebelMaxTreasury, startIndex+i);
    }
  }

  function reserveInPrivateSale(uint256 _amount)  public nonReentrant {
    require(privateSale, "Private sale must be active");
    require(_privateReserved[msg.sender] == 0, "Already reserved");
    require(totalReserved+_amount <= (TOTAL_TOKEN_LIMIT.sub(2)), "Reserve would exceeed allocated limit.");
    require(_privateAddresses[msg.sender], "Not authorised to participate");
    require(_amount <= _maxTokensAtOnce, "Too many tokens at once");
    
    // Free for whitelisted

    _privateReserved[msg.sender] = _amount;

    totalReserved += _amount;

  }

  

  function claimTokensFromPrivateSale() public nonReentrant {
    require(publicSale, "Public sale must be active");
    require(_privateReserved[msg.sender] > 0, "Nothing reserved");
    require(totalSupply().add(_privateReserved[msg.sender]) <= TOTAL_TOKEN_LIMIT, "Purchase would exceed private sale allocation.");
    
   
    for(uint256 i = 0; i < _privateReserved[msg.sender]; i++) {
      _mintWithRandomTokenId(msg.sender);
    }

    _privateReserved[msg.sender] = 0;
  }

  function withdraw() public onlyOwner {
        uint balance = address(this).balance;
                
        uint256 fee1 = balance.mul(10).div(100);
        uint256 fee2 = balance.mul(90).div(100);


        fee1Address.transfer(fee1);
        fee2Address.transfer(fee2);

    }


  function isWhitelisted(address _to) public view returns (bool) {
    return _privateAddresses[_to];
  }

  function hasReserved(address _to) public view returns (bool) {
    return _privateReserved[_to] > 0;
  }


  // Private Sale Whitelist
  
  function addPresaleAds(address[] calldata  _addresses) external onlyOwner  {
     for (uint i=0; i<_addresses.length; i++) {
         _privateAddresses[_addresses[i]] = true;
     }
  }
}