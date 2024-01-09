// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

abstract contract OwnableCustom is Ownable{
  using SafeMath for uint256;

  address[] internal _ownersList;

  constructor (address[] memory _list) Ownable() {
    _ownersList = _list;
  }

  modifier owners {
    require(_isOwner(msg.sender),"Reserved for owners!");
    _;
  }

  function _isOwner(address _user) internal view returns(bool){
    bool isOwner = false;
    if(_user == owner())
      isOwner = true;
    for (uint256 i=0; i<_ownersList.length && !isOwner; i++) {
      if(_user == _ownersList[i])
        isOwner = true;
    }
    return isOwner;
  }

  function getOwners() external view owners returns (address[] memory) {
    return _ownersList;
  }

  function setOwners(address[] memory _list) external owners{
    delete _ownersList;
    _ownersList = _list;
  }

  function withdrawOwners() external owners{
    uint256 balance = address(this).balance;
    for (uint i=0; i<_ownersList.length; i++) {
      (bool os, ) = payable(_ownersList[i]).call{
        value: balance.div(_ownersList.length)
      }("");
      require(os);
    }
  }
}

contract TEDDYz is ERC721, OwnableCustom {
  using Strings for uint256;
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  // ---------- Variables
  string public uriPrefix = "";
  string public hiddenUri = "";
  string public uriSuffix = ".json";
  
  uint256 public cost = 0.1 ether;
  uint256 public whitelistCost = 0.05 ether;
  uint256 public maxSupply = 3333;
  uint256 public limitPerTx = 30;
  uint256 public limitPerAddress = 30;
  uint256 public whitelistAmount = 3233;
  uint256 public reservedTokens = 100;
  uint256 private _reservedMinted = 0;
  uint256 public revealedTokens = 0;

  bool public isOpen = false;
  bool public whitelistOpen = false;

  address[] private _whitelist;

  // ---------- Constructor
  constructor(string memory name, string memory symbol, string memory _hiddenUri, address[] memory _ownersList)
  ERC721(name, symbol)
  OwnableCustom(_ownersList)  
  {
    hiddenUri = _hiddenUri;
    _whitelist = new address[](0);
  }

  // ---------- Modifiers
  modifier open {
    require(isOpen, "Contract is paused");
    _;
  }

  // ---------- Setters
  /**
   * @notice 
   * - new max supply must be greater than current
   * - whitelistAmount is the index of the token where the whitelist will end
   * - new reserved tokens must be at least as big as current 
   */
  function setNewPhase(
    uint256 _newCost, uint256 _newWhitelistCost, uint256 _newSupply,
    uint256 _newWhitelistAmount, uint256 _newReservedTokens
  ) external owners {
    require(_newSupply>=maxSupply,"Supply must be bigger than current max");
    require(_newWhitelistAmount<=_newSupply,"Whitelist must be within supply");
    require(_newReservedTokens>=reservedTokens,"Reserved tokens at least as big as current");
    cost = _newCost;
    whitelistCost = _newWhitelistCost;
    maxSupply = _newSupply;
    whitelistAmount = _newWhitelistAmount;
    reservedTokens = _newReservedTokens;
  }

  function setOpen(
    bool _isOpen, bool _whitelistOpen,
    uint256 _limitPerTx, uint256 _limitPerAddress,
    address[] memory _list
  ) external owners{
    isOpen = _isOpen;
    whitelistOpen = _whitelistOpen;
    limitPerTx = _limitPerTx;
    limitPerAddress = _limitPerAddress;
    delete _whitelist;
    _whitelist = _list;
  }

  function setRevealed(uint256 _revealedTokens, string memory _uriPrefix, string memory _hiddenUri, string memory _uriSuffix) external owners{
    revealedTokens = _revealedTokens;
    uriPrefix = _uriPrefix;
    hiddenUri = _hiddenUri;
    uriSuffix = _uriSuffix;
  }

  // ---------- Views

   function totalSupply() external view returns (uint256) {
    return supply.current();
  }
  
  function getReservedMinted() external view returns (string memory) {
    if(_isOwner(msg.sender)) return _reservedMinted.toString();
    return "Available for owners only.";
  }

  function getWhitelist() external view owners returns (address[] memory) {
    return _whitelist;
  }

  function walletOfOwner(address _owner) external view returns (uint256[] memory) {
    uint256 ownedCount = balanceOf(_owner);
    uint256 ownedIndex = 0;
    uint256[] memory ownedIDs = new uint256[](ownedCount);
    uint256 index = 1;
    while (ownedIndex < ownedCount && index <= maxSupply) {
      address currentTokenOwner = ownerOf(index);
      if (currentTokenOwner == _owner) {
        ownedIDs[ownedIndex] = index;
        ownedIndex++;
      }
      index++;
    }
    return ownedIDs;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (_tokenId > revealedTokens || _tokenId < 1) {
      return hiddenUri;
    }

    string memory baseUri = _baseURI();
    return bytes(baseUri).length > 0
        ? string(abi.encodePacked(baseUri, _tokenId.toString(), uriSuffix))
        : "";
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function isWhitelisted(address _user) public view returns (bool) {
    bool isWL = false;
    for (uint i=0; i<_whitelist.length && !isWL; i++) {
      if(_user == _whitelist[i])
        isWL = true;
    }
    return isWL;
  }

  // ---------- Mint
  function mint(uint256 _amount) public payable open {
    require(_amount > 0 && _amount <= limitPerTx, "Invalid mint amount!");
    require((_amount + balanceOf(msg.sender)) <= limitPerAddress, "You will exceed the maximum amount per address!");
    if(whitelistOpen){
      require(isWhitelisted(msg.sender),"You have not been whitelisted");
      require(supply.current() + _amount<= whitelistAmount, "Whitelist supply exceeded!");
      require(msg.value >= whitelistCost * _amount, "Insufficient funds!");
    }
    else{
      require(msg.value >= cost * _amount, "Insufficient funds!");
    }
    require(supply.current() + _amount + (reservedTokens - _reservedMinted) <= maxSupply, "Max supply exceeded!");
    _mintFx(msg.sender, _amount);
  }

  function ownerMintForAirdrop(uint256 _amount, address _receiver) public owners{
    require(_amount <= (reservedTokens-_reservedMinted), "Mint would exceed reserved tokens");
    require(supply.current() + _amount <= maxSupply, "Max supply exceeded!");
    _mintFx(_receiver, _amount);
    _reservedMinted += _amount;
  }
  
  function _mintFx(address _receiver, uint256 _amount) internal {
    for (uint256 i = 0; i < _amount; i++) {
      _safeMint(_receiver, supply.current()+1);
      supply.increment();
    }
  }

  // ---------- other
  function withdraw(uint256 _percent) external owners {
    uint256 amount = address(this).balance / 100 * _percent;
    (bool os, ) = payable(owner()).call{value: amount}("");
    require(os);
  }
}
