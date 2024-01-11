// SPDX-License-Identifier: Unlicensed
// Developer - ReservedSnow

/*
    __  ___      __              __     ______      __    ___          __  __           __    __     ________      __  
   /  |/  /_  __/ /_____ _____  / /_   / ____/___  / /_  / (_)___      \ \/ /___ ______/ /_  / /_   / ____/ /_  __/ /_ 
  / /|_/ / / / / __/ __ `/ __ \/ __/  / / __/ __ \/ __ \/ / / __ \      \  / __ `/ ___/ __ \/ __/  / /   / / / / / __ \
 / /  / / /_/ / /_/ /_/ / / / / /_   / /_/ / /_/ / /_/ / / / / / /      / / /_/ / /__/ / / / /_   / /___/ / /_/ / /_/ /
/_/  /_/\__,_/\__/\__,_/_/ /_/\__/   \____/\____/_.___/_/_/_/ /_/      /_/\__,_/\___/_/ /_/\__/   \____/_/\__,_/_.___/ 
                                                                                                                       
*/


import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ERC721A.sol";


pragma solidity >=0.8.13 <0.9.0;

contract MutantGoblinYachtClub is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

// ================== Variables Start =======================
    
  string public uri;
  string public uriSuffix = ".json";
  string public hiddenMetadataUri = "ipfs://QmRfEaiGRAPjTsytCdtZt3KXGXJNutFSPKFhJcePHw2212/hidden.json";
  uint256 public cost1 = 0 ether;
  uint256 public cost2 = 0.0099 ether;
  uint256 public supplyLimit = 9999;
  uint256 public maxMintAmountPerTx = 20;
  uint256 public maxLimitPerWallet = 100;
  bool public sale = false;
  bool public revealed = false;

// ================== Variables End =======================  

// ================== Constructor Start =======================

  constructor(
    string memory _uri
  ) ERC721A("Mutant Goblin Yacht Club", "MGYC")  {
    seturi(_uri);
  }

// ================== Constructor End =======================

// ================== Mint Functions Start =======================

  function UpdateCost(uint256 _supply) internal view returns  (uint256 _cost) {

      if (_supply < 2001) {
          return cost1;
        }
      if (_supply < supplyLimit){
          return cost2;
        }
  }
  
  function Mint(uint256 _mintAmount) public payable {
    //Dynamic Price
    uint256 supply = totalSupply();
    // Normal requirements 
    require(sale, 'The Sale is paused!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    require(balanceOf(msg.sender) + _mintAmount <= maxLimitPerWallet, 'Max mint per wallet exceeded!');
    require(msg.value >= UpdateCost(supply) * _mintAmount, 'Insufficient funds!');
     
    // Mint
     _safeMint(_msgSender(), _mintAmount);
  }  

  function Airdrop(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
  }

// ================== Mint Functions End =======================  

// ================== Set Functions Start =======================

// reveal
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

// uri
  function seturi(string memory _uri) public onlyOwner {
    uri = _uri;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

// sales toggle
  function setSaleStatus(bool _sale) public onlyOwner {
    sale = _sale;
  }

// max per tx
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

// pax per wallet
  function setmaxLimitPerWallet(uint256 _maxLimitPerWallet) public onlyOwner {
    maxLimitPerWallet = _maxLimitPerWallet;
  }

// price

  function setcost1(uint256 _cost1) public onlyOwner {
    cost1 = _cost1;
  }  

  function setcost2(uint256 _cost2) public onlyOwner {
    cost2 = _cost2;
  }  

// supply limit
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
 
  function price() public view returns (uint256){
         if (totalSupply() < 2001) {
          return cost1;
          }
         if (totalSupply() < supplyLimit){
          return cost2;
        }

  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= supplyLimit) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }

      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }

// ================== Read Functions End =======================  

}