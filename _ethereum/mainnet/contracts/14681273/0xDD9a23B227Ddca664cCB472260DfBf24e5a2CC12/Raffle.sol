// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./Ownable.sol";

contract Raffle is VRFConsumerBaseV2, Ownable {
  VRFCoordinatorV2Interface COORDINATOR;

  // Keeps track of wallets that have been added the raffle. Once a wallet is selected 
  // as a winner or runner-up, they are removed from this list in order to
  // prevent that same wallet from possibly being selected again.
  address[] public walletsInRaffle;

  // A lookup to provide the requestId that Chainlink VRF that was provided each
  // time a drawing took place.
  // (e.g. index of 1 = winner's VRF requestId that used, 2 = first runner-up's VRF requestId, etc.)
  mapping(uint => uint256) public vrfRequestIdPlacement;

  // A lookup to provide the randomly generated number from Chainlink VRF that was provided each
  // time a drawing took place.
  // (e.g. index of 1 = winner's VRF random number that generated, 2 = first runner-up's VRF random number, etc.)
  mapping(uint => uint256) public vrfRandomNumberPlacement;

  // A lookup to check if a wallet is part of the raffle. Unlike walletsInRaffle, once
  // a wallet to added to this lookup, they will remain in this lookup, winner or not.
  mapping(address => bool) public isInRaffle;

  // Provides a lookup on the placement of the winner and runner-ups.
  mapping(uint => address) public winners;

  // Keeps track of how many draws have been done for the raffle.
  uint256 public numDraws;

  enum RAFFLE_STATE { OPEN, CLOSED, CALCULATING_WINNER }
  RAFFLE_STATE public raffleState;

  uint64 vrfSubscriptionId;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 vrfKeyHash;

  // The gas limit that will used when the fulfillRandomWords() function is called.
  uint32 callbackGasLimit = 350000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  event RequestedRandomness(uint256 requestId);

  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  constructor(
    uint64 _vrfSubscriptionId,
    bytes32 _vrfKeyHash,
    address _vrfCoordinator) VRFConsumerBaseV2(_vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    vrfSubscriptionId = _vrfSubscriptionId;
    vrfKeyHash = _vrfKeyHash;
  }

  function addWalletsToRaffle(address[] memory addresses) external onlyOwner {
    require(numDraws == 0, "Cannot enter post draw");
    require(raffleState == RAFFLE_STATE.OPEN, "Raffle must be open");

    for(uint256 i=0;i < addresses.length;i++) {
      // ignore any addresses that are already part of the raffle
      if(isInRaffle[addresses[i]]) {
        continue;
      }

      walletsInRaffle.push(addresses[i]);
      isInRaffle[addresses[i]] = true;
    }
  }

  // Return the total number of wallets that were entered into the raffle. 
  // Note: Since a wallet is removed from walletsInRaffle after winning and a 
  // drawing only selects 1 wallet, numDraws is used to help determine the correct total number
  function numWalletsInRaffle() external view returns (uint256) {
    return walletsInRaffle.length + numDraws;
  }

  // Once raffle is fully finished and a winner has been chosen, close down the raffle permanently. 
  function closeRaffle() external onlyOwner {
    require(raffleState == RAFFLE_STATE.OPEN, "Raffle must be open");

    raffleState = RAFFLE_STATE.CLOSED;
  }

  function drawWinner() external onlyOwner {
    requestRandomWords();
  }

  // In the event that VRF encounters an out of gas error during the callback to this contract,
  // the gas limit can be adjusted here in order to fix that.
  function updateVrfGasLimit(uint32 _callbackGasLimit) external onlyOwner {
    require(raffleState == RAFFLE_STATE.CALCULATING_WINNER, "Invalid state");

    callbackGasLimit = _callbackGasLimit;
    raffleState = RAFFLE_STATE.OPEN;
  }

  function requestRandomWords() private { 
    require(raffleState == RAFFLE_STATE.OPEN, "Raffle must be open");
    require(walletsInRaffle.length > 0, "No wallets in raffle");
    uint32 numWords =  1;

    raffleState = RAFFLE_STATE.CALCULATING_WINNER;
    uint256 requestId = COORDINATOR.requestRandomWords(
      vrfKeyHash,
      vrfSubscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );

    emit RequestedRandomness(requestId);
  }
  
  function fulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  ) internal override {
    require(raffleState == RAFFLE_STATE.CALCULATING_WINNER, "Not there yet");
    numDraws++;

    uint256 indexOfWinner = randomWords[0] % walletsInRaffle.length;
    vrfRequestIdPlacement[numDraws] = requestId;
    vrfRandomNumberPlacement[numDraws] = randomWords[0];
    winners[numDraws] = walletsInRaffle[indexOfWinner];

    removeWalletFromRaffle(indexOfWinner);
    raffleState = RAFFLE_STATE.OPEN;
  }

  function removeWalletFromRaffle(uint index) private {
    walletsInRaffle[index] = walletsInRaffle[walletsInRaffle.length - 1];
    walletsInRaffle.pop();
  }
}
