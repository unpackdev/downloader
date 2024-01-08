
pragma solidity ^0.8.0;

// SPDX-License-Identifier: LGPL-3.0-or-later

//               crypto
//        moments    mon
//     cry          ts @
//    pt ts         p   ts
//   @c   to      me     t
//  c      r     cry      m
// to    cmoments  to     om
// crypto    me     crypto @
//  @         t moments    p
//   t       pt      me    p
//    @c     mo        ts r
//    mo    to         cry
//      m  ts           @
//       cr          cryp
//        cryptomoments

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./SafeMath.sol";

import "./IPreviousCollection.sol";

contract CryptoMomentsNextToken is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable, Pausable, PaymentSplitter, ReentrancyGuard {
  using SafeMath for uint256;

  uint256 private constant _PUBLIC_TOKENS = 100; 
  uint256 private constant _FREE_TOKENS = 70; 

  uint256 public constant TOKEN_LIMIT = _PUBLIC_TOKENS + _FREE_TOKENS; 

  uint256 private _tokenPrice;
  uint256 private _maxTokensAtOnce = 5;

  bool public publicSale = false;
  bool public privateSale = true;


  uint internal nonce = 0;
  uint[TOKEN_LIMIT] internal indices;

  

  mapping(address => bool) private _privateSaleAddresses;
  uint256[] private _shares = [45,45,10];
  address[] private _payees = [0xd903a646805873D9d86233E6746a7880796fBf08,0x96816B7F0623C92CA22B9288f08f8a84149C4210, 0x295fAC863B0Ad3dE1BeCCd40856D8fee180986d1];

  address _previuosMomentsContractAddress = 0x0Edf9F38fe1bf9eB1322C5560bD5b5eb23C0056e;
  mapping(address => bool) private _bonusAlreadyClaimed;

  constructor()
    PaymentSplitter(_payees, _shares)
    ERC721("Crypto Moments - BTC Genesis", unicode"₿")
  {
    setTokenPrice(100000000000000000);

    _privateSaleAddresses[msg.sender] = true;

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

  function disablePrivateSale() public onlyOwner {
    privateSale = false;
  }

  function setPreviousMomentsContractAddress(address _contractAddress) public onlyOwner {
    _previuosMomentsContractAddress = _contractAddress;
  }

  // Token URIs
  function _baseURI() internal override pure returns (string memory) {
    return "ipfs://Qma7x4XeJk54WuNuY2kZYYCe47epEAZBr43VoodAyPgmef/";
  }

  // Pick a random index
  function randomIndex() internal returns (uint256) {
    uint256 totalSize = TOKEN_LIMIT - totalSupply();
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
    require(totalSupply().add(_amount) <= _PUBLIC_TOKENS, "Purchase would exceed public sale supply.");
    require(publicSale, "Public sale must be active");
    require(_amount <= _maxTokensAtOnce, "Too many tokens at once");
    require(getTokenPrice().mul(_amount) <= msg.value, "Insufficient funds to purchase");

    for(uint256 i = 0; i < _amount; i++) {
      _mintWithRandomTokenId(msg.sender);
    }
  }

  function mintMultipleTokensForPrivateSale(uint256 _amount, address _to) public payable nonReentrant {
    require(privateSale, "Private sale ended");
    require(totalSupply() < TOKEN_LIMIT, "Purchase would exceed max supply of Crypto Moments");
    require(_privateSaleAddresses[address(msg.sender)], "Not authorised");

    for(uint256 i = 0; i < _amount; i++) {
      _mintWithRandomTokenId(_to);
    }
  }

  function mintBonusTokenForPreviousOwners() public nonReentrant {
     
     require(totalSupply() >= _PUBLIC_TOKENS, "Public sale did not end yet.");
     require(totalSupply().add(1) <= TOKEN_LIMIT, "Purchase would exceed max supply of Crypto Moments");
     require(!_bonusAlreadyClaimed[address(msg.sender)], "Bonus already claimed");
     require(balanceOfPreviousMoments(address(msg.sender))>0, "Not a proud owner of a piece of crypto history.");

     _mintWithRandomTokenId(msg.sender);

     _bonusAlreadyClaimed[address(msg.sender)] = true;
  }

  function ownerOfPreviousMoments(uint _tokenId) public view returns (address) {
    IPreviousCollection previous = IPreviousCollection(_previuosMomentsContractAddress);
    return previous.ownerOf(_tokenId);
  }

  function balanceOfPreviousMoments(address _owner) public view returns (uint256) {
    IPreviousCollection previous = IPreviousCollection(_previuosMomentsContractAddress);
    return previous.balanceOf(_owner);
  }

  


}