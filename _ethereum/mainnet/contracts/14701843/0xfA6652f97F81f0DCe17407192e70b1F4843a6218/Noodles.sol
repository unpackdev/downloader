// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";


contract Noodles is ERC721Enumerable, Ownable {
  using Strings for uint256;

  //NFT Parameters
  string private baseURI;
  string private baseExtension = ".json";
  string private notRevealedUri;
  uint256 public cost;
  uint256 public maxMintAmount;
  bool public paused = true;
  bool public revealed = false;

  //sale states:
  //stage 0: init
  //stage 1: free mint
  //stage 2: pre-sale
  //stage 3: public sale

  uint8 public mintState;

  //stage 1: free mint
  mapping(address => uint8) public addressFreeMintsAvailable;

  //stage 2: presale mint
  mapping(address => uint8) public addressWLMintsAvailable;

  constructor() ERC721("Noodles", "NOODS") {}

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint8 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused, "contract is paused");
    require(_mintAmount > 0, "You have to mint at least 1 NFT!"); //must mint at least 1
    require(mintState <= 3, "Minting is finished!"); //only 3 states
    require(_mintAmount <= maxMintAmount, "Exceeded maximum NFT purchase");
    require(cost * _mintAmount <= msg.value, "Insufficient funds!"); //not enough ETH

    if (mintState == 1){
      //free mint of 1 with 833 spots
          require(supply + _mintAmount <= 836, "Total Free supply exceeded!");
          require(addressFreeMintsAvailable[msg.sender] >= _mintAmount , "Max NFTs exceeded");
          addressFreeMintsAvailable[msg.sender] -= _mintAmount;
    }

    else if (mintState == 2){
      //WL mint of 1, 2, or 3 addresses whitelisted
          require(supply + _mintAmount <= 4436, "Total whitelist supply exceeded!");
          require(addressWLMintsAvailable[msg.sender] >= _mintAmount , "Max NFTs exceeded");
          addressWLMintsAvailable[msg.sender] -= _mintAmount;
    }

    else if (mintState ==3){
      //public mint
          require(supply + _mintAmount <= 5555);
    }

    else {
      assert(false);
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);

    }
  }

  function reserve(uint256 n) public onlyOwner {
    uint supply = totalSupply();
      for (uint256 i = 1; i <= n; i++) {
          _safeMint(msg.sender, supply + i);
      }
  }

  function tokenURI(uint256 tokenId)public view virtual override returns (string memory) {
    require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");

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

   function setState(uint8 _state)public onlyOwner{
       mintState = _state;

     //free mint
     if (mintState==1){
        cost=0 ether;
        maxMintAmount=1;
      }
     //whitelist
     if (mintState==2){
        cost=0.01 ether;
        maxMintAmount=3;
      }
    //public
    if (mintState==3){
        cost=0.01 ether;
        maxMintAmount = 10;
      }
   }

  function unpause() public onlyOwner{
      paused = false;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function addFreeMintUsers(address[] calldata _users) public onlyOwner {
    for (uint i=0;i<_users.length;i++){
      addressFreeMintsAvailable[_users[i]] = 1;
    }
  }

  function addWhitelistUsers(address[] calldata _users) public onlyOwner {
    for (uint i=0;i<_users.length;i++){
      addressWLMintsAvailable[_users[i]] = 3;
    }
  }

  function withdraw() public payable onlyOwner {
    //20% payment split
    (bool hs, ) = payable(0xC35f3F92A9F27A157B309a9656CfEA30E5C9cCe3).call{value: address(this).balance * 20 / 100}("");
    require(hs);

    (bool os, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(os);
  }

}
