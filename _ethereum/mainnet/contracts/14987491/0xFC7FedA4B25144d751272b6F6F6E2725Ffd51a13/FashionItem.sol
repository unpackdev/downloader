// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721URIStorage.sol";

contract FashionNFT is ERC721Enumerable, Ownable, Pausable {
  using Address for address;
  using Strings for uint256;

  using SafeMath for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdTracker;
  
  bool public isPublic;
  string public baseUri;
  address[] public whitelists;

  uint256 public MAX_SUPPLY = 10000;
  uint256 public PRIVATE_SUPPLY = 1000;
  uint256 public wlPrice = 1 * 10**17; // 0.1 ETH
  uint256 public publicPrice = 2 * 10**17; // 0.2 ETH

  mapping(address => uint) public firstTokenId;
  mapping(address => bool) public whitelisted;
  mapping(uint => bool) public locked;

  constructor () ERC721 ("FashionItem", "$FIT") {
    setBaseURI("https://api.icon.fashion/api/getTokenURI/fashion/");
    pause(true);
  }

  // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
  function _baseURI() internal view virtual override returns (string memory) {
    return baseUri;
  }

  modifier saleIsOpen {
    require(totalSupply() <= MAX_SUPPLY, "Sale end");
    if (_msgSender() != owner()) {
      require(!paused(), "Pausable: paused");
    }
    _;
  }

  function mintFashionItem(uint256 amount) public payable saleIsOpen {
    uint256 tokenCount = totalSupply();
    if(isPublic == false) {
      require(tokenCount + amount <= PRIVATE_SUPPLY, "Mint: over Max limit");
      require(whitelisted[msg.sender] == true, "Not WL member");
      require(msg.value >= multiprice(wlPrice, amount), "Value below price");
    } else {
      require(tokenCount + amount <= MAX_SUPPLY, "Mint: over Max limit");
      if(whitelisted[msg.sender] == true) {
        require(msg.value >= multiprice(wlPrice, amount), "Value below price");
      } else {
        require(msg.value >= multiprice(publicPrice, amount), "Value below price");
      }
    }

    for (uint256 i = 0; i < amount; i++) {
      _mintAnElement();
    }
  }

  function checkLockValidity(address account, uint256 [] memory fashion_tokenIds) public view returns (bool) {
    for (uint256 i = 0; i < fashion_tokenIds.length; i++) {
      uint check = 0;
      uint256 _tokenId = fashion_tokenIds[i];
      uint256[] memory tokenIDs = tokensOfOwner(account);
      for (uint256 k = 0; k < tokenIDs.length; k++) {
        if (tokenIDs[k] == _tokenId) {
          check = 1;
          break;
        }
      }
      if (check != 1) return false;
    }
    return true;
  }

  function lockFashionItems(address account, uint256 [] memory fashion_tokenIds) public saleIsOpen {
    require(checkLockValidity(account, fashion_tokenIds), "Mint: invalid tokenIds");
    for (uint256 i = 0; i < fashion_tokenIds.length; i++) {
      uint256 tokenId = fashion_tokenIds[i];
      // require(msg.sender==owner(), "Only owner can burn");
      locked[tokenId] = true;
    }
  }

  // undress IconGirl
  function unlockFashionItems(address account, uint256 [] memory fashion_tokenIds) public saleIsOpen {
    require(checkLockValidity(account, fashion_tokenIds), "Mint: invalid tokenIds");
    for (uint256 i = 0; i < fashion_tokenIds.length; i++) {
      uint256 tokenId = fashion_tokenIds[i];
      // require(msg.sender==owner(), "Only owner can burn");
      locked[tokenId] = false;
    }
  }

  // mint one Token to sender
  function _mintAnElement() private {
    _tokenIdTracker.increment();
    uint256 _tokenId = getLastTokenID();
    _safeMint(msg.sender, _tokenId);
  }

  // See which address owns which tokens
  function tokensOfOwner(address addr) public view returns(uint256[] memory) {
    uint256 tokenCount = balanceOf(addr);
    uint256[] memory tokensId = new uint256[](tokenCount);
    for(uint256 i; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(addr, i);
    }
    return tokensId;
  }

  function getLastTokenID() public view returns (uint256) {
    return _tokenIdTracker.current();
  }

  // check if it is paused
  function isPaused() public view returns (bool) {
    return paused();
  }

  // return Token URI
  function tokenURI(uint256 tokenId) public view  virtual override returns (string memory)
  {
    require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
      ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
      : "";
  }

  // set the state of minting
  function pause(bool val) public onlyOwner {
    if (val == true) {
      _pause();
      return;
    }
    _unpause();
  }

  // the total price of token amounts which the sender will mint
  function multiprice(uint256 price, uint256 count) public pure returns (uint256) {
    return price.mul(count);
  }

  // Set a different price for fashion item in case ETH changes drastically
  function setWlPrice(uint256 newPrice) public onlyOwner {
    wlPrice = newPrice;
  }

  // Set a different price for fashion item in case ETH changes drastically
  function setPublicPrice(uint256 newPrice) public onlyOwner {
    publicPrice = newPrice;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
    require(from != to, "cannot transfer to same address");
    require(!locked[tokenId], "Cannot transfer - currently locked");
    super._beforeTokenTransfer(from, to, tokenId);
  }

  // withdraw all coins
  function withdrawAll() public onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "There is no balance to withdraw");
    _widthdraw(msg.sender, balance );
  }

  function _widthdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require(success, "Transfer failed.");
  }

  // Start public mint by Owner
  function startPublicMint(bool state) public onlyOwner {
    isPublic = state;
  }
  // set BaseURL
  function setBaseURI(string memory _baseUri) public onlyOwner {
    baseUri = _baseUri;
  }

  // set MAX_SUPPLY
  function setMaxSupply(uint256 _count) public onlyOwner {
    MAX_SUPPLY = _count;
  }

  // add user's address to whitelist
  function addWhitelistUser(address[] memory _user) public onlyOwner {
    for(uint256 idx = 0; idx < _user.length; idx++) {
      require(whitelisted[_user[idx]] == false, "already set");
      whitelisted[_user[idx]] = true;
      whitelists.push(_user[idx]);
    }
  }

  // remove user's address to whitelist
  function removeWhitelistUser(address[] memory _user) public onlyOwner {
    for(uint256 idx = 0; idx < _user.length; idx++) {
      require(whitelisted[_user[idx]] == true, "not exist");
      whitelisted[_user[idx]] = false;
      removeWhitelistByValue(_user[idx]);
    }
  }

  function removeWhitelistByValue(address value) internal {
    uint i = 0;
    while (whitelists[i] != value) {
      i++;
    }
    removeWhitelistByIndex(i);
  }

  function removeWhitelistByIndex(uint i) internal {
    while (i<whitelists.length-1) {
      whitelists[i] = whitelists[i+1];
      i++;
    }
    whitelists.pop();
  }
}
