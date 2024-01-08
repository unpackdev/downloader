// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./VRFConsumerBase.sol";

/**
 * @dev Contract dedicated to request and consume a random number
 * from Chainlink VRF
 */
contract PianoKingRNConsumer is Ownable, VRFConsumerBase {
  // The 3 possible status for the random number
  enum RNStatus {
    undefined,
    requested,
    received
  }

  // The random number used as a seed for the random sequence for batch mint
  uint256 internal randomSeed;
  // The random number used as the base for the incrementor in the sequence
  uint256 internal randomIncrementor;

  // Indicate the status of the random number
  // Since 0 is equal to undefined then it will be its default value
  // which is what we want
  RNStatus internal randomNumberStatus;

  // Data for chainlink
  bytes32 internal keyhash;
  uint256 internal fee;

  event RequestedRandomness(bytes32 indexed requestId);
  event RandomNumberReceived(bytes32 indexed requestId);

  constructor(
    address _vrfCoordinator,
    address _linkToken,
    bytes32 _keyhash,
    uint256 _fee
  ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
    keyhash = _keyhash;
    fee = _fee;
  }

  /**
   * @dev Request the random number to be used for a batch mint
   */
  function requestRandomNumber() external onlyOwner {
    // Can trigger only one randomness request at a time
    require(
      randomNumberStatus != RNStatus.requested,
      "Random number already requested"
    );
    // We need some LINK to pay a fee to the oracles
    require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
    // Indicate that a request has been initiated
    randomNumberStatus = RNStatus.requested;
    // Request a random number to Chainlink oracles
    bytes32 requestId = requestRandomness(keyhash, fee);
    emit RequestedRandomness(requestId);
  }

  /**
   * Called by Chainlink oracles when sending back a random number for
   * a given request
   * This function cannot use more than 200,000 gas or the transaction
   * will fail
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
    internal
    override
  {
    // Put 16 bytes of randomNumber into randomSeed
    randomSeed =
      randomNumber &
      0xffffffffffffffff0000000000000000ffffffffffffffff0000000000000000;
    // Put the other 16 bytes of randomNumber into randomIncrementor
    randomIncrementor =
      randomNumber &
      0x0000000000000000ffffffffffffffff0000000000000000ffffffffffffffff;
    // We're making sure the random incrementor is high enough and most
    // importantly not zero
    if (randomIncrementor < 10000) {
      randomIncrementor += 10000;
    }
    // Allow to trigger a new randomness request
    randomNumberStatus = RNStatus.received;
    // Just to tell us that the random number has been received
    // No need to broadcast, however making it public is not problematic
    // and shouldn't since any data on-chain is public (even private variable)
    emit RandomNumberReceived(requestId);
  }

  /**
   * @dev Get the random numbers
   */
  function getRandomNumbers()
    external
    view
    returns (uint256 _randomSeed, uint256 _randomIncrementor)
  {
    require(randomNumberStatus == RNStatus.received, "Random number not ready");
    _randomSeed = randomSeed;
    _randomIncrementor = randomIncrementor;
  }

  /**
   * @dev Let the owner of the contract withdraw LINK from the smart contract.
   * Can be useful if too much was sent or LINK are no longer needed on the contract
   */
  function withdrawLinkTokens(uint256 amount) external onlyOwner {
    LINK.transfer(msg.sender, amount);
  }
}
