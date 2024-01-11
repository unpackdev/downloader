// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract DapesFlossClub is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;

  
  mapping(address => uint256) internal NFTRewards;
  mapping(address => uint256) internal ETHRewards;
  mapping(address => bool) public wlClaimed;
  mapping(uint8 => uint256) public rewardMintCounts;
  mapping(uint8 => uint256) public rewardAmounts;
  mapping(uint8 => uint256) public rewardLevels;
  mapping(uint8 => string) public NFTURIs;
  mapping(uint256 => string) public INITREVEALURIs;

  string internal uriPrefix;
  string internal uriSuffix = '.json';
  string internal hiddenMetadataUri;
  string public PROVENANCE_RECORD = "";

  uint256 internal hidden_num = 12345;
  uint256 public cost = 0.1 ether;
  uint256 public wlcost = 0.08 ether;
  uint256 public presaleCost = 0.09 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmountPerTx = 2;
  uint256 public NFTReserve = 2500;
  uint256 public ContractState = 0;

  bool public mintRewardsEnabled = true;

  event eventDistributeReward(uint256 indexed _NFTID, uint8 indexed _LEVEL);

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setHiddenMetadataUri(_hiddenMetadataUri);
    rewardMintCounts[0] = 0;
    rewardMintCounts[1] = 100;
    rewardMintCounts[2] = 100;
    rewardAmounts[0] = 0.2 ether;
    rewardAmounts[1] = 0.5 ether;
    rewardAmounts[2] = 1 ether;
    rewardLevels[0] = 25;
    rewardLevels[1] = 250;
    rewardLevels[2] = 1000;

    _safeMint(_msgSender(), 100);
  }

  // 0 = paused
  // 1 = Pre sale
  // 2 = whitelist Sale
  // 3 = Public Sale

  modifier mintCompliance(uint256 _mintAmount, uint256 _contractState) {
    require(_contractState != 0, 'Contract is paused!');
    require(_contractState == ContractState, 'Invalid mint type!');
    require(_mintAmount != 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount + NFTReserve <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintCountCompliance(uint256 _mintAmount) {
    require(_mintAmount != 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount + NFTReserve <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount, uint256 _contractState) {
    if (_contractState == 1) {
      require(msg.value >= presaleCost * _mintAmount, 'Funds!');
    } else if (_contractState == 2) {
      require(msg.value >= wlcost * _mintAmount, 'Funds!');
    } else {
      require(msg.value >= cost * _mintAmount, 'Funds!');
    }
    _;
  }

  function randomNum(uint256 _mod, uint256 _rand) internal view returns (uint256) {
    uint256 num = (uint256(keccak256(abi.encode(hidden_num, _rand, msg.sender, _mod + 1))) % _mod) + 1;
    return num;
  }


  function assignReward(uint256 _supply, uint256 _num, uint8 _level, uint256 _rewardAmt) internal {
    uint256 num;
    address rewardAdd;
    num = randomNum(_supply, _num);
    rewardAdd = ownerOf(num);
     ETHRewards[rewardAdd] = ETHRewards[rewardAdd] + _rewardAmt;
     emit eventDistributeReward(num, _level);

  }


  function distributeReward(uint256 _mintAmount) internal {
    if (mintRewardsEnabled == true) {
      uint256 rewardMintCount0 = rewardMintCounts[0];
      uint256 rewardMintCount1 = rewardMintCounts[1];
      uint256 rewardMintCount2 = rewardMintCounts[2];
      uint256 rewardLvl0 = rewardLevels[0];
      uint256 rewardLvl1 = rewardLevels[1];
      uint256 rewardLvl2 = rewardLevels[2];

      uint256 supply;
      uint256 num;

      bool checkForReward = false;
      

      hidden_num = uint256(keccak256(abi.encode(hidden_num, msg.sender)));
      
      unchecked {
        if ((rewardMintCount0 + _mintAmount >= rewardLvl0) || (rewardMintCount1 + _mintAmount >= rewardLvl1) || (rewardMintCount2 + _mintAmount >= rewardLvl2)) {
          supply = totalSupply();
          num = randomNum(supply, hidden_num);
        }
      
       assembly { 
          switch or(gt(add(rewardMintCount0, _mintAmount), rewardLvl0), eq(add(rewardMintCount0, _mintAmount), rewardLvl0)) 
          case 1 {
            rewardMintCount0 := sub(add(rewardMintCount0, _mintAmount), rewardLvl0)
            checkForReward := true 
          }
          default {
            rewardMintCount0 := add(rewardMintCount0, _mintAmount)
          }
       }

        rewardMintCounts[0] = rewardMintCount0;

        if (checkForReward) {
          assignReward(supply, num, 0, rewardAmounts[0]);
        }

       assembly { 
          checkForReward := false 
          switch or(gt(add(rewardMintCount1, _mintAmount), rewardLvl1), eq(add(rewardMintCount1, _mintAmount), rewardLvl1)) 
          case 1 {
            rewardMintCount1 := sub(add(rewardMintCount1, _mintAmount), rewardLvl1)
            checkForReward := true 
          }
          default {
            rewardMintCount1 := add(rewardMintCount1, _mintAmount)
          }
       }

        rewardMintCounts[1] = rewardMintCount1;
        if (checkForReward) {
          assignReward(supply, num, 1, rewardAmounts[1]);
        }

       assembly { 
          checkForReward := false 
          switch or(gt(add(rewardMintCount2, _mintAmount), rewardLvl2), eq(add(rewardMintCount2, _mintAmount), rewardLvl2)) 
          case 1 {
            rewardMintCount2 := sub(add(rewardMintCount2, _mintAmount), rewardLvl2)
            checkForReward := true 
          }
          default {
            rewardMintCount2 := add(rewardMintCount2, _mintAmount)
          }
       }

        rewardMintCounts[2] = rewardMintCount2;
        if (checkForReward) {
          assignReward(supply, num, 2, rewardAmounts[2]);
        }

      }
    }
  }


  function whitelistMint(uint256 _mintAmount, bytes32[] memory _merkleProof) public payable mintCompliance(_mintAmount, 2) mintPriceCompliance(_mintAmount, 2)  {
    // Verify whitelist requirements
    require(!wlClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
    wlClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
    distributeReward(_mintAmount);
  }

  function presaleMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount, 1) mintPriceCompliance(_mintAmount, 1) {
    _safeMint(_msgSender(), _mintAmount);
    distributeReward(_mintAmount);
  }


  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount, 3) mintPriceCompliance(_mintAmount, 3) {
    _safeMint(_msgSender(), _mintAmount);
    distributeReward(_mintAmount);
  }
  

  function mintRewardNFTs(uint256 _mintAmount) public payable mintCompliance(_mintAmount, 3) {
    // Verify reward requirements
    require(NFTRewards[_msgSender()] >= _mintAmount, 'Mint amount more than available reward!');
    NFTRewards[_msgSender()] = NFTRewards[_msgSender()] - _mintAmount;
    NFTReserve = NFTReserve - _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }

  function investorMint(uint256 _mintAmount) public payable mintCountCompliance(_mintAmount) {
    require(NFTRewards[_msgSender()] >= _mintAmount, 'Mint amount more than allocated!');
    NFTRewards[_msgSender()] = NFTRewards[_msgSender()] - _mintAmount;
    NFTReserve = NFTReserve - _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }

 
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCountCompliance(_mintAmount) onlyOwner {
    NFTReserve = NFTReserve - _mintAmount;
    _safeMint(_receiver, _mintAmount);
  }


  function claimMyEthReward() public nonReentrant {
    uint256 rewardAmt = ETHRewards[_msgSender()];
    require(rewardAmt > 0, 'No rewards available to claim.');
    require(address(this).balance > rewardAmt, 'No rewards available to claim at this time.');
    ETHRewards[_msgSender()] = 0;
    (bool os, ) = payable(_msgSender()).call{value: rewardAmt}('');
    require(os);
  }


  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
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
    require(_exists(_tokenId), 'ERC721Metadata: URI query for non existent token');
    string memory currentBaseURI;

    currentBaseURI = INITREVEALURIs[_tokenId];
    if (bytes(currentBaseURI).length == 0) {
      if (_tokenId <= 100) {
        currentBaseURI = NFTURIs[0];
      } else {
        currentBaseURI = NFTURIs[uint8(_tokenId / 500) + 1];
      }
    }

    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : string(abi.encodePacked(hiddenMetadataUri, _tokenId.toString(), uriSuffix));
  }


  function setHiddenNum(uint256 _num) public onlyOwner {
    hidden_num = _num;
  }


  function setRewardAmounts(uint8 _RewardLevel, uint256 _RewardAmt) public onlyOwner {
     require(_RewardLevel <= 2, 'Incorrect Reward Level, should be 0, 1, or 2');
       rewardAmounts[_RewardLevel] = _RewardAmt;
  }

  function setRewardLevels(uint8 _RewardLevel, uint256 _RewardMintCount) public onlyOwner {
     require(_RewardLevel <= 2, 'Incorrect Reward Level, should be 0, 1, or 2');
       rewardLevels[_RewardLevel] = _RewardMintCount;
  }


  function showMyNFTReward() public view returns (uint256) {
    return NFTRewards[_msgSender()];
  }
  
  function showMyETHReward() public view returns (uint256) {
    return ETHRewards[_msgSender()];
  }



  function showNFTReward(address _receiver) public view returns (uint256) {
    return NFTRewards[_receiver];
  }
  
  function showETHReward(address _receiver) public view returns (uint256) {
    return ETHRewards[_receiver];
  }

  function setETHRewardforAddress(address _receiver, uint256 _ETHAmount) public onlyOwner {
     require(_ETHAmount <= 3 ether, 'High Ether Amount');
     ETHRewards[_receiver] = ETHRewards[_receiver] + _ETHAmount;
  }

  function setNFTGroupURI(uint8 _groupIndex, string memory _NFTUriPrefix) public onlyOwner {
      NFTURIs[_groupIndex] = _NFTUriPrefix;
  }

  function setNFTRewardforAddress(address _receiver, uint256 _NFTCount) public onlyOwner {
     NFTRewards[_receiver] = NFTRewards[_receiver] + _NFTCount;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }


  function setPROVENANCE_RECORD(string memory _record) public onlyOwner {
    PROVENANCE_RECORD = _record;
  }

  function setReserve(uint256 _reserve) public onlyOwner {
    NFTReserve = _reserve;
  }

  function setWLCost(uint256 _wlcost) public onlyOwner {
    wlcost = _wlcost;
  }

  function setPresaleCost(uint256 _presaleCost) public onlyOwner {
    presaleCost = _presaleCost;
  }

  function setMaxSupply(uint256 _MaxSupply) public onlyOwner {
    require(_MaxSupply >= totalSupply(), 'Incorrect Max Supply');
    maxSupply = _MaxSupply;
  }



  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    require(_maxMintAmountPerTx >= 1, 'Incorrect Max Mint Amount');
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }



  function setContractState(uint256 _state) public onlyOwner {
    ContractState = _state;
  }

  function setMintRewardsEnabled(bool _state) public onlyOwner {
    mintRewardsEnabled = _state;
  }


  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }


  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setINITREVEALUri(string memory _Uri, uint256 _tokenid) public onlyOwner {
    INITREVEALURIs[_tokenid] = _Uri;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
  
  fallback() external{
  }
}
