// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";
import "./ERC721A.sol";

/*

https://hashed.city

Hashed City it's a digital representation of cities around the world. 
We manually select some of the bests cities to be part of this collection.
*/

contract HashedCity is ERC721A, Ownable {
  using Strings for uint256;

  address public constant proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

  string defaultUri = "ipfs://QmNTmxw8NMjD5fpL2quJBb7zBwjXfH4mpRMUGyEcQkmdmx/";
  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.002 ether;  
  uint256 public maxSupply = 6000;
  uint256 public freeSupply = 200;
  uint256 public maxMintAmount = 10;
  bool public paused = true;

  constructor() ERC721A("Hashed City", "CITY") { }

  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused, "Paused");
    require(_mintAmount > 0, "Invalid mint number");
    require(_mintAmount <= maxMintAmount, "Exceeds max per tx");
    require(supply + _mintAmount <= maxSupply, "Exceeds max supply");

    if ( msg.sender != owner() && supply + _mintAmount > freeSupply ) {
      require(msg.value >= cost * _mintAmount, "Invalid funds provided");
    }
    
    _safeMint(msg.sender, _mintAmount);
    
  }

    /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  ) override public view returns (bool isOperator) {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }

    return super.isApprovedForAll(_owner, _operator);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    
    string memory currentBaseURI = baseURI;
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : defaultUri;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function updateMaxSupply(uint256 _supply) public onlyOwner {
    maxSupply = _supply;
  }

  function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
    maxMintAmount = _newMaxMintAmount;
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
 
  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}

contract OwnableDelegateProxy { }
contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}