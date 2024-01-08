// SPDX-License-Identifier: NONE

// Created by BUNSTER
// RB

pragma solidity ^0.8.7;

import "./OwnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./StringsUpgradeable.sol";

contract RaveBunnies is ERC721EnumerableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
  using StringsUpgradeable for uint256;

  string internal baseURI;
  string internal ipfsBaseURI;
  string internal eggURI = "https://www.ravebunnies.com/meta/egg.json";
  string internal baseExtension = ".json";
  uint256 public cost = 0.056 ether;
  uint256 public privateCost = 0.046 ether;
  uint256 public publicSupply = 3800;
  uint256 public whitelistSupply = 1100;
  uint256 public djSupply = 100;
  uint256 public maxMintAmount = 10;
  bool internal publicMode = false;
  bool internal ipfsMode = false;
  bool internal useWhite = false;
  bool public revealed = false;
  bool public paused = true;
  mapping(address => bool) internal whitelisted;
  mapping(address => bool) internal djs;
  mapping (uint256 => string) internal IPFS_CIDs;

   bool internal _initialized = false;
   function initialize(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) initializer public {
    require(!_initialized);
        _initialized = true;
        eggURI = "https://www.ravebunnies.com/meta/egg.json";
        baseExtension = ".json";
        cost = 0.056 ether;
        privateCost = 0.046 ether;
        publicSupply = 3800;
        whitelistSupply = 1100;
        djSupply = 100;
        maxMintAmount = 10;
        publicMode = false;
        ipfsMode = false;
        useWhite = false;
        revealed = false;
        paused = true;
    __ERC721_init(_name, _symbol);
    __ERC721Enumerable_init();
    __Ownable_init();
    __ReentrancyGuard_init();
    setBaseURI(_initBaseURI);
    //uint256 supply = totalSupply();
    // for (uint256 i = 1; i <= 5; i++) {
    //   _safeMint(msg.sender, supply + i);
    // }
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  // internal
  function _ipfsBaseURI() internal view virtual returns (string memory) {
    return ipfsBaseURI;
  }
  
  // internal
  function _eggURI() internal view virtual returns (string memory) {
    return eggURI;
  }
  
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
  
  function setIpfsBaseURI(string memory _newIpfsBaseURI) public onlyOwner {
    ipfsBaseURI = _newIpfsBaseURI;
  }
  
  function setEggURI(string memory _newEggURI) public onlyOwner {
    eggURI = _newEggURI;
  }
  
  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  
  //only owner
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }
  //only owner
  function setPrivateCost(uint256 _newPrivateCost) public onlyOwner() {
    privateCost = _newPrivateCost;
  }

  function setWhitelistSupply(uint256 _whitelistSupply) public onlyOwner() {
    whitelistSupply = _whitelistSupply;
  }
  
  function setDjSupply(uint256 _djSupply) public onlyOwner() {
    djSupply = _djSupply;
  }
  
  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }

  function setPublicMode(bool _publicMode) public onlyOwner {
    publicMode = _publicMode;
  }
  
  function setIpfsMode(bool _ipfsMode) public onlyOwner {
    ipfsMode = _ipfsMode;
  }
  
  function setUseWhite(bool _useWhite) public onlyOwner {
    useWhite = _useWhite;
  }
  
  function reveal(bool _revealed) public onlyOwner {
    revealed = _revealed;
  }
  
  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setInitialized(bool _initializeBool) public onlyOwner {
    _initialized = _initializeBool;
  }
 
 function whitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = true;
  }
 
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
  }
  
  function addDj(address _user) public onlyOwner {
    djs[_user] = true;
  }
 
  function removeDj(address _user) public onlyOwner {
    djs[_user] = false;
  }
  
  function setTokenCID(uint tokenId, string memory tokenCID) public onlyOwner{
        IPFS_CIDs[tokenId] = tokenCID;
  }

  function setTokenCIDs(uint[] memory tokenIds, string[] memory tokenCIDs) public onlyOwner{
        require(tokenIds.length <= 100, "Limit 100 tokenIds");
        for(uint i = 0; i < tokenIds.length; i++){
            IPFS_CIDs[tokenIds[i]] = tokenCIDs[i];
        }
  }
  
  // public
  function mintBunny(address _to, uint256 _mintAmount) virtual public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    //100 are for the djs, promoters and partners minted in 2 phases
    require(supply + _mintAmount <= publicSupply + whitelistSupply+djSupply);
  
    if (msg.sender != owner()) {
    
    if(djs[msg.sender] != true)
    {
    require(_mintAmount <= maxMintAmount);
    }
    
      if(publicMode != true)
      {
        require(supply + _mintAmount <= whitelistSupply + djSupply);
        if(useWhite == true)
        {
        require(whitelisted[msg.sender] == true);
        }
        
      require(msg.value >= privateCost * _mintAmount);
      }else
      {
      require(msg.value >= cost * _mintAmount);
      }
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
    }
  }
  

  function walletOfOwner(address _owner)
    public
    view
    virtual
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
    string memory currentIpfsBaseURI = _ipfsBaseURI();
    string memory currentEggURI = _eggURI();
    string memory tempTokenURI = "";
    if(revealed != true)
    {
    	tempTokenURI = eggURI;
    }else
    {
	if(ipfsMode != true)
	{
	tempTokenURI = bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : currentEggURI;
	}else
	{
	tempTokenURI = bytes(IPFS_CIDs[tokenId]).length > 0 ? string(abi.encodePacked(currentIpfsBaseURI, IPFS_CIDs[tokenId])) : currentEggURI;
	}
    }
    return tempTokenURI;
  }

  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}
