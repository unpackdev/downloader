// SPDX-License-Identifier: MIT
// Abana Music List Randomizer
// Based on Niftydude's Pixel Vault List Randomizer, updated for Chainlink VRF V2.
// @author CryptoCactoid
pragma solidity ^0.8.9;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract RandomizeList is VRFConsumerBaseV2, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private counter; 

  VRFCoordinatorV2Interface COORDINATOR;

  uint64 s_subscriptionId = 82; //mainnet

  address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909; //mainnet
  bytes32 public keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef; //mainnet 200 gwei keyHash

  //defaults
  uint32 callbackGasLimit = 100000;
  uint16 requestConfirmations = 3;

  //Returns one number in a uint256 array which is sufficient for list randomization
  uint32 numWords =  1;

  mapping(uint256 => Randomization) public randomizations;

  struct Randomization {
      uint256 listLength;
      string description;
      uint256 randomNumber;
      bool isFulfilled;
      string itemListIpfsHash;
  }

  constructor() VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
  }

  /**
  * @notice Update KeyHash to choose different speeds
  * 
  * @param _keyHash Max Gas price allowed per randomness request
  * 
  */
  function updateKeyHash(bytes32 _keyHash) external onlyOwner {
    keyHash = _keyHash;
  }

  /**
  * @notice initiate a new randomization
  * 
  * @param _listLength the number of items in the list
  * @param _itemListIpfsHash ipfs hash pointing to the list of items to randomize
  * 
  */
  function startRandomization(
    uint256 _listLength, 
    string memory _itemListIpfsHash,
    string memory _description
  ) external onlyOwner returns (uint256 requestId) {
    require(counter.current() == 0 || randomizations[counter.current()-1].isFulfilled, "Previous randomization not fulfilled");    
    Randomization storage d = randomizations[counter.current()];
    d.listLength = _listLength;
    d.itemListIpfsHash = _itemListIpfsHash;
    d.description = _description;

    counter.increment();

    return COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }   

  /**
  * @notice return randomized list for a given randomization
  * 
  * @param _id the randomization id to return the list for
  */
  function getRandomList(uint256 _id) external view returns (uint256[] memory) {         
    require(randomizations[_id].isFulfilled, "Randomization not fulfilled yet");            

    uint256[] memory arr = new uint256[](randomizations[_id].listLength);

    for (uint256 i = 0; i < randomizations[_id].listLength; i++) {
      uint256 j = (uint256(keccak256(abi.encode(randomizations[_id].randomNumber, i))) % (i + 1));

      arr[i] = arr[j];
      arr[j] = i+1;
    }
    
    return arr;
  }    

  //callback function used by VRF V2 Coordinator
  function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
    randomizations[counter.current()-1].randomNumber = randomWords[0];
    randomizations[counter.current()-1].isFulfilled = true;
  }

}