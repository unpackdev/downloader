// SPDX-License-Identifier: GPL-3.0

// Created by HashLips, ticket system added by Josh
// The Nerdy Coder Clones

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract ME_NFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public contractURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.11 ether;
  uint256 public wlcost = 0.11 ether;
  uint256 public maxSupply = 777;
  uint256 public ticketSupply = 0;
  uint256 public maxMintAmount = 10;
  uint256 public nftPerAddressLimit = 10;
  bool public ticketsPaused = true;
  bool public mintPaused = false;
  bool public onlyWhitelisted = false;
  bool public revealed = false;
  address[] public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;
  mapping(address => uint256) public addressTicketBalance;

  constructor(
  ) ERC721("METELITE METs", "MET") {
    setBaseURI("ipfs://");
    setNotRevealedURI("ipfs://Qmdknk7pQu9bDevzZnc4XUnfVS72uw5cLZWE8uSiCiNoLT");
    buyTickets(20);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(address _to, uint256 _mintAmount) public {
    uint256 supply = totalSupply();

    require(!mintPaused, "minting is paused");
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(addressTicketBalance[msg.sender] >= _mintAmount, "insufficient tickets"); //check if there are enough tickets

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressTicketBalance[msg.sender]--; //remove tickets from minting address
      addressMintedBalance[_to]++;
      _safeMint(_to, supply + i);
    }
  }

  function buyTickets(uint256 _ticketAmount) public payable {
    require(_ticketAmount > 0, "need to buy at least 1 ticket");
    require(ticketSupply + _ticketAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
      require(!ticketsPaused, "tickets are paused");
      require(_ticketAmount <= maxMintAmount, "max mint amount per session exceeded");

      if(onlyWhitelisted == true) {
          require(isWhitelisted(msg.sender), "user is not whitelisted");
          uint256 ownerTicketCount = addressTicketBalance[msg.sender];
          uint256 ownerMintedCount = addressMintedBalance[msg.sender];
          require(ownerTicketCount + _ticketAmount + ownerMintedCount <= nftPerAddressLimit, "max NFTs/tickets per address exceeded");
          require(msg.value >= wlcost * _ticketAmount, "insufficient funds");
      } else {
        require(msg.value >= cost * _ticketAmount, "insufficient funds");
      }
    }

    addressTicketBalance[msg.sender]+=_ticketAmount; //add tickets to minting address
    ticketSupply+=_ticketAmount; //add tickets to total supply
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

    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setWlCost(uint256 _newWlCost) public onlyOwner {
    wlcost = _newWlCost;
  }

  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function ticketPause(bool _state) public onlyOwner {
    ticketsPaused = _state;
  }

  function mintPause(bool _state) public onlyOwner {
    mintPaused = _state;
  }

  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }

  function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }

  function whitelistUser(address _user) public onlyOwner {
    whitelistedAddresses.push(_user);
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}
