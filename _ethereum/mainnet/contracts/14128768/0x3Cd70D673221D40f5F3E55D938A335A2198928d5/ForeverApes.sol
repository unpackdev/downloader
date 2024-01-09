// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract ForeverApes is ERC721Enumerable, Ownable {

  string public baseURI;
  using Strings for uint;
  uint public maxSupply = 150;
  uint public saleState; 
  using Counters for Counters.Counter;  
  Counters.Counter private _tokenIdCounter;
  mapping(address => bool) public isWhitelisted;
  mapping(uint => bool) public redeemed;
  
  event redeemEvent(address indexed _from, uint indexed _id, bool _value);


  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

/*
Free Mint for whitelisted folks
*/
  function mint() public payable {
    require(saleState == 1, 'Sale is not active');
    require(super.totalSupply()+1  <= maxSupply, 'Not enough supply');
    require(isWhitelisted[msg.sender], 'Only whitelisted users allowed to mint Genesis token');
    isWhitelisted[msg.sender] = false;
    _safeMint(msg.sender, _tokenIdCounter.current());
    redeemed[_tokenIdCounter.current()]=false;
    _tokenIdCounter.increment();
  }

  
  function walletOfOwner(address _owner)
    public
    view
    returns (uint[] memory)
  {
    uint ownerTokenCount = balanceOf(_owner);
    uint[] memory tokenIds = new uint[](ownerTokenCount);
    for (uint i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setSaleState(uint _state) public onlyOwner {
    saleState = _state;
  }
  
//Whitelist addresses

  function whitelist(address[] memory _users) public onlyOwner {
      for(uint i = 0; i < _users.length; i++) {
          require(!isWhitelisted[_users[i]], 'already whitelisted');
          isWhitelisted[_users[i]] = true;
      }
  }
  
  //unWhitelist addresses
  function unWhitelist(address[] memory _users) public onlyOwner {
     for(uint i = 0; i < _users.length; i++) {
          require(isWhitelisted[_users[i]], 'not whitelisted');
          isWhitelisted[_users[i]] = false;
     }
  }
 
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}('');
    require(success);
  }

/*
Code to facilitate book redemptions and if a book has been claimed for a token. The team will decide if this the way to go.
*/
  function redeemBook(uint tokenId) public{ 
   address tokenOwner = ownerOf(tokenId);
   require(tokenOwner == msg.sender,'Only token owner can redeem' );
   require(redeemed[tokenId]==false, 'Book already redeemed with token');
   redeemed[tokenId]=true;
   emit redeemEvent(msg.sender, tokenId, true);

  } 
 
}