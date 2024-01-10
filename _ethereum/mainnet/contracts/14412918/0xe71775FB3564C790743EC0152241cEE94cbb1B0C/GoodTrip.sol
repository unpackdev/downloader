// SPDX-License-Identifier: MIT

// www.thecreatiiives.com

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract GoodTrip is Ownable, ERC721 {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "ipfs://QmdMTvy7cAbFcU5m4jMjKwahQKw4qRZkiyU2s53gmo8tZ1/";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.1 ether;
  uint256 public wlCost = 0.08 ether;
  uint256 public maxSupply = 5100;
  uint256 public maxMintAmountPerTx = 30;
  uint256 public wlSupply = 150;

  bool public paused = false;
  bool public revealed = true;
  bool public onlyWhitelisted = true;
  mapping(address => uint256) public allowlist;
  mapping(uint256 => uint256) public team;

  constructor() ERC721("GoodTrip", "GT")  {
    setHiddenMetadataUri("");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(!paused, "The contract is paused!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!onlyWhitelisted, "Public not yet started!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");

    _mintLoop(msg.sender, _mintAmount);
  }

  function mintWl(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(onlyWhitelisted, "The presale ended!");
    require(totalSupply() + _mintAmount <= wlSupply, "The presale ended!");
    require(allowlist[msg.sender] - _mintAmount >= 0, "not eligible for allowlist mint");
    require(msg.value >= wlCost * _mintAmount, "Insufficient funds!");
    allowlist[msg.sender] = allowlist[msg.sender] - _mintAmount;

    _mintLoop(msg.sender, _mintAmount);
  }

  function isWhitelisted(address _address) public view returns (uint256)  {
      return allowlist[_address];
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function mintForTeam(uint256 _mintId, address _receiver) public onlyOwner {
    team[_mintId]=1;
    _safeMint(_receiver, _mintId);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setWlCost(uint256 _wlCost) public onlyOwner {
    wlCost = _wlCost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setWlSupply(uint256 _wlSupply) public onlyOwner {
    wlSupply = _wlSupply;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }
  
  function seedAllowlist(address[] memory addresses, uint256 numSlots)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      allowlist[addresses[i]] = numSlots;
    }
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      if(team[supply.current()] == 1) {
        supply.increment();
      }
      _safeMint(_receiver, supply.current());
    }
  }
}