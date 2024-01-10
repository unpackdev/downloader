// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721Burnable.sol";
contract AntiApeAssociation is ERC721, Ownable, ERC721Burnable {
  using Strings for uint256;
  using Counters for Counters.Counter;
  
  Counters.Counter private supply;
   
  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri="";
  uint256 public cost = 0.1 ether;
  uint256 public maxSupply = 11111;
  uint256 public presaleSupply=4444;
  uint256 public maxMintAmount = 50;
  
   bool public onlyWhitelisted = true;
  address[] public whitelistedAddresses;
  bool public presale=true;
  bool public paused = false;
  bool public revealed = false;
 

  mapping(address => uint256) public addressMintedBalance;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _notRevealedUri
  
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedBaseURI(_notRevealedUri);
   
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  function totalSupply() external view returns (uint256) {
    return supply.current();
  }
  function burnForOwner(address owner,uint256 tokenCount)public onlyOwner{
   uint256 ownerTokenCount= balanceOf(owner);
   uint256 start=0;
   while(ownerTokenCount!=start){
     if(ownerOf(start+1)==owner){
       start+=1;
       if(start==tokenCount){
         return;
       }
       burn(start);
     }
   }
  }
  function presaleMint(uint256 _mintAmount)public payable {
    require(!paused, "the contract is paused");
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    require(supply.current() + _mintAmount <= presaleSupply, "max NFT limit exceeded");
  
    if (msg.sender != owner()) {
         uint256 ownerMintedCount = addressMintedBalance[msg.sender];
           if(!onlyWhitelisted){
               uint256 wlCount=checkWhitelist(msg.sender);
               require(ownerMintedCount + _mintAmount <= wlCount, "max NFT per address exceeded");
           }
           
          require(msg.value >= cost * _mintAmount, "insufficient funds");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
       supply.increment();
      _safeMint(msg.sender, supply.current());
     
    }
  }
  
  function mint(uint256 _mintAmount) public payable {
    require(!presale,"still presale try later");
    require(!paused, "the contract is paused");
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    require(supply.current() + _mintAmount <= maxSupply, "max NFT limit exceeded");
  
    if (msg.sender != owner()) {
         uint256 ownerMintedCount = addressMintedBalance[msg.sender];
           if(!onlyWhitelisted){
             
               uint256 wlCount=checkWhitelist(msg.sender);
               require(ownerMintedCount + _mintAmount <= wlCount, "max NFT per address exceeded");
           }
          
          require(msg.value >= cost * _mintAmount, "insufficient funds");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
       supply.increment();
      _safeMint(msg.sender, supply.current());
     
    }
  }

 function checkWhitelist(address _user) public view returns (uint256) {
   uint count=0;
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          count++;
      }
    }
    if(count==0){
      return 0;
    }
    else if(count==1){
      return 4;
    }
     else if(count==2){
      return 10;
    }
     else if(count==3){
      return 15;
    }
    else if(count==4){
      return 50;
      //COLLECTOR
    }
    else{
      return 0;
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
  

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
  function setNotRevealedBaseURI(string memory _notRevealedUri) public onlyOwner {
    notRevealedUri = _notRevealedUri;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  


  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
   
 
 function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }
  
  function offPresale(bool _state) public onlyOwner {
    presale = _state;
  }
  
  function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }
 
  function withdraw() public payable onlyOwner {
   
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}