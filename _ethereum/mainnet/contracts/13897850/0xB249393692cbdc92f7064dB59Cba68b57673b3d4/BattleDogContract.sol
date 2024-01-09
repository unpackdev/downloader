// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.7.0 <0.9.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

contract BattleDogContract is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public notRevealedUri;

  uint256 public cost = 0.06 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmount = 5;
  uint256 public WhiteListMaxMintAmount = 3;

  bool public  allowAllMint = false;
  bool public revealed = false;
  bool public onlyWhiteListMint = false;

  address[] public whitelistedAddresses;

  mapping(address => uint256) public addressMintedBalance;
  mapping(address => uint256) public whiteListAddressMintedBalance;


  constructor(string memory _initBaseURI, string memory _initNotRevealedUri) 
  ERC721("BattleDog", "BD") {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(msg.value >= cost * _mintAmount, "Ether value sent is not correct");
    if (msg.sender != owner()) {
        if( onlyWhiteListMint == true &&  allowAllMint == false) {
            require(isWhitelisted(msg.sender), "user is not whitelisted");
            require(checkMintBalnce(msg.sender, _mintAmount), "you canct mint that much");
            whiteListAddressMintedBalance[msg.sender] = whiteListAddressMintedBalance[msg.sender] + _mintAmount;
        }
        else{
          require( allowAllMint, "the contract is paused");
          require(checkMintBalnce(msg.sender,_mintAmount));
          require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
          addressMintedBalance[msg.sender] = addressMintedBalance[msg.sender] + _mintAmount;
        }
    }
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function checkMintBalnce(address _user, uint256 _mintAmount) public view returns (bool) {
    if( onlyWhiteListMint == true &&  allowAllMint == false){
      if (whiteListAddressMintedBalance[_user]+_mintAmount <= WhiteListMaxMintAmount){
        return true;
      } 
      return false;
    }
    else{
       if (addressMintedBalance[_user]+_mintAmount <= maxMintAmount){
        return true;
      } 
      return false;
    }
  }
  
  
  function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }
  
  
  function ownerMint() public onlyOwner{
    uint256 supply = totalSupply();
    for (uint256 i = 1; i <= 25; i++) {
        _safeMint(msg.sender, supply + i);
    }    
  }


  function walletOfOwner()public view returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(owner());
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(owner(), i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)public view virtual override returns (string memory)
  {
    require(_exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token");
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
        : "";
  }
  
  function reveal(bool _state) public onlyOwner {
    revealed = _state;
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
  
  function setWhitelistUsers(address[] memory _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }
  function addWhitList(address[] memory _users)public onlyOwner{
     for (uint i=0; i < _users.length; i++) {
            whitelistedAddresses.push(_users[i]);
        }
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function  setAllowAllMint(bool _state) public onlyOwner {
    allowAllMint = _state;
  }
  
  function setOnlyWhiteListMint(bool _state) public onlyOwner {
    onlyWhiteListMint = _state;
  }
  
  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}