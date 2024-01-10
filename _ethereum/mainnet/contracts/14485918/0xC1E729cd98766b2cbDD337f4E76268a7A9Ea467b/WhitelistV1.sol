// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

abstract contract NftContract {
  function mint(
    address to,
    uint256 tokenId,
    uint8 width,
    uint8 height
  ) external virtual;
}

contract WhitelistV1 is VRFConsumerBaseV2, Ownable {
  // Chainlink params
  VRFCoordinatorV2Interface public COORDINATOR;
  LinkTokenInterface public LINKTOKEN;
  uint256[] private randomSeedList;
  uint64 public subscriptionId;
  bytes32 public keyHash;
  uint256 public requestId;

  struct Whitelist {
    uint8 width;
    uint8 height;
    uint16 seedOffset;
    uint16 currentSupply;
    uint32 startTime;
    uint32 endTime;
    bytes32 merkleRoot;
  }

  mapping(uint256 => Whitelist) public whitelistList; // whitelistId to whitelist struct
  mapping(uint256 => uint16[]) private whitelistTokenList; // whitelistId to token id array
  mapping(uint256 => mapping(address => bool)) public minted; // [whitelistId][address] = false
  address immutable nftContractAddress; // nft contract

  event RandomWordsReceived(uint256 length);
  event WhitelistCreated(
    uint256 listId,
    uint32 startTime,
    uint32 endTime,
    uint8 width,
    uint8 height,
    bytes32 merkleRoot
  );
  event WhitelistUpdated(uint256 listId, uint32 startTime, uint32 endTime);
  event Mint(address to, uint256 tokenId, uint256 listId);

  constructor(
    address _nftContractAddress,
    uint64 _subscriptionId,
    address vrfCoordinator,
    address linkTokenAddress,
    bytes32 _keyHash
  ) VRFConsumerBaseV2(vrfCoordinator) {
    nftContractAddress = _nftContractAddress;
    subscriptionId = _subscriptionId;
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(linkTokenAddress);
    keyHash = _keyHash;
  }

  modifier isActive(uint256 listId) {
    Whitelist memory whitelist = whitelistList[listId];
    require(whitelist.startTime <= block.timestamp, "Session not started");
    require(whitelist.endTime >= block.timestamp, "Session ended");
    _;
  }

  function setKeyHash(bytes32 _keyHash) external onlyOwner {
    keyHash = _keyHash;
  }

  function generateRandomWords(uint32 numWords) external onlyOwner {
    uint256[] memory randomWords = new uint256[](numWords);
    uint256 random;
    for (uint32 i = 0; i < numWords; i++) {
      random = uint256(
        keccak256(abi.encodePacked(random, block.difficulty, block.timestamp))
      );
      randomWords[i] = random;
    }
    fulfillRandomWords(0, randomWords);
  }

  function requestRandomWords(uint32 numWords, uint32 callbackGasLimit)
    external
    onlyOwner
  {
    // Will revert if subscription is not set and funded.
    requestId = COORDINATOR.requestRandomWords(
      keyHash,
      subscriptionId,
      3, //requestConfirmations
      callbackGasLimit,
      numWords
    );
  }

  function createWhitelist(
    uint256 listId,
    uint8 width,
    uint8 height,
    uint16 seedOffset,
    uint32 startTime,
    uint32 endTime,
    bytes32 merkleRoot,
    uint16[] calldata tokenList
  ) external onlyOwner {
    require(
      tokenList.length <= randomSeedList.length * 16,
      "Insufficient random seeds"
    );
    require(whitelistList[listId].width == 0, "listId exists");
    require(width > 0 && height > 0, "Incorrect width or height");
    whitelistList[listId] = Whitelist(
      width,
      height,
      uint16(listId + seedOffset),
      0,
      startTime,
      endTime,
      merkleRoot
    );
    whitelistTokenList[listId] = tokenList;
    shuffleTokenList(listId);
    emit WhitelistCreated(
      listId,
      startTime,
      endTime,
      width,
      height,
      merkleRoot
    );
  }

  function updateWhitelistStartTime(uint256 listId, uint32 _startTime)
    external
    onlyOwner
  {
    whitelistList[listId].startTime = _startTime;
    emit WhitelistUpdated(
      listId,
      whitelistList[listId].startTime,
      whitelistList[listId].endTime
    );
  }

  function updateWhitelistEndTime(uint256 listId, uint32 _endTime)
    external
    onlyOwner
  {
    whitelistList[listId].endTime = _endTime;
    emit WhitelistUpdated(
      listId,
      whitelistList[listId].startTime,
      whitelistList[listId].endTime
    );
  }

  function mint(uint256 listId, bytes32[] calldata proof)
    external
    isActive(listId)
  {
    require(msg.sender == tx.origin, "Contract interaction not allowed");
    require(verifyProof(listId, msg.sender, proof), "Invalid merkle proof");

    require(!minted[listId][msg.sender], "Already minted");

    minted[listId][msg.sender] = true;
    uint256 tokenId = drawRandomTokenId(listId);
    NftContract nftContract = NftContract(nftContractAddress);
    Whitelist memory whitelist = whitelistList[listId];
    nftContract.mint(msg.sender, tokenId, whitelist.width, whitelist.height);
    emit Mint(msg.sender, tokenId, listId);
  }

  function getRandomSeedListLength() external view returns (uint256) {
    return randomSeedList.length * 16;
  }

  function verifyProof(
    uint256 listId,
    address who,
    bytes32[] calldata proof
  ) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(who));
    return MerkleProof.verify(proof, whitelistList[listId].merkleRoot, leaf);
  }

  function fulfillRandomWords(
    uint256,
    /* requestId */
    uint256[] memory randomWords
  ) internal override {
    for (uint256 i = 0; i < randomWords.length; i++) {
      randomSeedList.push(randomWords[i]);
    }
    emit RandomWordsReceived(randomWords.length);
  }

  function shuffleTokenList(uint256 listId) internal {
    uint16[] storage tokenList = whitelistTokenList[listId];
    for (uint16 i = 0; i < tokenList.length; i++) {
      uint256 seedIndex = ((i + whitelistList[listId].seedOffset) / 16) %
        randomSeedList.length;
      uint256 random = uint16(randomSeedList[seedIndex] >> (i % 16)) %
        tokenList.length;
      (tokenList[i], tokenList[random]) = (tokenList[random], tokenList[i]);
    }
  }

  function drawRandomTokenId(uint256 listId) internal returns (uint256) {
    whitelistList[listId].currentSupply += 1;
    return whitelistTokenList[listId][whitelistList[listId].currentSupply - 1];
  }
}
