// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
//
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./Ownable.sol";

// ======================================================================================================
//
// Draw contract for the winner of the PROXTOBER giveaway. All users who setup a proxy in October
// are automatically in the draw. Prize is 1 ETH. One winner, selected randomly using chainlink VRF.
//
// The final list of entries with the corresponding entry number are on arweave at:
//
//
// ======================================================================================================

contract SimpleVRFDraw is VRFConsumerBaseV2, Ownable {
  string public constant ENTRY_LIST_URL =
    "https://arweave.net/mVLmswY-97CKFZExmYDSHcfaD-MXpzhxJxXiOxGHgM4";

  uint256 public constant NUMBER_OF_ENTRIES = 37;

  uint256 public recordedRandomWord;

  uint256 public winner; // the winning position

  /**
   * @dev Chainlink config.
   */
  // Mainnet: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909
  // Goerli: 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
  VRFCoordinatorV2Interface vrfCoordinator;
  uint64 vrfSubscriptionId;
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  // Mainnet 200 gwei: 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef
  // Goerli 150 gwei 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15
  bytes32 vrfKeyHash;
  uint32 vrfCallbackGasLimit = 150000;
  uint16 vrfRequestConfirmations = 3;
  uint32 vrfNumWords = 1;

  error VRFAlreadySet();

  event RandomNumberReceived(uint256 indexed requestId, uint256 randomNumber);
  event Winner(uint256 winningPosition);

  constructor() VRFConsumerBaseV2(0x271682DEB8C4E0901D1a1550aD2e64D568E69909) {
    vrfCoordinator = VRFCoordinatorV2Interface(
      0x271682DEB8C4E0901D1a1550aD2e64D568E69909
    );
    vrfKeyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    setVRFSubscriptionId(500);
  }

  /**
   *
   * @dev drawTheWinner
   *
   */
  function drawTheWinner() external onlyOwner returns (uint256) {
    if (recordedRandomWord != 0) {
      revert VRFAlreadySet();
    }
    return
      vrfCoordinator.requestRandomWords(
        vrfKeyHash,
        vrfSubscriptionId,
        vrfRequestConfirmations,
        vrfCallbackGasLimit,
        vrfNumWords
      );
  }

  /** =====================================================
   *
   *
   * Chainlink VRF
   *
   *
   * =====================================================
   */

  /**
   *
   * @dev fulfillRandomWords: Callback from the chainlinkv2 oracle with randomness.
   * Checks to end the auction if it's in the random end period of price or time.
   */
  function fulfillRandomWords(uint256 requestId_, uint256[] memory randomWords_)
    internal
    override
  {
    recordedRandomWord = randomWords_[0];
    winner = (randomWords_[0] % NUMBER_OF_ENTRIES) + 1;
    emit RandomNumberReceived(requestId_, randomWords_[0]);
    emit Winner(winner);
  }

  /**
   *
   * @dev chainlink configuration setters:
   *
   */

  /**
   *
   * @dev setVRFCoordinator: Set the chainlink subscription metadataSalt coordinator.
   *
   */
  function setVRFCoordinator(address vrfCoordinator_) external onlyOwner {
    vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
  }

  /**
   *
   * @dev setVRFSubscriptionId: Set the chainlink subscription id.
   *
   */
  function setVRFSubscriptionId(uint64 vrfSubscriptionId_) public onlyOwner {
    vrfSubscriptionId = vrfSubscriptionId_;
  }

  /**
   *
   * @dev setVRFKeyHash: Set the chainlink keyhash (gas lane).
   *
   */
  function setVRFKeyHash(bytes32 vrfKeyHash_) external onlyOwner {
    vrfKeyHash = vrfKeyHash_;
  }

  /**
   *
   * @dev setVRFCallbackGasLimit: Set the chainlink callback gas limit.
   *
   */
  function setVRFCallbackGasLimit(uint32 vrfCallbackGasLimit_)
    external
    onlyOwner
  {
    vrfCallbackGasLimit = vrfCallbackGasLimit_;
  }

  /**
   *
   * @dev set: Set the chainlink number of confirmations.
   *
   */
  function setVRFRequestConfirmations(uint16 vrfRequestConfirmations_)
    external
    onlyOwner
  {
    vrfRequestConfirmations = vrfRequestConfirmations_;
  }

  /**
   *
   * @dev setVRFNumWords: Set the chainlink number of words.
   *
   */
  function setVRFNumWords(uint32 vrfNumWords_) external onlyOwner {
    vrfNumWords = vrfNumWords_;
  }
}
