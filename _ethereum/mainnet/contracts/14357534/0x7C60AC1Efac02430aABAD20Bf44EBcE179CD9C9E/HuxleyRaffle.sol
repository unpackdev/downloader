// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity 0.8.10;

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract HuxleyRaffle is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;
  LinkTokenInterface LINKTOKEN;
  
  uint64 s_subscriptionId;
  address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
  address link = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
  bytes32 keyHash = 0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92;
  uint32 callbackGasLimit = 100000;
  uint16 requestConfirmations = 3;
  uint32 numWords =  1;
  uint256[] public s_randomWords;
  uint256[][] public raffleWinners;
  string[] public ipfsGiveawayData;
  uint256 public s_requestId;
  address s_owner;

  event RaffleWinners(uint256 randomResult, uint256[] winnersResult);

  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(link);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
  }
  
  function requestRandomWords() external onlyOwner {
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }
  
  function fulfillRandomWords(
    uint256, 
    uint256[] memory randomWords
  ) internal override {
    s_randomWords.push(randomWords[0]);
  }

  function selectWinners(uint256 numWinners, uint256 drawId, uint256 numEntries) external onlyOwner {
    uint256[] memory winners = new uint256[](numWinners);
      
    for (uint256 i = 0; i < numWinners; i++) {      
      winners[i] = (uint256(keccak256(abi.encode(s_randomWords[drawId], i))) % numEntries) + 1;
    }

    raffleWinners.push(winners);
    emit RaffleWinners(s_randomWords[drawId], winners);
  }

  function addGiveawayData(string memory _ipfsGiveawayData) external onlyOwner {
    ipfsGiveawayData.push(_ipfsGiveawayData);
  } 

  function getWinners(uint256 raffleId) external view returns (uint256[] memory) {
    return raffleWinners[raffleId];
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }
}
