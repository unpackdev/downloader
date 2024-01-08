// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

// TODO:
// - make upgradable, use a proxy

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract PumpkinSpiceTitties is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.069 ether;
  uint256 public maxSupply;
  uint256 public maxMintAmount = 7;
  bool public paused = true;
  bool public revealed = false;
  string public notRevealedUri;
  mapping(uint256 => string) private _tokenURIMap;

  constructor(
    // Pumpkin Spice Titties
    string memory _name,
    // PST
    string memory _symbol,
    // https://ipfs.io/ipfs/
    string memory _initBaseURI,
    // placeholder: hash of placeholder gif
    string memory _initNotRevealedUri,
    uint256 _maxSupply
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    maxSupply = _maxSupply;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function _getTokenUri(uint256 tokenId) internal view virtual returns (string memory) {
    return _tokenURIMap[tokenId];
  }

  // public
  function mint(uint256 _mintAmount)
    public
    payable 
  {
    require(!paused, "minting paused");
    require(_mintAmount > 0, "cannot mint 0");
    require(_mintAmount <= maxMintAmount || _mintAmount == 69, "max mint: 7");
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "mint amount exceeds maxSupply");

    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount);
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + 1);
      supply = totalSupply();
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i = 0; i < ownerTokenCount; i++) {
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
      "ERC721Metadata: nonexistent token"
    );
    
    string memory currentBaseURI = _baseURI();

    if(revealed == false) {
        return string(abi.encodePacked(currentBaseURI, notRevealedUri, baseExtension));
    }
    // Get token URI value from token URI map
    string memory tokenURIValue = _getTokenUri(tokenId);
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenURIValue, baseExtension))
        : "";
  }

  function isPaused()
    public
    view
    virtual
    returns (bool)
  {
    return paused;
  }

  //only owner
  function reveal() public onlyOwner() {
      revealed = true;
  }
  
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setTokenUriMap(string[] memory _tokenUris) public onlyOwner {
    // For each string, update map with location of string as the tokenID
    uint256 len = _tokenUris.length;
    require(len == maxSupply + 1, "token map greater than supply");

    for (uint i=1; i<_tokenUris.length; i++) {
        _tokenURIMap[i] = _tokenUris[i];
    }
  }

  function updateTokenUri(uint256 tokenID, string memory _tokenUri) public onlyOwner {
    // For each string, update map with location of string as the tokenID
    require(tokenID <= maxSupply);
    _tokenURIMap[tokenID] = _tokenUri;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function withdraw()
    public
    payable
    onlyOwner 
  {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}