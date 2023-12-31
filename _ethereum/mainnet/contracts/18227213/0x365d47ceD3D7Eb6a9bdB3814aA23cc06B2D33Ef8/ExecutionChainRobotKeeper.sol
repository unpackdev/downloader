// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IPayloadsControllerCore.sol";
import "./IExecutionChainRobotKeeper.sol";
import "./Ownable.sol";

/**
 * @title ExecutionChainRobotKeeper
 * @author BGD Labs
 * @notice Contract to perform automation on payloads controller
 * @dev Aave chainlink automation-keeper-compatible contract to:
 *      - check if the payload could be executed
 *      - executes the payload if all the conditions are met.
 */
contract ExecutionChainRobotKeeper is Ownable, IExecutionChainRobotKeeper {
  /// @inheritdoc IExecutionChainRobotKeeper
  address public immutable PAYLOADS_CONTROLLER;

  mapping(uint256 => bool) internal _disabledProposals;

  /// @inheritdoc IExecutionChainRobotKeeper
  uint256 public constant MAX_SHUFFLE_SIZE = 5;

  /**
   * @inheritdoc IExecutionChainRobotKeeper
   * @dev maximum number of payloads to check before the latest payload, if they could be executed.
   *      from the last payload we check 20 more payloads to be very sure that no proposal is being unchecked.
   */
  uint256 public constant MAX_SKIP = 20;

  error NoActionCanBePerformed();

  /**
   * @param payloadsController address of the payloads controller contract.
   */
  constructor(address payloadsController) {
    PAYLOADS_CONTROLLER = payloadsController;
  }

  /**
   * @inheritdoc AutomationCompatibleInterface
   * @dev run off-chain, checks if payload should be executed
   */
  function checkUpkeep(bytes calldata) external view override returns (bool, bytes memory) {
    uint40[] memory payloadIdsToExecute = new uint40[](MAX_SHUFFLE_SIZE);
    uint256 actionsCount;

    uint40 index = IPayloadsControllerCore(PAYLOADS_CONTROLLER).getPayloadsCount();
    uint256 skipCount;

    // loops from the last/latest payloadId until MAX_SKIP iterations. resets skipCount and checks more MAX_SKIP number
    // of payloads if they could be executed. we only check payloads until MAX_SKIP iterations from the last/latest payload
    // or payloads where any action could be performed, and payloads before that will not be checked by the keeper.
    while (index != 0 && skipCount <= MAX_SKIP && actionsCount < MAX_SHUFFLE_SIZE) {
      uint40 payloadId = index - 1;
      if (!isDisabled(payloadId)) {
        if (_canPayloadBeExecuted(payloadId)) {
          payloadIdsToExecute[actionsCount] = payloadId;
          actionsCount++;
          skipCount = 0;
        } else {
          skipCount++;
        }
      }
      index--;
    }

    if (actionsCount > 0) {
      // we shuffle the payloadsIds list to execute so that one payload failing does not block the other actions of the keeper.
      payloadIdsToExecute = _squeezeAndShuffleActions(payloadIdsToExecute, actionsCount);
      // squash and pick the first element from the shuffled array to perform execute.
      // we only perform one execute action due to gas limit limitation in one performUpkeep.
      assembly {
        mstore(payloadIdsToExecute, 1)
      }
      return (true, abi.encode(payloadIdsToExecute));
    }

    return (false, '');
  }

  /**
   * @inheritdoc AutomationCompatibleInterface
   * @dev executes executePayload action on payload controller.
   * @param performData array of proposal ids to execute.
   */
  function performUpkeep(bytes calldata performData) external override {
    uint40[] memory payloadIdsToExecute = abi.decode(performData, (uint40[]));
    bool isActionPerformed;

    // executes action on payloadIds in order from first to last
    for (uint256 i = payloadIdsToExecute.length; i > 0; i--) {
      uint40 payloadId = payloadIdsToExecute[i - 1];

      if (_canPayloadBeExecuted(payloadId)) {
        IPayloadsControllerCore(PAYLOADS_CONTROLLER).executePayload(payloadId);
        isActionPerformed = true;
        emit ActionSucceeded(payloadId);
      }
    }

    if (!isActionPerformed) revert NoActionCanBePerformed();
  }

  /// @inheritdoc IExecutionChainRobotKeeper
  function isDisabled(uint40 id) public view returns (bool) {
    return _disabledProposals[id];
  }

  /// @inheritdoc IExecutionChainRobotKeeper
  function toggleDisableAutomationById(uint256 id) external onlyOwner {
    _disabledProposals[id] = !_disabledProposals[id];
  }

  /**
   * @notice method to check if the payload could be executed.
   * @param payloadId the id of the payload to check if it can be executed.
   * @return true if the payload could be executed, false otherwise.
   */
  function _canPayloadBeExecuted(uint40 payloadId) internal view returns (bool) {
    IPayloadsControllerCore.Payload memory payload = IPayloadsControllerCore(PAYLOADS_CONTROLLER)
      .getPayloadById(payloadId);

    return
      payload.state == IPayloadsControllerCore.PayloadState.Queued &&
      block.timestamp > payload.queuedAt + payload.delay;
  }

  /**
   * @notice method to squeeze the payloadIds array to the right size and shuffle them.
   * @param payloadIds the list of payloadIds to squeeze and shuffle.
   * @param actionsCount the total count of actions - used to squeeze the array to the right size.
   * @return actions array squeezed and shuffled.
   */
  function _squeezeAndShuffleActions(
    uint40[] memory payloadIds,
    uint256 actionsCount
  ) internal view returns (uint40[] memory) {
    // we do not know the length in advance, so we init arrays with MAX_SHUFFLE_SIZE
    // and then squeeze the array using mstore
    assembly {
      mstore(payloadIds, actionsCount)
    }

    // shuffle actions
    for (uint256 i = 0; i < payloadIds.length; i++) {
      uint256 randomNumber = uint256(
        keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
      );
      uint256 n = i + (randomNumber % (payloadIds.length - i));
      uint40 temp = payloadIds[n];
      payloadIds[n] = payloadIds[i];
      payloadIds[i] = temp;
    }

    return payloadIds;
  }
}
