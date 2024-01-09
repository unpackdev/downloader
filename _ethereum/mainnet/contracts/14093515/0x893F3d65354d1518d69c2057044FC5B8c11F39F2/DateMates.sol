// SPDX-License-Identifier: MIT

//   _____        _         __  __       _            
//  |  __ \      | |       |  \/  |     | |           
//  | |  | | __ _| |_ ___  | \  / | __ _| |_ ___  ___ 
//  | |  | |/ _` | __/ _ \ | |\/| |/ _` | __/ _ \/ __|
//  | |__| | (_| | ||  __/ | |  | | (_| | ||  __/\__ \
//  |_____/ \__,_|\__\___| |_|  |_|\__,_|\__\___||___/
// 
//  by Jeffrey Mann

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";


contract DateMates is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public previewUrl;
  string public baseURI;
  string public provenance;
  string public baseExtension = ".json";
  uint256 public cost = 0.02 ether;
  uint256 public maxSupply = 4000;
  uint256 public maxMintsPerWallet = 30;
  uint256 public freeQuota = 1500;
  bool public paused = true;
  
  event Created(
    uint indexed count,
    address acc
  );

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _baseURIString,
    uint256 _maxBatchSize,
    uint256 _collectionSize
  ) ERC721A(_name, _symbol, _maxBatchSize, _collectionSize) {
    setBaseURI(_baseURIString);
    setProvenance('0bdb7478a7a39941ee964f1344dccd35cc34ca3f226f0802a487bffbbc2ef046');
  }

  function freeMint(uint256 _mintAmount)
    external
    payable
  {
    uint256 supply = totalSupply();
    require(!paused, "Contract must be unpaused before minting");
    require(supply + _mintAmount <= freeQuota, "The allocated free supply has been minted out.");
    require(numberMinted(msg.sender) + _mintAmount <= 3, "Oh-oh. Max mints during the free stage is 3.");

    _safeMint(msg.sender, _mintAmount);
    emit Created(_mintAmount, msg.sender);
  }

  function mint(uint256 _mintAmount)
    external
    payable
  {
    uint256 supply = totalSupply();
    require(!paused, "Contract must be unpaused before minting");
    require(supply + _mintAmount <= maxSupply, "Max supply has been minted.");
    require(msg.value >= cost * _mintAmount);    
    require(_mintAmount <= 10, "Max mint amount per transaction exceeded");
    require(numberMinted(msg.sender) + _mintAmount <= maxMintsPerWallet, "Maximum minted per address exceeded. Only 30 max mints per account are allowed.");

    _safeMint(msg.sender, _mintAmount);
    emit Created(_mintAmount, msg.sender);
  }  

  function devMint(uint256 _mintAmount)
    external
    payable
    onlyOwner
  {
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "Max supply has been minted.");

    _safeMint(msg.sender, _mintAmount);
    emit Created(_mintAmount, msg.sender);
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
    string memory currentURI = bytes(baseURI).length > 0 ? baseURI : previewUrl;
    return string(abi.encodePacked(currentURI, tokenId.toString(), baseExtension));
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }

  // 
  // Owner Functions
  // 

  function setCost(uint256 _newCost) external onlyOwner {
    cost = _newCost;
  }

  function setFreeQuota(uint256 _freeQuota) external onlyOwner {
    freeQuota = _freeQuota;
  }

  function setProvenance(string memory _provenance) public onlyOwner {
      provenance = _provenance;
  }
  function setPreviewUrl(string memory _previewUrl) public onlyOwner {
      previewUrl = _previewUrl;
  }

  function lowerSupply(uint256 _newMaxSupply) external onlyOwner {
    require(_newMaxSupply < maxSupply, "You can only lower the supply");  
    maxSupply = _newMaxSupply;
  }

  function setMaxMintsPerWallet(uint256 _maxMintsPerWallet) public onlyOwner {
    maxMintsPerWallet = _maxMintsPerWallet;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}