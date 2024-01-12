// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol"; 
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract TinyDuckies is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI = '';
  string public uriSuffix = '.json';
  uint256 public maxSupply = 1111;
  uint256 public maxMintAmount = 10;
  uint256 public price = 0.01 ether;

  bool public paused = true;

  constructor() 
    ERC721A("TinyDuckies", "TDUCKS") {
    
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(!paused, "The contract is paused!");
    require(_mintAmount > 0, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(_mintAmount <= maxMintAmount, "Max per TX reached!");
    require(msg.value >= price * _mintAmount, "Insufficient funds!");
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _safeMint(_receiver, _mintAmount);
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
    maxMintAmount = _maxMintAmount;
  }

  function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

  function setBaseURI(string calldata baseURI_) public onlyOwner {
    baseURI = baseURI_;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function toggleMint() public onlyOwner {
    paused = !paused;
  }

  function isPaused() public view returns (bool) {
    return paused;
  }

  function withdraw() public onlyOwner nonReentrant {
    uint256 amount = address(this).balance * 50 / 100;
    (bool m, ) = payable(0x3ca5fC388870c78a1Ae898B1A0cAFDd2653f37A6).call{value: amount}('');
    require(m);

    (bool d, ) = payable(owner()).call{value: address(this).balance}('');
    require(d);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
}