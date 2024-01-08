// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract TrashPandaSociety is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.06 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmount = 20;
  bool public paused = true;
  mapping(address => bool) public whitelisted;

  constructor(
    string memory _initBaseURI
  ) ERC721("TrashPandaSociety", "TPS") {
    setBaseURI(_initBaseURI, baseExtension);
  }

  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "You can't mint zero tokens.");
    require(supply + _mintAmount <= maxSupply, "There is not enough tokens left to mint your requested amount. Reduce the amount and try again.");
    
    if (msg.sender != owner()) {
      require(_mintAmount <= maxMintAmount, "Sorry, you are trying to mint too many tokens.");
      require(msg.value >= cost * _mintAmount, "There was not enough eth sent to mint the tokens you want");
      uint256 ownerTokenCount = balanceOf(msg.sender);
      require(ownerTokenCount + _mintAmount <= maxMintAmount, "You own to many tokens to keep minting.");

      if(whitelisted[msg.sender] != true) {
        require(!paused, "Minting is currently pasued, please check our social media for updates.");        
      }
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function bulkCreate(address[] calldata _addresses) public payable onlyOwner {
    uint256 supply = totalSupply();
    supply += 1;
    for (uint i=0; i<_addresses.length; i++) {
      _safeMint(_addresses[i], supply + i);
    }
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

  function pause(bool _state) external onlyOwner {
    paused = _state;
  }

  function withdraw(uint256 amount) external onlyOwner {
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "TPS: The transfer failed");
  }

  function whitelistUser(address[] calldata _addresses) external onlyOwner {
    for (uint i=0; i<_addresses.length; i++) {
      whitelisted[_addresses[i]] = true;
    }
  }
 
  function removeWhitelistUser(address[] calldata _addresses) external onlyOwner {
    for (uint i=0; i<_addresses.length; i++) {
      whitelisted[_addresses[i]] = false;
    }
  }

  function setBaseURI(string memory _newBaseURI, string memory _newBaseExtension) public onlyOwner {
    baseURI = _newBaseURI;
    baseExtension = _newBaseExtension;
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

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setMaxMintAmount(uint256 _newMaxMintAmount) external onlyOwner {
    maxMintAmount = _newMaxMintAmount;
  }
}