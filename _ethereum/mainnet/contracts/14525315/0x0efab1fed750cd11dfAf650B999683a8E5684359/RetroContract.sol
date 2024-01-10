// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract RetroverseContract is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  uint256 public cost = 0.03 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmountPerTx = 1;

  bool public paused = false;
  bool public revealed = false;
  uint256 public index = 0;
  bool public discountEnabled = true;
  address[] public discountedAddresses50;
  address[] public discountedAddresses75;
  address[] public discountedAddresses100;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _uriPrefix ,
    string memory _hiddenMetadataUri
  ) ERC721(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    uriPrefix = _uriPrefix ;
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  //  Mint
  function mint(uint256 _mintAmount ) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    require(_mintAmount == 1, "Max mint amount should be 1");

    if (discountEnabled && isDiscounted100(msg.sender)){
          for (uint256 i = 0; i < discountedAddresses100.length; i++) {
          if (discountedAddresses100[i] == msg.sender) {
            delete discountedAddresses100[i];
          }
        }
      require(msg.value >= cost * 0, "Wrong minting value");
      _mintLoop(msg.sender, _mintAmount);
    }
    else if(discountEnabled && isDiscounted75(msg.sender)){
          for (uint256 i = 0; i < discountedAddresses75.length; i++) {
          if (discountedAddresses75[i] == msg.sender) {
            delete discountedAddresses75[i];
          }
        }
      require(msg.value >= (cost * 3)/4, "Wrong minting value");
        _mintLoop(msg.sender, _mintAmount);
    }
    else if(discountEnabled && isDiscounted50(msg.sender)){
          for (uint256 i = 0; i < discountedAddresses50.length; i++) {
          if (discountedAddresses50[i] == msg.sender) {
            delete discountedAddresses50[i];
          }
        }
      require(msg.value >= (cost * 1)/2 , "Wrong minting value");
      _mintLoop(msg.sender, _mintAmount);
    }
    else {
      require(msg.value >= cost , "Wrong minting value");
      _mintLoop(msg.sender, _mintAmount);
    }
  }

  function mintOwner(uint256 _mintAmount) public  onlyOwner {
        require(!paused, "The contract is paused!");
        _mintLoop(msg.sender, _mintAmount);
  }

  function burn (uint256 token_id) public onlyOwner {
    require(!paused, "The contract is paused!");
    require(token_id > 0 && token_id <= supply.current(), "Invalid token id!");
    _burn(token_id);
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);
      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;
        ownedTokenIndex++;
      }
      currentTokenId++;
    }
    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setDiscountEnabled(bool _state) public onlyOwner {
    discountEnabled = _state;
  }

  function deleteFullList50() public onlyOwner {
    delete discountedAddresses50;
  }

  function addOneToList50(address _user) public onlyOwner {
    discountedAddresses50.push(_user);
  }

  function deleteOneFromList50(address _user) public onlyOwner {
    for (uint256 i = 0; i < discountedAddresses50.length; i++) {
      if (discountedAddresses50[i] == _user) {
        delete discountedAddresses50[i];
      }
      else {
        revert("Failed to find address.");
      }
    }
  }

  function isDiscounted50(address _user) view public returns (bool) {
    for (uint256 i = 0; i < discountedAddresses50.length; i++) {
      if (discountedAddresses50[i] == _user) {
        return true;
      }
    }
    return false;
  }

  function deleteFullList75() public onlyOwner {
    delete discountedAddresses75;
  }

  function addOneToList75(address _user) public onlyOwner {
    discountedAddresses75.push(_user);
  }

  function deleteOneFromList75(address _user) public onlyOwner {
    for (uint256 i = 0; i < discountedAddresses75.length; i++) {
      if (discountedAddresses75[i] == _user) {
        delete discountedAddresses75[i];
      }
      else {
        revert("Failed to find address.");
      }
    }
  }

  function isDiscounted75(address _user) view public returns (bool) {
    for (uint256 i = 0; i < discountedAddresses75.length; i++) {
      if (discountedAddresses75[i] == _user) {
        return true;
      }
    }
    return false;
  }


  function deleteFullList100() public onlyOwner {
    delete discountedAddresses100;
  }

  function addOneToList100(address _user) public onlyOwner {
    discountedAddresses100.push(_user);
  }

  function deleteOneFromList100(address _user) public onlyOwner {
    for (uint256 i = 0; i < discountedAddresses100.length; i++) {
      if (discountedAddresses100[i] == _user) {
        delete discountedAddresses100[i];
      }
      else {
        revert("Failed to find address.");
      }
    }
  }

  function isDiscounted100(address _user) view public returns (bool) {
    for (uint256 i = 0; i < discountedAddresses100.length; i++) {
      if (discountedAddresses100[i] == _user) {
        return true;
      }
    }
    return false;
  }

  function getCost(address _wallet) view public returns (uint256) {
    if (isDiscounted100(_wallet)){
      return 0;
    }
    else if(isDiscounted75(_wallet)){
      return (cost * 3)/4;
    }
    else if(isDiscounted50(_wallet)){
      return (cost * 1)/2 ;
    }
    else {
      return cost ;
    }
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}