// SPDX-License-Identifier: Unlicensed

import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./ERC721R.sol";


pragma solidity >=0.8.15 <0.9.0;
contract MoonSweepers is ERC721r, Ownable, ReentrancyGuard {

  using Strings for uint256;

// ================== Variables Start =======================

  string internal uri;
  string public suffix= ".json";
  string public hiddenMetadataUri = "ipfs://QmSEZCBZVsAH9JC9uLetHTdLZ4HpuRWzpCvJk9WY4e53Bx/hidden.json";
  uint256 public price = 0.015 ether;
  uint256 public supplyLimit = 1097;
  uint256 public maxMintAmountPerTx = 7;
  uint256 public maxLimitPerWallet = 7;
  bool public publicSale = false;
  bool public revealed = false;
  mapping(address => uint256) public mintCountByAccount;

// ================== Variables End =======================  

// ================== Constructor Start =======================

  constructor(
      string memory _uri
  ) ERC721r("Moon Sweepers", "MS", supplyLimit)  {
    seturi(_uri);
    _mintRandom(msg.sender, 1);
  }

// ================== Constructor End =======================

// ================== Mint Functions Start =======================

  function PublicMint(uint256 _mintAmount) public payable {
    
    // Normal requirements 
    require(publicSale, 'The PublicSale is paused!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    require(mintCountByAccount[msg.sender] + _mintAmount <= maxLimitPerWallet, 'Max mint per wallet exceeded!');
    require(msg.value >= price * _mintAmount, 'Insufficient funds!');

    // Mapping update 
    mintCountByAccount[msg.sender] += _mintAmount;

    // Mint
    _mintRandom(_msgSender(), _mintAmount);
  }  

  function Airdrop(uint256 _mintAmount, address destination) public onlyOwner {
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
   _mintRandom(destination, _mintAmount);
  }

// ================== Mint Functions End =======================  

// ================== Set Functions Start =======================

  function ConfigureCollection(string memory _uri, uint256 _costInWEI, uint256 _supplyLimit, uint256 _maxMintAmountPerTx, uint256 _maxLimitPerWallet) public onlyOwner {
     uri = _uri;
     price = _costInWEI;
     supplyLimit = _supplyLimit;
     maxMintAmountPerTx = _maxMintAmountPerTx;
     maxLimitPerWallet = _maxLimitPerWallet;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function seturi(string memory _uri) public onlyOwner {
    uri = _uri;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function togglepublicSale() public onlyOwner {
    publicSale = !publicSale;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setmaxLimitPerWallet(uint256 _maxLimitPerWallet) public onlyOwner {
    maxLimitPerWallet = _maxLimitPerWallet;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setsupplyLimit(uint256 _supplyLimit) public onlyOwner {
    supplyLimit = _supplyLimit;
  }

// ================== Set Functions End =======================

// ================== Withdraw Function Start =======================
  
  function withdraw() public onlyOwner nonReentrant {
      //owner withdraw
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }  

// ================== Withdraw Function End=======================  

// ================== Read Functions Start =======================

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(),suffix))
        : '';
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }

  event ethReceived(address, uint);
    receive() external payable {
        emit ethReceived(msg.sender, msg.value);
    }

// ================== Read Functions End =======================  

}