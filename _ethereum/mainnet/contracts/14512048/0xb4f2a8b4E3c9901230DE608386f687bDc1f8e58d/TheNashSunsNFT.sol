// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract TheNashSunsNFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.0049 ether;
  uint256 public maxSupply = 250;
  bool public paused = false;
  uint256[250] public cost_per_mint;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    mint(msg.sender,0.005 ether);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(address _to, uint256 _newCost) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(supply + 1 <= maxSupply);
    require(_newCost > cost);
        
    cost = _newCost;
    if (msg.sender != owner()) {
      require(msg.value >= cost);
    }
    _safeMint(_to, supply + 1);
    cost_per_mint[supply]=cost;
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

  function getCostPerMint() public view returns (uint256[250] memory) {
      return cost_per_mint;
  }

  //only owner
  
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
    require(payable(msg.sender).send(address(this).balance));
  }
}