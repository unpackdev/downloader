//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.11;

import "./VRFConsumerBase.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract OGScavengerCompetition is VRFConsumerBase, Ownable {
  /// @notice Count of all players in this competition where each player is identified by their Discord ID
  uint256 public constant COUNT_OF_PLAYERS = 61;

  /// @notice Index of competition winner
  uint256 public winner;

  /// @notice Random number received from VRF coordinator ChainLink service
  uint256 public randomness;

  /// @notice Fee required by Chainlink service to calculate randomness
  uint256 private fee;

  /// @notice Request id of randomness request to VRF coordinator ChainLink service
  bytes32 public requestId;

  /// @notice public key hash of VRF coordinator ChainLink service
  bytes32 private keyHash;

  /// @notice Competition state enum
  /// NOT_STARTED - Initial state of competition, not started yet - initial state
  /// COMPUTING - Competition is running and waiting for randomness from VRF coordinator ChainLink service
  /// COMPLETED - Competition is completed and winner is set - final state
  enum CompetitionState {
    NOT_STARTED,
    COMPUTING,
    COMPLETED
  }

  CompetitionState public state;

  event RequestRandomness(bytes32 requestId);

  event AnnounceWinner(uint256 playerId);

  /// @notice Instantiates the OGScavengerCompetition contract.
  /// @param _vrfCoordinator VRF coordinator address.
  /// @param _link Link Token address.
  /// @param _keyhash public keyhash of the VRF coordinator.
  /// @param _fee Fee for requesting randomness.
  constructor(
    address _vrfCoordinator,
    address _link,
    bytes32 _keyhash,
    uint256 _fee
  ) VRFConsumerBase(_vrfCoordinator, _link) {
    keyHash = _keyhash;
    fee = _fee;
    state = CompetitionState.NOT_STARTED;
  }

  function start() external onlyOwner {
    require(
      state == CompetitionState.NOT_STARTED,
      "State must be 'not started'"
    );

    require(LINK.balanceOf(address(this)) >= fee, 'Not enough LINK');

    state = CompetitionState.COMPUTING;

    requestId = requestRandomness(keyHash, fee);
    emit RequestRandomness(requestId);
  }

  function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
    internal
    override
  {
    require(state == CompetitionState.COMPUTING, 'State must be computing');
    require(requestId == _requestId, 'Request id must be known');
    require(_randomness > 0, 'Randomness must be > 0');

    randomness = _randomness;
    uint256 indexOfWinner = (_randomness % COUNT_OF_PLAYERS) + 1;

    winner = indexOfWinner;
    state = CompetitionState.COMPLETED;

    emit AnnounceWinner(winner);
  }

  function withdrawLink() external onlyOwner {
    IERC20 tokenContract = IERC20(address(LINK));

    require(
      tokenContract.transfer(
        msg.sender,
        tokenContract.balanceOf(address(this))
      ),
      'Unable to transfer'
    );
  }
}
