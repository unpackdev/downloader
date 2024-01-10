// SPDX-License-Identifier: MIT AND GPL-3.0
pragma solidity ^0.8.0;

import "./ERC721A_METASTORE.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

interface IStateTunnel {
    function sendTransferMessage(bytes calldata _data) external;
}

error PayComissionFailed();
error NonValidRandomWords(uint256 randomNumber);
contract MetaStoreNFT is ERC721A_METASTORE, VRFConsumerBaseV2, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public publicSalePrice = 0.188 ether;
  uint256 public publicSaleTime;
  uint256 public preSalePrice = 0.168 ether;
  uint256 public preSaleTime;
  uint256 public maxTeamReverseNum = 200;
  uint256 public maxMetaStoreSupply = 6666; // available 6666 - 200 = 6466
  uint256 public maxMergeNum = 2222; // 6666 / 3 = 2222
  uint256 public maxTotalSupply = maxMetaStoreSupply + maxMergeNum;
  uint256 public maxMintAmount = 20;
  uint256 public nftPerAddressLimit = 1;
  
  bool public paused = false;
  bool public mergeIsOpen = false;
  bool public isPreSaleActive = false;
  bool public isPublicSaleActive = false;

  bool private isStateTunnelEnable = false;
  IStateTunnel private stateTunnel;

  event SetTokenLevel(uint16 tokenId, uint8 level);
  uint8[] levelList = [0]; // index 0 is un-used
  mapping(uint16 => uint8) mergedTokenLevelMap;
  uint8 public mergedBonusLevel = 3;

  constructor(
    address _vrfCoordinator,
    address _link,
    string memory _name,
    string memory _symbol
  ) ERC721A_METASTORE(_name, _symbol) VRFConsumerBaseV2(_vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(_link);
    teamReserve(1);
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _startMergeTokenId() internal view override returns (uint256) {
    return maxMetaStoreSupply + 1;
  }

  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal override {
    if(isStateTunnelEnable) {
      bytes memory parameter = abi.encode(from, to, startTokenId, quantity);
      stateTunnel.sendTransferMessage(parameter);
    }
  }

  function encode(address _receiver, uint256 tokenId, address newOwner) internal view returns (bytes memory) {
    bytes memory parameter = abi.encode(tokenId, newOwner);
    bytes memory data = abi.encode(msg.sender, _receiver, parameter);
    return data;
  }

  function currentIndex() public view returns (uint256) {
    return _currentIndex;
  }

  function currentMergedIndex() public view returns (uint256) {
    return _currentMergedIndex;
  }

  function teamReserve(uint256 _mintAmount) public onlyOwner {
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(!paused, "the mint is open");
    require(
      _numberMinted(owner()) + _mintAmount <= maxTeamReverseNum,
      "exceeds max team reversed NFTs"
    );
    require(totalNormalMinted() + _mintAmount <= maxMetaStoreSupply, "exceeds max supply");
    bool allowCommission = true;
    _safeMint(owner(), _mintAmount, allowCommission);
  }

  function preSaleMint(uint256 _mintAmount, bytes32[] calldata proof_) public payable {
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(block.timestamp >= preSaleTime, "not pre-sale time yet");
    require(tx.origin == msg.sender, "contracts not allowed");
    require(!paused, "the contract is paused");
    require(isPreSaleActive, "minting not enabled");
    require(totalNormalMinted() + _mintAmount <= maxMetaStoreSupply, "exceeds max supply");
    require(
      _numberMinted(msg.sender) + _mintAmount <= nftPerAddressLimit,
      "exceeds max available NFTs per address"
    );
    require(checkAllowlist(proof_), "address is not on the whitelist");

    uint256 cost = preSalePrice * _mintAmount;
    require(msg.value == cost, "wrong payment amount");
    bool allowCommission = true;
    _safeMint(msg.sender, _mintAmount, allowCommission);
  }

  function publicMint(uint256 _mintAmount, uint16 _invitationCode) public payable {
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    require(block.timestamp >= publicSaleTime, "It is not public sale time");
    require(tx.origin == msg.sender, "contracts not allowed");
    require(!paused, "the contract is paused");
    require(isPublicSaleActive, "minting not enabled");
    require(totalNormalMinted() + _mintAmount <= maxMetaStoreSupply, "exceeds max supply");

    uint256 cost = publicSalePrice * _mintAmount;
    require(msg.value == cost, "wrong payment amount");
    bool allowCommission = false;
    _safeMint(msg.sender, _mintAmount, allowCommission);

    TokenOwnership memory _ownership = _ownershipOf(_invitationCode);
    require(_ownership.allowCommission, "wrong invitation code");
    uint256 commission = cost * 10 / 100; // commission is 10%
    require(commission < cost, "commission error");
    (bool success, ) = payable(_ownership.addr).call{ value: commission }("");
    require(success, "failed to pay commission");
  }
  
  function merge(uint16[3] calldata tokenIDs) public returns (uint16) {
    require(mergeIsOpen, "the merge is not open");
    require(totalMergedMinted() <= maxMergeNum, "excceed max merge amount");
    require(tokenIDs.length == 3, "need 3 NFTs");
    require(tokenIDs[0] != tokenIDs[1] && tokenIDs[0] != tokenIDs[2] && tokenIDs[1] != tokenIDs[2], "tokenIDs must be different");
    require(ownerOf(tokenIDs[0]) == msg.sender, "tokenIDs must be owned");
    require(ownerOf(tokenIDs[1]) == msg.sender, "tokenIDs must be owned");
    require(ownerOf(tokenIDs[2]) == msg.sender, "tokenIDs must be owned");
    
    require(tokenIDs[0] <= maxMetaStoreSupply, "tokenIDs must be valid");
    require(tokenIDs[1] <= maxMetaStoreSupply, "tokenIDs must be valid");
    require(tokenIDs[2] <= maxMetaStoreSupply, "tokenIDs must be valid");


    uint8 newLevel = 0;
    for (uint256 i = 0; i < tokenIDs.length; i++) {
        newLevel += tokenLevel(tokenIDs[i]);
        _burn(tokenIDs[i], true);
    }
    newLevel += mergedBonusLevel;

    bool allowCommission = true;
    _safeMergeMint(msg.sender, allowCommission);

    uint16 tokenId = uint16(_currentMergedIndex - 1);
    mergedTokenLevelMap[tokenId] = newLevel;

    return tokenId;
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
      "ERC721Metadata: URI query for nonexistent token"
    );
    return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function tokenLevel(uint16 _tokenId) public view returns (uint8) {
    require(_exists(uint256(_tokenId)), "ERC721Metadata: token level query for nonexistent token");
    if(isMergedToken(_tokenId)) {
      return mergedTokenLevelMap[_tokenId];
    }
    require(levelList[_tokenId] > 0, "Still not be revealed yet");
    return levelList[_tokenId];
  }

  // VRF
  VRFCoordinatorV2Interface COORDINATOR;
  LinkTokenInterface LINKTOKEN;
  uint64 s_subscriptionId;
  bytes32 keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

  uint32 callbackGasLimit = 1000000;
  uint16 requestConfirmations = 3;
  uint256[] public s_randomWords;
  uint256 public s_requestId;

  function setSubscriptionId(uint64 subscriptionId) public onlyOwner {
    s_subscriptionId = subscriptionId;
  }

  function setKeyHash(bytes32 _keyHash) public onlyOwner {
    keyHash = _keyHash;
  }

  function setVrfCallbackGasLimit(uint32 _callbackGasLimit) public onlyOwner {
    callbackGasLimit = _callbackGasLimit;
  }

  function requestRandomWords(uint32 numWords) external onlyOwner {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }

  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
  }

  // Reveal
  uint16 public unrevealAmount = uint16(maxMetaStoreSupply);
  function isAllTokenRevealed() public view returns (bool) {
    return unrevealAmount == 0;
  }

  function revealTokenLevel(uint16 amount, uint8 ridx) external onlyOwner {
    require(s_randomWords[ridx] > 0, "random word is not set");
    require(amount > 0, "amount must be greater than 0");
    require(!isAllTokenRevealed(), "All tokens are revealed");
    uint16 start = uint16(maxMetaStoreSupply) - unrevealAmount + 1;
    uint16 end = start + amount - 1;
    for (uint16 tokenId = start; tokenId <= end; tokenId++) {
        uint256 rn = uint256(keccak256(abi.encode(s_randomWords[ridx], tokenId)));
        uint8 level = getRandomLevel(rn);
        levelList.push(level);
        emit SetTokenLevel(tokenId, level);
    }
    unrevealAmount -= amount;
  }

  function getRandomLevel(uint256 randomNumber) internal pure returns (uint8) {
      uint256 raw = (randomNumber % 100000);
      if(raw < 45000) { // 45%
        return 1;
      } else if(raw < 75000) { // 30%
        return 2;
      } else if(raw < 90000) { // 15%
        return 3;
      } else if(raw < 97500) { // 7.5%
        return 4;
      } else if(raw < 100000) { // 2.5%
        return 5;
      } else {
        revert NonValidRandomWords(randomNumber);
      }
  }


  //only owner
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }

  function setPreSalePrice(uint256 _newPreSalePrice) public onlyOwner {
    preSalePrice = _newPreSalePrice;
  }

  function setPublicSalePrice(uint256 _newPublicSalePrice) public onlyOwner {
    publicSalePrice = _newPublicSalePrice;
  }

  function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
    maxMintAmount = _newMaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setPause(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMergeMode(bool _state) public onlyOwner {
    mergeIsOpen = _state;
  }
  
  function setIsPreSaleActive(bool _state) public onlyOwner {
    isPreSaleActive = _state;
  }

  function setIsPublicSaleActive(bool _state) public onlyOwner {
    isPublicSaleActive = _state;
  }
  
  function setPublicSaleTime(uint256 _publicSaleTime) external onlyOwner {
    publicSaleTime = _publicSaleTime;
  }

  function setPreSaleTime(uint256 _preSaleTime) external onlyOwner {
    preSaleTime = _preSaleTime;
  }

  function setMergedBonusLevel(uint8 _mergedBonusLevel) public onlyOwner {
    mergedBonusLevel = _mergedBonusLevel;
  }
 
  function withdraw(uint256 amount) public onlyOwner {
    require(amount <= address(this).balance, "Not enough balance");
    uint256 halfBalance = address(this).balance * 5 / 10;
    (bool success1, ) = payable(0xAB35A2578c26314b9244831bdB4B044Cd1DBA4E0).call{ value: halfBalance }("");
    (bool success2, ) = payable(0x85587426C2154AB3c43452a7D8E8ee40020A2900).call{ value: halfBalance }("");
    require(success1, "failed to withdraw money (1)");
    require(success2, "failed to withdraw money (2)");
  }

  function setStateTunnel(address _stateTunnel) public onlyOwner {
    stateTunnel = IStateTunnel(_stateTunnel);
  }

  function setStateTunnelEnabled(bool _enabled) public onlyOwner {
    isStateTunnelEnable = _enabled;
  }



  //
  bytes32 private merkleRoot;
  function checkAllowlist(bytes32[] calldata proof)
    public
    view
    returns (bool)
  {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    return MerkleProof.verify(proof, merkleRoot, leaf);
  }

  function checkAllowlist(address addr, bytes32[] calldata proof)
    public
    view
    returns (bool)
  {
    bytes32 leaf = keccak256(abi.encodePacked(addr));
    return MerkleProof.verify(proof, merkleRoot, leaf);
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }
}
