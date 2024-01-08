// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";

import "./console.sol";

contract DaimonSlayers is ERC721, Ownable {
  using Counters for Counters.Counter;
  using Strings for uint256;
  using SafeMath for uint;

  Counters.Counter private _tokenIds;

  uint public constant PRICE = 0.06 ether;
  uint public constant GIFTABLE = 100;
  uint public constant PUBLIC = 9900;
  uint public constant CAP = GIFTABLE + PUBLIC;
  uint public constant LIMIT_PER_ACCOUNT = 10;

  bool public isActive = false;
  bool public isWhitelistActive = false;
  uint public whitelistLimitPerAccount = 3;
  uint public totalGifted;
  uint public totalMinted;

  mapping (address => bool) private _whitelist;
  mapping (address => uint) private _whitelistMinted;

  string private _tokenBaseURI = '';
  string private _tokenRevealedBaseURI = '';

  constructor() public ERC721("Daimon Slayers", "DS NFT") {}

  function activate(bool _active) external onlyOwner {
    isActive = _active;
  }

  function activateWhitelist(bool _active) external onlyOwner {
    isWhitelistActive = _active;
  }

  function addToWhitelist(address[] calldata _addresses) external onlyOwner {
    for(uint i=0; i<_addresses.length; i++){
      require(_addresses[i] != address(0), "Address can not be null");
      _whitelist[_addresses[i]] = true;
      _whitelistMinted[_addresses[i]] > 0 ? _whitelistMinted[_addresses[i]] : 0;
    }
  }

  function isOnWhitelist(address add) external view returns (bool) {
    return _whitelist[add];
  }

  function removeFromWhitelist(address[] calldata _addresses) external onlyOwner {
    for(uint i=0; i<_addresses.length; i++){
      require(_addresses[i] != address(0), "Address can not be null");
      _whitelist[_addresses[i]] = false;
    }
  }

  function whitelistMintedBy(address _add) external view returns (uint) {
    require(_add != address(0), "Address can not be null");
    return _whitelistMinted[_add];
  }

  function getCap() external pure returns (uint) {
    return CAP;
  }

  function getCurrentId() external view returns (uint256) {
    return _tokenIds.current();
  }

  function capReached() external view returns (bool) {
    return _tokenIds.current() >= CAP;
  }

  function giveaway(address[] calldata _addresses) external onlyOwner {
    require(_tokenIds.current() < CAP, "Total cap has been reached");
    require(totalGifted.add(_addresses.length) <= GIFTABLE, "Not enough to giveway");

    for(uint i=0; i<_addresses.length; i++){
      _tokenIds.increment();
      uint256 newItemId = _tokenIds.current();
      totalGifted = totalGifted.add(1);
      _safeMint(_addresses[i], newItemId);
    }
  }

  function mintWhitelistNFT(address _recipient, uint _quantity) public payable {
    require(isActive, "We are not live yet");
    require(isWhitelistActive, "Whitelist minting is not live");
    require(_whitelist[_recipient], "Sorry, but you are not on the whitelist");
    require(_quantity <= whitelistLimitPerAccount, "This will be over the whitelist mint limit per account");
    require(_whitelistMinted[_recipient].add(_quantity) <= whitelistLimitPerAccount, "This will be over the whitelist mint limit per account");
    require(_tokenIds.current().add(_quantity) <= CAP, "This will exceed total cap");
    require(msg.value == PRICE * _quantity, "The price is 0.06 ETH per token");
    require(totalMinted.add(_quantity) <= PUBLIC, "This will exceed the public limit");

    for(uint i=0; i<_quantity; i++){
      _tokenIds.increment();
      uint256 newItemId = _tokenIds.current();
      totalMinted = totalMinted.add(1);
      _whitelistMinted[_recipient] = _whitelistMinted[_recipient].add(1);
      _safeMint(_recipient, newItemId);
    }
  }

  function mintNFT(address _recipient, uint _quantity) public payable {
    require(isActive, "We are not live yet");
    require(!isWhitelistActive, "Whitelist minting only");
    require(_quantity <= LIMIT_PER_ACCOUNT, "This will be over the mint limit per account");
    require(_tokenIds.current().add(_quantity) <= CAP, "This will exceed total cap");
    require(msg.value == PRICE * _quantity, "The price is 0.06 ETH per token");
    require(totalMinted.add(_quantity) <= PUBLIC, "This will exceed the public limit");

    for(uint i=0; i<_quantity; i++){
      if(totalMinted < PUBLIC){
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        totalMinted = totalMinted.add(1);
        _safeMint(_recipient, newItemId);
      }
    }
  }

  function setWhitelistLimit(uint _limit) external onlyOwner {
    whitelistLimitPerAccount = _limit;
  }

  function getWhitelistLimit() external view returns (uint) {
    return whitelistLimitPerAccount;
  }

  function tokenURI(uint256 _tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(_tokenId), "Token does not exist");

    string memory revealedBaseURI = _tokenRevealedBaseURI;
    return bytes(revealedBaseURI).length > 0 ?
      string(abi.encodePacked(revealedBaseURI, _tokenId.toString())) :
      _tokenBaseURI;
  }

  function setBaseURI(string calldata _uri) external onlyOwner {
    _tokenBaseURI = _uri;
  }

  function setRevealedBaseURI(string calldata _revealedBaseURI) external onlyOwner {
    _tokenRevealedBaseURI = _revealedBaseURI;
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}
