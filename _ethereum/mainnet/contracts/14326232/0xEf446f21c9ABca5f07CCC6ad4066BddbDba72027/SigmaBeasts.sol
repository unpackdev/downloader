// SPDX-License-Identifier: MIT

// www.thecreatiiives.com

pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract SigmaBeasts is Ownable, ERC721A {
  using Strings for uint256;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.05 ether;
  uint256 public wlCost = 0.04 ether;
  uint256 public maxSupply = 1000;
  uint256 public maxMintAmountPerTx = 15;
  uint256 public wlSupply = 150;

  bool public paused = false;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  mapping(address => uint256) public allowlist;

  constructor() ERC721A("SigmaBeasts", "SB")  {
    setHiddenMetadataUri("ipfs://QmRpucH9DUzReN9oAhV4f78aGETfj48r3Zz3JEz54JHJWD/hidden.json");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(!paused, "The contract is paused!");
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!onlyWhitelisted, "Public not yet started!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");

    _safeMint(msg.sender, _mintAmount);
  }

  function mintWl(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(onlyWhitelisted, "The presale ended!");
    require(totalSupply() + _mintAmount <= wlSupply, "The presale ended!");
    require(allowlist[msg.sender] - _mintAmount >= 0, "not eligible for allowlist mint");
    require(msg.value >= wlCost * _mintAmount, "Insufficient funds!");
    allowlist[msg.sender] = allowlist[msg.sender] - _mintAmount;

    _safeMint(msg.sender, _mintAmount);
  }

  function isWhitelisted(address _address) public view returns (uint256)  {
      return allowlist[_address];
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
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
}