// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

//    ___            _            ___ _                  _       
//   / __\   _ _ __ | | ___   _  / _ \ | __ _ _ __   ___| |_ ___ 
//  / _\| | | | '_ \| |/ / | | |/ /_)/ |/ _` | '_ \ / _ \ __/ __|
// / /  | |_| | | | |   <| |_| / ___/| | (_| | | | |  __/ |_\__ \
// \/    \__,_|_| |_|_|\_\\__, \/    |_|\__,_|_| |_|\___|\__|___/
//                        |___/                                  

contract FunkyPlanets is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string private baseExtension = ".json";
  string public PLANET_PROVENANCE = "";
  // the cost will increase around of 10% for each new 1000 planets
  uint256 private cost0 = 50000000000000000; // 0.05 ether
  uint256 private cost1 = 55000000000000000; // 0.055 ether
  uint256 private cost2 = 60500000000000000; // 0.0605 ether
  uint256 private cost3 = 66800000000000000; // 0.0668 ether
  uint256 private cost4 = 73200000000000000; // 0.0732 ether
  uint256 private cost5 = 80500000000000000; // 0.0805 ether
  uint256 public maxSupply = 4525;
  uint256 public maxMintAmount = 20;
  uint256 public reservedPlanetsForTeam = 50;
  bool public saleIsActive = true;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }

  /*     
  * Set provenance once it's calculated
  */
  function setProvenanceHash(string memory provenanceHash) public onlyOwner {
    PLANET_PROVENANCE = provenanceHash;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function getCostToMint() 
    public
    view
    returns (uint256)
  {
    uint256 supply = totalSupply();
    uint256 _cost = 0;
    if (supply < 1000){
      _cost = cost0;
    } else if (supply >= 1000 && supply < 2000){
      _cost = cost1;
    } else if (supply >= 2000 && supply < 3000){
      _cost = cost2;
    } else if (supply >= 3000 && supply < 4000){
      _cost = cost3;
    } else if (supply >= 4000 && supply < 5000){
      _cost = cost4;
    } else {
      _cost = cost5;
    }

    return _cost;
  }

  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    uint256 _cost = getCostToMint();
    require(saleIsActive, "Sale is not active");
    require(_mintAmount > 0, "At least you should mint one planet");
    require(_mintAmount <= maxMintAmount, "Can only mint the maxMintAmount tokens at a time");
    require(supply + _mintAmount <= maxSupply, "Purchase would exceed max supply of planets");
    require(msg.value >= _cost * _mintAmount, "Ether value sent is not correct, check getCostToMint function to get the individual price");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function mintReservedPlanets(address _to, uint256 _reserveAmount) public onlyOwner {        
    uint256 supply = totalSupply();
    require(saleIsActive, "Sale is not active");
    require(_reserveAmount <= maxMintAmount, "Can only mint the maxMintAmount tokens at a time");
    require(supply + _reserveAmount <= maxSupply, "Purchase would exceed max supply of planets");
    require(_reserveAmount > 0 && _reserveAmount <= reservedPlanetsForTeam, "Purchase would exceed max reserved supply of planets and should be more than 0");
    for (uint256 i = 1; i <= _reserveAmount; i++) {
        _safeMint(_to, supply + i);
    }
    reservedPlanetsForTeam = reservedPlanetsForTeam - _reserveAmount;
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

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  /*
  * Pause sale if active, make active if paused
  */
  function flipSaleState() public onlyOwner {
    saleIsActive = !saleIsActive;
  }

  function withdraw() public payable onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

}
