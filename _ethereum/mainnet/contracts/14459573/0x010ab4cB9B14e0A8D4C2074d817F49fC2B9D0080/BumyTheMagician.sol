// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract BumyTheMagician is ERC721, Ownable, ReentrancyGuard {

  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "ipfs://QmcR7DuWSCy6kPiatXw9gWBuQ2CKpZ4zn3A6yo4svGXGEi/";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;

  uint256 private costBumylist = 0.015 ether;
  uint256 public startDate = 1648314000;
  uint256 public weekSupply = 190;
  uint256 public cost = 0.08 ether; 
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmountPerTx = 25;
  uint256 public maxMintAmountPerWL = 5;
  uint256 public weekNum = getWeek();
  uint256 public maxMintAmount = 20;

  uint tokenId = 1;
  bytes32 private root;

  bool public onlyBumylisted = true;
  bool public paused = false;
  bool public revealed = true;

  address private devAdr = 0x201732639EDd8952BA75feF95677dCE3562Ca0b2;
  mapping(address => uint256) public addressMintedBalance;

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0, "Invalid mint amount");
    require(totalMinted() + _mintAmount <= maxSupply, "Max supply exceeded");
    _;
  }

  constructor(bytes32 merkleroot) ERC721("BumyTheMagician", "BTM") {
    setHiddenMetadataUri("ipfs://QmZyadxSGnDzYpppoDvoHW4NdYXD6xJtcGcpx7TCWTjQUx/hidden.json");
    root = merkleroot;
  }

  function mintNFT(address account, bytes32[] calldata proof, uint256 _mintAmount) external payable mintCompliance(_mintAmount) {
    if (msg.sender != owner()) {
      require(!paused, "The contract is paused!");
      if(onlyBumylisted == true) {
        require(isWhiteListed(account, proof), "Not on the Bumylist");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + _mintAmount <= maxMintAmountPerWL, "Max NFT per Bumylist member exceeded"); 
        require(msg.value >= costBumylist * _mintAmount, "Insufficient funds");
      }
      else {
        require(msg.value >= cost * _mintAmount, "Insufficient funds");
      }
      require(totalMinted() + _mintAmount <= weekSupply * weekNum, "Weekly supply exceeded");
      require(_mintAmount <= maxMintAmountPerTx, "Invalid mint amount"); 
    }
    _mintLoop(msg.sender, _mintAmount);
  }

  function isWhiteListed(address account, bytes32[] calldata proof) public view returns(bool) {
    return _verify(_leaf(account), proof);
  }

  function _leaf(address account) internal pure returns(bytes32) {
    return keccak256(abi.encodePacked(account));
  }

  function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns(bool) {
    return MerkleProof.verify(proof, root, leaf);
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  } 

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
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

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = uriPrefix;
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function getWeek() public view returns (uint256) {
    uint256 mintDate = block.timestamp;
    uint256 week = 0;
    uint256 i = 1;
    if (mintDate >= startDate + 53*604800) {
      week = 53;
    }
    else if (mintDate >= startDate) {
      while (mintDate >= startDate + (i-1)*604800) {
        week = i;
        i++;
      }       
    }
    return week;
  }

  function totalMinted() public view returns (uint256) {
    return supply.current();
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setBumylistCost(uint256 _costBumylist) public onlyOwner {
    costBumylist = _costBumylist;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setMaxMintAmountPerWL(uint256 _limit) public onlyOwner {
    maxMintAmountPerWL = _limit;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setOnlyBumylisted(bool _state) public onlyOwner {
    onlyBumylisted = _state;
  }

  function setReveal(bool _state) public onlyOwner {
      revealed = _state;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setWeekNum(uint256 _weekNum) public onlyOwner {
    weekNum = _weekNum;
  }

  function setStartDate(uint256 _startDate) public onlyOwner {
    startDate = _startDate;
  }

  function setMerkle(bytes32 _root) public onlyOwner {
    root = _root;
  }

  function setWeekSupply(uint256 _weekSupply) public onlyOwner {
    weekSupply = _weekSupply;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function withdraw() public onlyOwner nonReentrant() {
    (bool hs, ) = payable(devAdr).call{value: address(this).balance * 20 / 100}("");
    require(hs, "Failed to send ETH");

    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os, "Failed to send ETH");
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, totalMinted());
    }
  }

}