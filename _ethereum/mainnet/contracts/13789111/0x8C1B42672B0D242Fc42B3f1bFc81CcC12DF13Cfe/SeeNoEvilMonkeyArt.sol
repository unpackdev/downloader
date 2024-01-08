// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract SeeNoEvilMonkeyArt is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  string public notRevealedURI;

  uint256 public maxSupply = 9999;
  uint256 public price = 0.06 ether;
  uint256 public whitelistDiscount = 0.01 ether;
  uint256 public maxMintAmount = 10;
  uint256 private _giveAwaysReserved = 100;

  bool public paused = false;
  bool public revealed = false;

  mapping(address => bool) public whitelist;

  constructor(string memory initNotRevealedUri)
    ERC721("SeeNoEvilMonkeyArt", "SNEMA")
  {
    setNotRevealedURI(initNotRevealedUri);
  }

  function mint(uint256 amount) public payable whenNotPaused {
    uint256 supply = totalSupply();

    uint256 currentPrice = price;
    if (whitelist[msg.sender]) currentPrice -= whitelistDiscount;

    require(amount > 0, "Minium amount to mint is 1");
    require(amount <= maxMintAmount, "Exceeds maximum amount of mints per tx");
    require(
      supply + amount <= maxSupply - _giveAwaysReserved,
      "Exceeds maximum supply"
    );
    require(msg.value >= currentPrice * amount, "Ether sent is not correct");

    for (uint256 i; i < amount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  // only owner
  function applyNextMintStage(
    uint256 newMaxSupply,
    uint256 newPrice,
    uint256 newWhitelistDiscount
  ) public onlyOwner {
    setMaxSupply(newMaxSupply);
    setPrice(newPrice);
    setWhitelistDiscount(newWhitelistDiscount);
  }

  function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
    uint256 supply = totalSupply();
    require(
      supply <= newMaxSupply,
      "Current supply exceeds new maximum supply"
    );
    require(
      supply + _giveAwaysReserved <= newMaxSupply,
      "GiveAwaysReserved exceeds new maximum supply"
    );

    maxSupply = newMaxSupply;
  }

  function setPrice(uint256 newPrice) public onlyOwner {
    price = newPrice;
  }

  function setWhitelistDiscount(uint256 newWhitelistDiscount) public onlyOwner {
    whitelistDiscount = newWhitelistDiscount;
  }

  function setMaxMintAmount(uint256 newMaxMintAmount) public onlyOwner {
    maxMintAmount = newMaxMintAmount;
  }

  function setBaseURI(string memory newBaseURI) public onlyOwner {
    baseURI = newBaseURI;
  }

  function setNotRevealedURI(string memory newNotRevealedURI) public onlyOwner {
    notRevealedURI = newNotRevealedURI;
  }

  function reveal() public onlyOwner {
    revealed = true;
  }

  function pause(bool state) public onlyOwner {
    paused = state;
  }

  function addToWhitelist(address addr) public onlyOwner {
    whitelist[addr] = true;
  }

  function addToWhitelistMany(address[] memory addrs) public onlyOwner {
    for (uint256 i = 0; i < addrs.length; i++) {
      whitelist[addrs[i]] = true;
    }
  }

  function setGiveAwaysReserved(uint256 newGiveAwaysReserved) public onlyOwner {
    uint256 supply = totalSupply();
    require(
      supply + newGiveAwaysReserved <= maxSupply,
      "GiveAwaysReserved exceeds maximum supply"
    );

    _giveAwaysReserved = newGiveAwaysReserved;
  }

  function giveAway(address to, uint256 amount) external onlyOwner {
    _giveAway(to, amount);
  }

  function giveAwayMany(address[] memory addresses, uint256[] memory amounts)
    external
    onlyOwner
  {
    require(
      addresses.length == amounts.length,
      "Addresses and amounts doesn't match"
    );

    for (uint256 i = 0; i < addresses.length; i++) {
      _giveAway(addresses[i], amounts[i]);
    }
  }

  function withdrawAll() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _giveAway(address to, uint256 amount) internal {
    require(amount <= _giveAwaysReserved, "Exceeds reserved give aways supply");

    uint256 supply = totalSupply();
    for (uint256 i; i < amount; i++) {
      _safeMint(to, supply + i);
    }

    _giveAwaysReserved -= amount;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return notRevealedURI;
    }

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
        : "";
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  modifier whenNotPaused() {
    require(!paused, "Mint paused");
    _;
  }
}
