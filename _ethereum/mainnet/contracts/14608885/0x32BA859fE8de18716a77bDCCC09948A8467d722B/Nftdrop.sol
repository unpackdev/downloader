// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Nftdrop is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 55000000000000000 wei;
  uint256 public maxSupply = 5555;
  uint256 public maxMintAmount = 5;
  uint256 public maxSupplyPresale = 555;
  mapping (address => bool) public whitelistedAdresses;
  bool onlyWhitelisted = true;
  bool paused = true;
  bool revealed = false;
  string public notRevealedUri;

  constructor(string memory _name, string memory _symbol, string memory _initNotRevealedUri) ERC721(_name, _symbol)
  {
    setNotRevealedURI(_initNotRevealedUri);
  }
  // internal
  function _baseURI() internal view virtual override returns (string memory)
  {
    return baseURI;
  }
  // public
  function mint(uint256 _mintAmount) public payable
  {
    require(!paused);
    uint256 supply = totalSupply();
    if (msg.sender != owner()) {
      if(onlyWhitelisted) {
        require(whitelistedAdresses[msg.sender] == true, "Address is not whitelisted");
        require(supply + _mintAmount <= maxSupplyPresale, "Presale Sold Out");
      }
      require(msg.value >= cost * _mintAmount,"Less then min cost");
    }
    require(_mintAmount > 0, "Mint at least 1 NFT");
    require(_mintAmount <= maxMintAmount, "You can not mint more than maxMintAmount");
    require(supply + _mintAmount <= maxSupply, "Sale Sold Out");
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender,supply+i);
    }
  }
  function mintOnAddress(address _user,uint256 amount) public onlyOwner
  {
    uint256 supply = totalSupply();
    require(amount <= maxMintAmount);
    for (uint256 i = 1; i <= amount; i++) {
      _safeMint(_user,supply+i);
    }
  }
  function walletOfOwner(address _owner) public view returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
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
  function reveal(string memory _newBaseURI) public onlyOwner()
  {
    require(!revealed, "Already revealed");
    setBaseURI(_newBaseURI);
    revealed = true;
  }
  function getReveal() public view returns (bool)
  {
    return revealed;
  }
  function setCost(uint256 _newCost) public onlyOwner()
  {
    cost = _newCost;
  }
  function setMaxOneMint(uint256 _newMaxMintAmount) public onlyOwner()
  {
    maxMintAmount = _newMaxMintAmount;
  }
  function setMaxMintAmount(uint256 _newMaxSupply) public onlyOwner()
  {
    maxSupply = _newMaxSupply;
  }
  function setMintAmountPresale(uint256 _newMaxSupplyPresale) public onlyOwner()
  {
    maxSupplyPresale = _newMaxSupplyPresale;
  }
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner()
  {
    notRevealedUri = _notRevealedURI;
  }
  function setBaseURI(string memory _newBaseURI) public onlyOwner()
  {
    baseURI = _newBaseURI;
  }
  function setBaseExtension(string memory _newBaseExtension) public onlyOwner()
  {
    baseExtension = _newBaseExtension;
  }
  function setPause(bool _state) public onlyOwner()
  {
    paused = _state;
  }
  function getPause() public view returns (bool)
  {
    return paused;
  }
  function setPreSale(bool _state) public onlyOwner()
  {
    onlyWhitelisted = _state;
  }
  function getPreSale() public view returns (bool)
  {
    return onlyWhitelisted;
  }
  function removeWhitelistedAddress(address[] memory _users) public onlyOwner()
  {
    for(uint256 i = 0; i< _users.length;i++){
      delete whitelistedAdresses[_users[i]];
    }
  }
  function addWhitelistUsersOrUpdate(address[] memory _users,bool whitelisted) public onlyOwner()
  {
    for(uint256 i = 0; i< _users.length;i++){
      whitelistedAdresses[_users[i]]=whitelisted;
    }
  }
  function withdraw() public onlyOwner()
  {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}
