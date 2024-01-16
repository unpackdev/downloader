// SPDX-License-Identifier: MIT

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

pragma solidity ^0.8.7;

contract ExoGirls is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  uint256 public cost = 0.005 ether;
  uint256 public maxSupply = 222;
  uint256 public maxMintAmount = 2;
  uint256 public maxPerTxn = 2;
  
  bool public mintOpen = false;

  constructor(
      string memory _tokenName,
      string memory _tokenSymbol,
      string memory _metadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
      setUriPrefix(_metadataUri);
      _safeMint(0xd20d9Ce882e43FC67776209cd6FB51dE34B3a107, 1);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(mintOpen, "The contract is not open for minting!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply minted.");
    require(_mintAmount > 0 && _mintAmount <= maxPerTxn, "Mint amount exceeds per transaction limit.");
    require(tx.origin == msg.sender, "Calling from another contract is not allowed.");
    require(
      _mintAmount > 0 && numberMinted(msg.sender) + _mintAmount <= maxMintAmount,
       "Invalid mint amount or minted max amount!"
    );
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
    maxMintAmount = _maxMintAmount;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setMintState(bool _state) public onlyOwner {
    mintOpen = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    uint256 contractBalance = address(this).balance;
    (bool hs, ) = payable(0xd20d9Ce882e43FC67776209cd6FB51dE34B3a107).call{
        value: (contractBalance * 85) / 100
    }("");
    (bool os, ) = payable(owner()).call{
        value: (contractBalance * 15) / 100
    }("");
     require(hs && os, "Withdraw failed");
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}