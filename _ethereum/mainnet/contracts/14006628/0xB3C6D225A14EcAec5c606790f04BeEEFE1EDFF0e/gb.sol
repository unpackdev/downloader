// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract GhettoBabyz is ERC721, Ownable {
  using Strings for uint256;

  using Counters for Counters.Counter;
  Counters.Counter private tokenSupply;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.05 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmount = 50;
  uint256 public nftPerAddressLimit = 100;
  bool public paused = false;
  bool public revealed = true;
  bool public onlyWhitelisted = true;
  address[] public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    require(!paused, "the contract is paused");
    uint256 supply = tokenSupply.current();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
        if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "user is not whitelisted");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
        }
        require(msg.value >= cost * _mintAmount, "insufficient funds");
    }

    for (uint256 i = 0; i < _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      tokenSupply.increment();
      _safeMint(msg.sender, supply + i);
    }
  }

  function isWhitelisted(address _user) public view returns (bool) {
      for(uint256 i = 0; i < whitelistedAddresses.length; i++) {
          if (whitelistedAddresses[i] == _user) {
              return true;
          }
      }
      return false;
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

  //only owner
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner() {
    nftPerAddressLimit = _limit;
  }

  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
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

  function setOnlyWhitelisted(bool _state) public payable onlyOwner() {
    onlyWhitelisted = _state;
  }
 
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }

  function whitelistUsers(address[] calldata _users) public {
      delete whitelistedAddresses;
      whitelistedAddresses = _users;
  }
}


// I made her stand outside forever like the statue of liberty 