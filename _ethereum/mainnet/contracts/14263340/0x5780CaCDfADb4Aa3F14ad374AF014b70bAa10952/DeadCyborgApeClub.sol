// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract DeadCyborgApeClub is ERC721Enumerable, Ownable {
  using Strings for uint256;
  
  string baseURI;
  string public baseExtension = ".json";
  bool public revealed = false;

  uint256 public cost = 0.09 ether;
  uint256 public preSaleCost = 0.06 ether;

  uint256 public maxSupply = 9999;
  uint256 public maxMintAmount = 10;

  bool public paused = true;

  bool public preSaleActive = true;
  mapping(address => bool) public whitelist;

  constructor() ERC721("Dead Cyborg Ape Club","DCAC") {//what do you want to symbol be
    setBaseURI("tokenURI");
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused, "Sale is not active!");
    require(_mintAmount > 0,"Mint amount must be more than zero!");
    require(_mintAmount <= maxMintAmount, "Exceeds maximum tokens you can purchase in a single transaction!");
    require(supply + _mintAmount <= maxSupply, "Exceeds maximum supply, check your amount!");

    if (msg.sender != owner()) {
        if(preSaleActive == true){
            require(whitelist[msg.sender], "You are not whitelisted!");
            require(msg.value >= preSaleCost * _mintAmount, "Ether value sent is not correct!");
        }
        else{
            require(msg.value >= cost * _mintAmount, "Ether value sent is not correct!");
        }
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
    }

    if(supply + _mintAmount == maxSupply){
      paused = true;
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

    if(revealed == false){
      return "Not Revealed!";
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function setPresaleCost(uint256 _newCost) public onlyOwner() {
    preSaleCost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function reveal() public onlyOwner{
    revealed = !revealed;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause() public onlyOwner {
    paused = !paused;
  }

  function preSaleActivate() public onlyOwner {
    preSaleActive = !preSaleActive;
  }  
 
  function whitelistUser(address[] memory _user) public onlyOwner {
    for(uint256 i=0; i<_user.length; i++)
      whitelist[_user[i]] = true;
  } 
 
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelist[_user] = false;
  }

  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }

  function getBalance() public view returns(uint) {
    return address(this).balance;
  }
}