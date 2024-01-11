// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract MooginVerseGenesis is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  string public uriPrefix;
  string public uriSuffix = '.json';
  
  uint256 public cost = 0.0029 ether;
  uint256 public maxSupply = 3333;
  uint256 public freeMints = 1010;
  uint256 public freeMintsPerWallet = 10;
  uint256 public freePerTx = 2;
  uint256 public paidPerTx = 5;

  bool public paused = true;

  mapping(address => uint) public freeMintClaimed;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _metadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setUriPrefix(_metadataUri);
    mintForAddress(10, _msgSender());
  }

  // ~~~~~~~~~~~~~~~~~~~~ Modifiers ~~~~~~~~~~~~~~~~~~~~
  modifier mintCompliance(uint256 _mintAmount) {
    if(freeMintClaimed[_msgSender()] < freeMintsPerWallet && totalSupply() <= freeMints) {
      require(_mintAmount > 0 && _mintAmount <= freePerTx, 'Too many mints in one free transaction!');
    } else {
      require(_mintAmount > 0 && _mintAmount <= paidPerTx, 'Too many mints in one transaction!');
    }
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    if(freeMintClaimed[_msgSender()] >= freeMintsPerWallet || totalSupply() >= freeMints) {
      require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    }
    _;
  }

  // ~~~~~~~~~~~~~~~~~~~~ Mint Functions ~~~~~~~~~~~~~~~~~~~~
  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    freeMintClaimed[_msgSender()] += _mintAmount;

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
      require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');

    _safeMint(_receiver, _mintAmount);
  }

  // ~~~~~~~~~~~~~~~~~~~~ Various Checks ~~~~~~~~~~~~~~~~~~~~
    function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  // ~~~~~~~~~~~~~~~~~~~~ onlyOwner Functions ~~~~~~~~~~~~~~~~~~~~

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setFreePerTx(uint256 _amountPerTx) public onlyOwner {
    freePerTx = _amountPerTx;
  }

  function setPaidPerTx(uint256 _amountPerTx) public onlyOwner {
    paidPerTx = _amountPerTx;
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

  function setFreeMints(uint256 _freeQty) public onlyOwner {
    freeMints = _freeQty;
  }

  function setFreeMintsPerWallet(uint256 _freeQty) public onlyOwner {
    freeMintsPerWallet = _freeQty;
  }

  // ~~~~~~~~~~~~~~~~~~~~ Withdraw Functions ~~~~~~~~~~~~~~~~~~~~
  function withdraw() public onlyOwner nonReentrant {
    (bool db, ) = payable(0x0755acA0cF9212A3D20F6d728a9B846BE67f07C9).call{value: address(this).balance * 5 / 100}('');
    require(db);
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
}