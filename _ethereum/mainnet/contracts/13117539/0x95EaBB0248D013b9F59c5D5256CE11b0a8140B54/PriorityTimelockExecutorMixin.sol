// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import "./SafeMath.sol";
import "./IPriorityTimelockExecutor.sol";
import "./IDydxGovernor.sol";

/**
 * @title Time-locked executor contract mixin, inherited the governance executor contract.
 * @dev Contract that can queue, execute, cancel transactions voted by Governance
 * Queued transactions can be executed after a delay and until
 * Grace period is not over.
 * @author dYdX
 **/
contract PriorityTimelockExecutorMixin is IPriorityTimelockExecutor {
  using SafeMath for uint256;

  uint256 public immutable override GRACE_PERIOD;
  uint256 public immutable override MINIMUM_DELAY;
  uint256 public immutable override MAXIMUM_DELAY;

  address private _admin;
  address private _pendingAdmin;
  mapping(address => bool) private _isPriorityController;

  uint256 private _delay;
  uint256 private _priorityPeriod;

  mapping(bytes32 => bool) private _queuedTransactions;
  mapping(bytes32 => bool) private _priorityUnlockedTransactions;

  /**
   * @dev Constructor
   * @param admin admin address, that can call the main functions, (Governance)
   * @param delay minimum time between queueing and execution of proposal
   * @param gracePeriod time after `delay` while a proposal can be executed
   * @param minimumDelay lower threshold of `delay`, in seconds
   * @param maximumDelay upper threhold of `delay`, in seconds
   * @param priorityPeriod time at end of delay period during which a priority controller may “unlock”
   * @param priorityController address which may execute proposals during the priority window
   *  the proposal for early execution
   **/
  constructor(
    address admin,
    uint256 delay,
    uint256 gracePeriod,
    uint256 minimumDelay,
    uint256 maximumDelay,
    uint256 priorityPeriod,
    address priorityController
  ) {
    require(delay >= minimumDelay, 'DELAY_SHORTER_THAN_MINIMUM');
    require(delay <= maximumDelay, 'DELAY_LONGER_THAN_MAXIMUM');
    _validatePriorityPeriod(delay, priorityPeriod);
    _delay = delay;
    _priorityPeriod = priorityPeriod;
    _admin = admin;

    GRACE_PERIOD = gracePeriod;
    MINIMUM_DELAY = minimumDelay;
    MAXIMUM_DELAY = maximumDelay;

    emit NewDelay(delay);
    emit NewPriorityPeriod(priorityPeriod);
    emit NewAdmin(admin);

    _updatePriorityController(priorityController, true);
  }

  modifier onlyAdmin() {
    require(msg.sender == _admin, 'ONLY_BY_ADMIN');
    _;
  }

  modifier onlyTimelock() {
    require(msg.sender == address(this), 'ONLY_BY_THIS_TIMELOCK');
    _;
  }

  modifier onlyPendingAdmin() {
    require(msg.sender == _pendingAdmin, 'ONLY_BY_PENDING_ADMIN');
    _;
  }

  modifier onlyPriorityController() {
    require(_isPriorityController[msg.sender], 'ONLY_BY_PRIORITY_CONTROLLER');
    _;
  }

  /**
   * @dev Set the delay
   * @param delay delay between queue and execution of proposal
   **/
  function setDelay(uint256 delay) public onlyTimelock {
    _validateDelay(delay);
    _validatePriorityPeriod(delay, _priorityPeriod);
    _delay = delay;

    emit NewDelay(delay);
  }

  /**
   * @dev Set the priority period
   * @param priorityPeriod time at end of delay period during which a priority controller may “unlock”
   *  the proposal for early execution
   **/
  function setPriorityPeriod(uint256 priorityPeriod) public onlyTimelock {
    _validatePriorityPeriod(_delay, priorityPeriod);
    _priorityPeriod = priorityPeriod;

    emit NewPriorityPeriod(priorityPeriod);
  }

  /**
   * @dev Function enabling pending admin to become admin
   **/
  function acceptAdmin() public onlyPendingAdmin {
    _admin = msg.sender;
    _pendingAdmin = address(0);

    emit NewAdmin(msg.sender);
  }

  /**
   * @dev Setting a new pending admin (that can then become admin)
   * Can only be called by this executor (i.e via proposal)
   * @param newPendingAdmin address of the new admin
   **/
  function setPendingAdmin(address newPendingAdmin) public onlyTimelock {
    _pendingAdmin = newPendingAdmin;

    emit NewPendingAdmin(newPendingAdmin);
  }

  /**
   * @dev Add or remove a priority controller.
   */
  function updatePriorityController(address account, bool isPriorityController) public onlyTimelock {
    _updatePriorityController(account, isPriorityController);
  }

  /**
   * @dev Function, called by Governance, that queue a transaction, returns action hash
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   * @return the action Hash
   **/
  function queueTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) public override onlyAdmin returns (bytes32) {
    require(executionTime >= block.timestamp.add(_delay), 'EXECUTION_TIME_UNDERESTIMATED');

    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    _queuedTransactions[actionHash] = true;

    emit QueuedAction(actionHash, target, value, signature, data, executionTime, withDelegatecall);
    return actionHash;
  }

  /**
   * @dev Function, called by Governance, that cancels a transaction, returns action hash
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   * @return the action Hash of the canceled tx
   **/
  function cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) public override onlyAdmin returns (bytes32) {
    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    _queuedTransactions[actionHash] = false;

    emit CancelledAction(
      actionHash,
      target,
      value,
      signature,
      data,
      executionTime,
      withDelegatecall
    );
    return actionHash;
  }

  /**
   * @dev Function, called by Governance, that executes a transaction, returns the callData executed
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   * @return the callData executed as memory bytes
   **/
  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) public payable override onlyAdmin returns (bytes memory) {
    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    require(_queuedTransactions[actionHash], 'ACTION_NOT_QUEUED');
    require(block.timestamp <= executionTime.add(GRACE_PERIOD), 'GRACE_PERIOD_FINISHED');

    // Require either that:
    //  - the timelock elapsed; or
    //  - the transaction was unlocked by a priority controller, and we are in the priority
    //    execution window.
    if (_priorityUnlockedTransactions[actionHash]) {
      require(block.timestamp >= executionTime.sub(_priorityPeriod), 'NOT_IN_PRIORITY_WINDOW');
    } else {
      require(block.timestamp >= executionTime, 'TIMELOCK_NOT_FINISHED');
    }

    _queuedTransactions[actionHash] = false;

    bytes memory callData;

    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    bool success;
    bytes memory resultData;
    if (withDelegatecall) {
      require(msg.value >= value, "NOT_ENOUGH_MSG_VALUE");
      // solium-disable-next-line security/no-call-value
      (success, resultData) = target.delegatecall(callData);
    } else {
      // solium-disable-next-line security/no-call-value
      (success, resultData) = target.call{value: value}(callData);
    }

    require(success, 'FAILED_ACTION_EXECUTION');

    emit ExecutedAction(
      actionHash,
      target,
      value,
      signature,
      data,
      executionTime,
      withDelegatecall,
      resultData
    );

    return resultData;
  }

  /**
   * @dev Function, called by a priority controller, to lock or unlock a proposal for execution
   *  during the priority period.
   * @param actionHash hash of the action
   * @param isUnlockedForExecution whether the proposal is executable during the priority period
   */
  function setTransactionPriorityStatus(
    bytes32 actionHash,
    bool isUnlockedForExecution
  ) public onlyPriorityController {
    require(_queuedTransactions[actionHash], 'ACTION_NOT_QUEUED');
    _priorityUnlockedTransactions[actionHash] = isUnlockedForExecution;
    emit UpdatedActionPriorityStatus(actionHash, isUnlockedForExecution);
  }

  /**
   * @dev Getter of the current admin address (should be governance)
   * @return The address of the current admin
   **/
  function getAdmin() external view override returns (address) {
    return _admin;
  }

  /**
   * @dev Getter of the current pending admin address
   * @return The address of the pending admin
   **/
  function getPendingAdmin() external view override returns (address) {
    return _pendingAdmin;
  }

  /**
   * @dev Getter of the delay between queuing and execution
   * @return The delay in seconds
   **/
  function getDelay() external view override returns (uint256) {
    return _delay;
  }

  /**
   * @dev Getter of the priority period, which is amount of time before mandatory
   * timelock delay that a proposal can be executed early only by a priority controller.
   * @return The priority period in seconds.
   **/
  function getPriorityPeriod() external view returns (uint256) {
    return _priorityPeriod;
  }

  /**
   * @dev Getter for whether an address is a priority controller.
   * @param account address to check for being a priority controller
   * @return True if `account` is a priority controller, false if not.
   **/
  function isPriorityController(address account) external view returns (bool) {
    return _isPriorityController[account];
  }

  /**
   * @dev Returns whether an action (via actionHash) is queued
   * @param actionHash hash of the action to be checked
   * keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall))
   * @return true if underlying action of actionHash is queued
   **/
  function isActionQueued(bytes32 actionHash) external view override returns (bool) {
    return _queuedTransactions[actionHash];
  }

  /**
   * @dev Returns whether an action (via actionHash) has priority status
   * @param actionHash hash of the action to be checked
   * keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall))
   * @return true if underlying action of actionHash is queued
   **/
  function hasPriorityStatus(bytes32 actionHash) external view returns (bool) {
    return _priorityUnlockedTransactions[actionHash];
  }

  /**
   * @dev Checks whether a proposal is over its grace period
   * @param governance Governance contract
   * @param proposalId Id of the proposal against which to test
   * @return true of proposal is over grace period
   **/
  function isProposalOverGracePeriod(IDydxGovernor governance, uint256 proposalId)
    external
    view
    override
    returns (bool)
  {
    IDydxGovernor.ProposalWithoutVotes memory proposal = governance.getProposalById(proposalId);

    return (block.timestamp > proposal.executionTime.add(GRACE_PERIOD));
  }

  function _updatePriorityController(address account, bool isPriorityController) internal {
    _isPriorityController[account] = isPriorityController;
    emit PriorityControllerUpdated(account, isPriorityController);
  }

  function _validateDelay(uint256 delay) internal view {
    require(delay >= MINIMUM_DELAY, 'DELAY_SHORTER_THAN_MINIMUM');
    require(delay <= MAXIMUM_DELAY, 'DELAY_LONGER_THAN_MAXIMUM');
  }

  function _validatePriorityPeriod(uint256 delay, uint256 priorityPeriod) internal view {
    require(priorityPeriod <= delay, 'PRIORITY_PERIOD_LONGER_THAN_DELAY');
  }

  receive() external payable {}
}
