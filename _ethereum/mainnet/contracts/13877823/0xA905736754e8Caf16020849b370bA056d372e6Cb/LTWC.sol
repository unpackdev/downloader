// SPDX-License-Identifier: GPL-3.0

// Created by HashLips
// The Nerdy Coder Clones

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract LTWC is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public contractURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.055 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmount = 10;
  uint256 public nftPerAddressLimit = 10;
  uint256 public nftPresaleLimit = 250;
  bool public paused = true;
  bool public presaleActive = true;
  address[] public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;


  constructor(
  ) ERC721("Lazy Tiger Wood Club", "LTWC") {
    setBaseURI("https://gateway.pinata.cloud/ipfs/QmUzBkeEfVqp73BUuFvSFUgyX2vbcBwkEW8KSvf73SwY3Z/");
    mint(20);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];

    if (msg.sender != owner()) {
      require(!paused, "the contract is paused");
      require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
      require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");

      if(presaleActive == true && isWhitelisted(msg.sender) == false) {
        require(supply + _mintAmount <= nftPresaleLimit, "OG LTWC presale sold out");
      }

      require(msg.value >= cost * _mintAmount, "insufficient funds");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
        addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }

  function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
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

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setNftPresaleLimit(uint256 _newNftPresaleLimitt) public onlyOwner {
    nftPresaleLimit = _newNftPresaleLimitt;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function setPresaleActive(bool _state) public onlyOwner {
    presaleActive = _state;
  }

  function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}
