// SPDX-License-Identifier: MIT

/*
 ___ ___    ___  ______   ____  __ __  ____  __  _  ____  ____    ____   _____
|   T   T  /  _]|      T /    T|  T  |l    j|  l/ ]l    j|    \  /    T / ___/
| _   _ | /  [_ |      |Y  o  ||  |  | |  T |  ' /  |  T |  _  YY   __j(   \_ 
|  \_/  |Y    _]l_j  l_j|     ||  |  | |  | |    \  |  | |  |  ||  T  | \__  T
|   |   ||   [_   |  |  |  _  |l  :  ! |  | |     Y |  | |  |  ||  l_ | /  \ |
|   |   ||     T  |  |  |  |  | \   /  j  l |  .  | j  l |  |  ||     | \    |
l___j___jl_____j  l__j  l__j__j  \_/  |____jl__j\_j|____jl__j__jl___,_j  \___j                                                     
**/                                                              
                                                               
pragma solidity ^0.8.15;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Metavikings is ERC721A, Ownable {
  string public baseURL = 'ipfs://QmWtgU6ibQxUxbX6hgkN7VQ4dsdP23rhWS3zdpLCYfgk6M/';
  bool public startMint = false;
  uint256 public maxFreeMintPerWallet = 1;
  uint256 public maxMintPerTx = 5;
  uint256 public maxFreeMintNumber = 5555;
  uint256 public maxNumber = 5555;
  uint256 public price = 0.005 ether;
  mapping(address => bool) public userFreeMinted;

  constructor() ERC721A('MetaVikings', 'MV') {}

  function freeMint() public {
    uint256 _totalSupply = totalSupply();
    require(msg.sender == tx.origin, 'minting from contract not supported');
    require(startMint, 'mint not started');
    require(_totalSupply + maxFreeMintPerWallet <= maxFreeMintNumber, 'free mint over');
    require(!userFreeMinted[msg.sender], 'only 1 free');
    userFreeMinted[msg.sender] = true;
    _safeMint(msg.sender, maxFreeMintPerWallet);
  }

  function paidMint(uint256 quantity) public payable {
    uint256 _totalSupply = totalSupply();
    require(msg.sender == tx.origin);
    require(startMint, 'mint not started');
    require(_totalSupply + quantity <= maxNumber, 'sold out');
    require(quantity <= maxMintPerTx, 'invalid quantity');
    require(msg.value == quantity * price, 'incorrect eth value');
    _safeMint(msg.sender, quantity);
  }

  function setStartMint(bool _startMint) public onlyOwner {
    startMint = _startMint;
  }

  function setFreeMintNumber(uint256 _freeMintNumber) public onlyOwner {
    maxFreeMintPerWallet = _freeMintNumber;
  }

  function setMaxMintPerTx(uint256 _maxMintPerTx) public onlyOwner {
    maxMintPerTx = _maxMintPerTx;
  }

  function setMaxFreeMintNumber(uint256 _maxFreeMintNumber) public onlyOwner {
    maxFreeMintNumber = _maxFreeMintNumber;
  }

  function setMaxNumber(uint256 _maxNumber) public onlyOwner {
    maxNumber = _maxNumber;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setBaseURL(string memory _baseURL) public onlyOwner {
    baseURL = _baseURL;
  }

  function teamMint(uint256 _quantity) public onlyOwner {
    uint256 _totalSupply = totalSupply();
    require(_totalSupply + _quantity <= maxNumber, 'invalid quantity');
    _safeMint(msg.sender, _quantity);
  }

  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}('');
    require(success);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURL;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function isFreeMint() public view returns (bool) {
    uint256 _totalSupply = totalSupply();
    return ((maxFreeMintNumber > _totalSupply) && ((maxFreeMintNumber - _totalSupply) >= maxFreeMintPerWallet));
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    if (bytes(baseURI).length != 0) {
      string memory url = string(abi.encodePacked(baseURI, _toString(tokenId)));
      return string.concat(url, '.json');
    }

    return '';
  }
}
