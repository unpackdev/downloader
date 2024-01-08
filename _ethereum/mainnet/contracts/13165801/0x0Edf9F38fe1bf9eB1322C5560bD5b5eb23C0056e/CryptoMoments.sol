
pragma solidity ^0.8.0;

// SPDX-License-Identifier: LGPL-3.0-or-later

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract CryptoMomentsToken is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable, Pausable, PaymentSplitter, ReentrancyGuard {
  using SafeMath for uint256;

  uint256 public constant TOKEN_LIMIT = 100; 
  uint256 private _tokenPrice;
  uint256 private _maxTokensAtOnce = 5;

  bool public publicSale = false;
  bool public privateSale = false;

  uint internal nonce = 0;
  uint[TOKEN_LIMIT] internal indices;

  mapping(address => bool) private _privateSaleAddresses;
  uint256[] private _shares = [75,5,10,10];
  address[] private _payees = [0xd903a646805873D9d86233E6746a7880796fBf08,0x96816B7F0623C92CA22B9288f08f8a84149C4210, 0xbE50AB04E3C5c14503805030877B3B9677FFB3d5, 0x295fAC863B0Ad3dE1BeCCd40856D8fee180986d1];

  constructor()
    PaymentSplitter(_payees, _shares)
    ERC721("Crypto Moments - DAO Hack", unicode"Ξ")
  {
    setTokenPrice(200000000000000000);

    _privateSaleAddresses[msg.sender] = true;

    privateSale = true;
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
    privateSale = false;
  }

  function disablePublicSale() public onlyOwner {
    publicSale = false;
  }

  function disablePrivateSale() public onlyOwner {
    privateSale = false;
  }


  // Token URIs
  function _baseURI() internal override pure returns (string memory) {
    return "ipfs://QmT8Py33ycNKptuiDWJLyztWJfYutLDnVyQq6iDBR4SXRV/";
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
    require(totalSupply().add(_amount) <= TOKEN_LIMIT, "Purchase would exceed max supply of Crypto Moments");
    require(publicSale, "Public sale must be active");
    require(_amount <= _maxTokensAtOnce, "Too many tokens at once");
    require(getTokenPrice().mul(_amount) == msg.value, "Insufficient funds to purchase");

    for(uint256 i = 0; i < _amount; i++) {
      _mintWithRandomTokenId(msg.sender);
    }
  }

  function mintMultipleTokensForPrivateSale(uint256 _amount) public payable nonReentrant {
    require(privateSale, "Private sale must be active to mint");
    require(totalSupply() < 100, "Exceeded private sale tokens allocation");
    require(_privateSaleAddresses[address(msg.sender)], "Not authorised");

    for(uint256 i = 0; i < _amount; i++) {
      _mintWithRandomTokenId(msg.sender);
    }
  }


}