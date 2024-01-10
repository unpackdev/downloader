//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract FlowtysStillLife is ERC721, Ownable, ReentrancyGuard {
  using Strings for uint256;

  bool public saleActive = false;
  uint256 constant TOKEN_PRICE_REALTIME = 1 ether;
  uint256 constant TOKEN_PRICE_SLOWED_DOWN = 0.1 ether;
  enum TokenType { Accelerated1, Accelerated2, Accelerated3, RealTime1, RealTime2, RealTime3, SlowedDown1, SlowedDown2, SlowedDown3 } 

  // metadata URI
  string private _baseTokenURI;
  // Number of mints per each token type
  mapping(TokenType => uint256) private _supply;
  // Starting block # for each tokenId
  mapping(uint256 => uint256) private _ages;

  // Period of "aging" for each TokenType expressed in blocks, e.g tokenId 1 ages within 3 days 
  // The threshold between metadata changes, when we need to show a different image
  struct AgeParams { 
    uint256 period;
    uint256 threshold;
  }
  mapping(TokenType => AgeParams) private _ageParams;

  constructor() ERC721("STILL LIFE 2.0", "STLF2") {}

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    Address.sendValue(payable(msg.sender), balance);
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  // Set the period and a threshold for a certain TokenType
  function setAging(TokenType tokenType, uint256 period, uint256 threshold) external onlyOwner {
    _ageParams[tokenType].period = period;
    _ageParams[tokenType].threshold = threshold;
  }

  function flipSaleActive() external onlyOwner {
    saleActive = !saleActive;
  }

  // 1/1s, tokenIDs are 0, 1, 2
  // Pre-mint only for partnered drop
  function mintAcceleratedTo(address account, TokenType tokenType)
    external
    nonReentrant
    onlyOwner
  {
    require(_supply[tokenType] == 0, "this 1/1s has been minted");

    createCollectible(account, tokenType, 1);
  }

  // TokenID disribution
  // 3... 102 => RealTime1
  // 103 ... 202 => RealTime2
  // 203 ... 302 => RealTime3
  function mintRealTime(uint256 qty, TokenType tokenType)
    external
    payable
    nonReentrant
    callerIsUser
    saleIsActive
  {
    require(tokenType >= TokenType.RealTime1 && tokenType <= TokenType.RealTime3, "minting RealTime for invalid token type");
    require(_supply[tokenType] + qty <= 100, "Purchase would exceed max RealTime tokens");
    require(msg.value == (TOKEN_PRICE_REALTIME * qty), "Ether value sent is not the required price");

    createCollectible(msg.sender, tokenType, qty);
  }

  // Pre-mint some amount for a partnered drop
  function preMintRealTimeTo(address account, uint256 qty, TokenType tokenType)
    public
    onlyOwner
  {
    require(tokenType >= TokenType.RealTime1 && tokenType <= TokenType.RealTime3, "minting RealTime for invalid token type");
    require(_supply[tokenType] + qty <= 100, "Purchase would exceed max RealTime tokens");

    createCollectible(account, tokenType, qty);
  }

  // TokenID disribution
  // 303 ... 1302 => SlowedDown1
  // 1303 ... 2302 => SlowedDown2
  // 2303 ... 3302 => SlowedDown3
  function mintSlowedDown(uint256 qty, TokenType tokenType)
    external
    payable
    nonReentrant
    callerIsUser
    saleIsActive
  {
    require(tokenType >= TokenType.SlowedDown1 && tokenType <= TokenType.SlowedDown3, "minting SlowedDown for invalid token type");
    require(_supply[tokenType] + qty <= 1000, "Purchase would exceed max SlowedDown tokens");
    require(msg.value == (TOKEN_PRICE_SLOWED_DOWN * qty), "Ether value sent is not the required price");

    createCollectible(msg.sender, tokenType, qty);
  }

  // Pre-mint some amount for a partnered drop
  function preMintSlowedDownTo(address account, uint256 qty, TokenType tokenType)
    external
    onlyOwner
  {
    require(tokenType >= TokenType.SlowedDown1 && tokenType <= TokenType.SlowedDown3, "minting SlowedDown for invalid token type");
    require(_supply[tokenType] + qty <= 1000, "Purchase would exceed max SlowedDown tokens");

    createCollectible(account, tokenType, qty);
  }

  function createCollectible(address mintAddress, TokenType tokenType, uint256 qty) private {
    for(uint256 i = 0; i < qty;) {
      uint256 tokenId = getTokenTypeStartingIndex(tokenType) + _supply[tokenType] + i;
      _safeMint(mintAddress, tokenId);
      _ages[tokenId] = block.number;
      unchecked { ++i; }
    }
    _supply[tokenType] += qty;
  }

  function getSupply(TokenType tokenType)
    public
    view 
    returns (uint256)
  {
    return _supply[tokenType];
  }

  // Returns the age stage for a given tokenId based on starting point and current block #
  // Result is a sequential number depending on _ageBlocksThreshold
  // Starts from 0 and corresponds to the very first image & metadata
  function getAge(uint256 tokenId) 
    public 
    view 
    returns (uint256)
  {
    require(_exists(tokenId), "getAge query for nonexistent token");
    TokenType tokenType = getTokenTypeById(tokenId);
    if (_ages[tokenId] > 0) {
      uint256 currentAge = (uint((block.number - _ages[tokenId]) % _ageParams[tokenType].period) / _ageParams[tokenType].threshold);
      return currentAge;
    }
    return 0;
  }

  function getTokenTypeById(uint256 tokenId) 
    private 
    pure 
    returns (TokenType)
  {
    if (tokenId <= uint8(TokenType.Accelerated3)) {
      return TokenType(tokenId);
    } else if (tokenId <= 102) {
      return TokenType.RealTime1;
    } else if (tokenId <= 202) {
      return TokenType.RealTime2;
    } else if (tokenId <= 302) {
      return TokenType.RealTime3;
    } else if (tokenId <= 1302) {
      return TokenType.SlowedDown1;
    } else if (tokenId <= 2302) {
      return TokenType.SlowedDown2;
    }
    return TokenType.SlowedDown3;
  }

  // Token id distribution by a token type:
  // 0, 1, 2 - 1/1s Accelerated
  // 3... 102 => RealTime1
  // 103 ... 202 => RealTime2
  // 203 ... 302 => RealTime3
  // 303 ... 1302 => SlowedDown1
  // 1303 ... 2302 => SlowedDown2
  // 2303 ... 3302 => SlowedDown3
  function getTokenTypeStartingIndex(TokenType tokenType) 
    private 
    pure 
    returns (uint256)
  {
    if (tokenType <= TokenType.Accelerated3) {
      return uint8(tokenType);
    } else if (tokenType <= TokenType.RealTime3) {
      return 3 + 100 * (uint8(tokenType) - 3);
    }
    return 303 + 1000 * (uint8(tokenType) - 6);
  }


  modifier saleIsActive() {
    require(saleActive, "The sale is not active");
    _;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  /**
  * @dev See {ERC721Metadata-tokenURI}.
  */
  //---------------------------------------------------------------------------------
  // We build URL is a following way: _baseTokenURI + tokenType + AGE (0...period)
  // There's only 9 unique artworks, so there's no point in duplicating the metadata
  // e.g. for tokenType 0 and age 0 : ipfs://hash_of_ipfs/0/0
  // e.g. for tokenType 3 and age 10 : ipfs://hash_of_ipfs/3/10
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "tokenURI query for nonexistent token");
    return bytes(_baseTokenURI).length > 0 ? 
          string(
            abi.encodePacked(abi.encodePacked(abi.encodePacked(_baseTokenURI, uint256(getTokenTypeById(tokenId)).toString()), "/"), getAge(tokenId).toString()))
          : "";  }

  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }
}