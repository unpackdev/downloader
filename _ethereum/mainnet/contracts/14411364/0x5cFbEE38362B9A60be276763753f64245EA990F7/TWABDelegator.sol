// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./Clones.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./ITicket.sol";

import "./Delegation.sol";
import "./LowLevelDelegator.sol";
import "./PermitAndMulticall.sol";

/**
 * @title Delegate chances to win to multiple accounts.
 * @notice This contract allows accounts to easily delegate a portion of their tickets to multiple delegatees.
  The delegatees chance of winning prizes is increased by the delegated amount.
  If a delegator doesn't want to actively manage the delegations, then they can stake on the contract and appoint representatives.
 */
contract TWABDelegator is ERC20, LowLevelDelegator, PermitAndMulticall {
  using Address for address;
  using Clones for address;
  using SafeERC20 for IERC20;

  /* ============ Events ============ */

  /**
   * @notice Emitted when ticket associated with this contract has been set.
   * @param ticket Address of the ticket
   */
  event TicketSet(ITicket indexed ticket);

  /**
   * @notice Emitted when tickets have been staked.
   * @param delegator Address of the delegator
   * @param amount Amount of tickets staked
   */
  event TicketsStaked(address indexed delegator, uint256 amount);

  /**
   * @notice Emitted when tickets have been unstaked.
   * @param delegator Address of the delegator
   * @param recipient Address of the recipient that will receive the tickets
   * @param amount Amount of tickets unstaked
   */
  event TicketsUnstaked(address indexed delegator, address indexed recipient, uint256 amount);

  /**
   * @notice Emitted when a new delegation is created.
   * @param delegator Delegator of the delegation
   * @param slot Slot of the delegation
   * @param lockUntil Timestamp until which the delegation is locked
   * @param delegatee Address of the delegatee
   * @param delegation Address of the delegation that was created
   * @param user Address of the user who created the delegation
   */
  event DelegationCreated(
    address indexed delegator,
    uint256 indexed slot,
    uint96 lockUntil,
    address indexed delegatee,
    Delegation delegation,
    address user
  );

  /**
   * @notice Emitted when a delegatee is updated.
   * @param delegator Address of the delegator
   * @param slot Slot of the delegation
   * @param delegatee Address of the delegatee
   * @param lockUntil Timestamp until which the delegation is locked
   * @param user Address of the user who updated the delegatee
   */
  event DelegateeUpdated(
    address indexed delegator,
    uint256 indexed slot,
    address indexed delegatee,
    uint96 lockUntil,
    address user
  );

  /**
   * @notice Emitted when a delegation is funded.
   * @param delegator Address of the delegator
   * @param slot Slot of the delegation
   * @param amount Amount of tickets that were sent to the delegation
   * @param user Address of the user who funded the delegation
   */
  event DelegationFunded(
    address indexed delegator,
    uint256 indexed slot,
    uint256 amount,
    address indexed user
  );

  /**
   * @notice Emitted when a delegation is funded from the staked amount.
   * @param delegator Address of the delegator
   * @param slot Slot of the delegation
   * @param amount Amount of tickets that were sent to the delegation
   * @param user Address of the user who pulled funds from the delegator stake to the delegation
   */
  event DelegationFundedFromStake(
    address indexed delegator,
    uint256 indexed slot,
    uint256 amount,
    address indexed user
  );

  /**
   * @notice Emitted when an amount of tickets has been withdrawn from a delegation. The tickets are held by this contract and the delegator stake is increased.
   * @param delegator Address of the delegator
   * @param slot Slot of the delegation
   * @param amount Amount of tickets withdrawn
   * @param user Address of the user who withdrew the tickets
   */
  event WithdrewDelegationToStake(
    address indexed delegator,
    uint256 indexed slot,
    uint256 amount,
    address indexed user
  );

  /**
   * @notice Emitted when a delegator withdraws an amount of tickets from a delegation to a specified wallet.
   * @param delegator Address of the delegator
   * @param slot  Slot of the delegation
   * @param amount Amount of tickets withdrawn
   * @param to Recipient address of withdrawn tickets
   */
  event TransferredDelegation(
    address indexed delegator,
    uint256 indexed slot,
    uint256 amount,
    address indexed to
  );

  /**
   * @notice Emitted when a representative is set.
   * @param delegator Address of the delegator
   * @param representative Address of the representative
   * @param set Boolean indicating if the representative was set or unset
   */
  event RepresentativeSet(address indexed delegator, address indexed representative, bool set);

  /* ============ Variables ============ */

  /// @notice Prize pool ticket to which this contract is tied to.
  ITicket public immutable ticket;

  /// @notice Max lock time during which a delegation cannot be updated.
  uint256 public constant MAX_LOCK = 180 days;

  /**
   * @notice Representative elected by the delegator to handle delegation.
   * @dev Representative can only handle delegation and cannot withdraw tickets to their wallet.
   * @dev delegator => representative => bool allowing representative to represent the delegator
   */
  mapping(address => mapping(address => bool)) internal representatives;

  /* ============ Constructor ============ */

  /**
   * @notice Creates a new TWAB Delegator that is bound to the given ticket contract.
   * @param name_ The name for the staked ticket token
   * @param symbol_ The symbol for the staked ticket token
   * @param _ticket Address of the ticket contract
   */
  constructor(
    string memory name_,
    string memory symbol_,
    ITicket _ticket
  ) LowLevelDelegator() ERC20(name_, symbol_) {
    require(address(_ticket) != address(0), "TWABDelegator/tick-not-zero-addr");
    ticket = _ticket;

    emit TicketSet(_ticket);
  }

  /* ============ External Functions ============ */

  /**
   * @notice Stake `_amount` of tickets in this contract.
   * @dev Tickets can be staked on behalf of a `_to` user.
   * @param _to Address to which the stake will be attributed
   * @param _amount Amount of tickets to stake
   */
  function stake(address _to, uint256 _amount) external {
    _requireAmountGtZero(_amount);

    IERC20(ticket).safeTransferFrom(msg.sender, address(this), _amount);
    _mint(_to, _amount);

    emit TicketsStaked(_to, _amount);
  }

  /**
   * @notice Unstake `_amount` of tickets from this contract. Transfers ticket to the passed `_to` address.
   * @dev If delegator has delegated his whole stake, he will first have to withdraw from a delegation to be able to unstake.
   * @param _to Address of the recipient that will receive the tickets
   * @param _amount Amount of tickets to unstake
   */
  function unstake(address _to, uint256 _amount) external {
    _requireRecipientNotZeroAddress(_to);
    _requireAmountGtZero(_amount);

    _burn(msg.sender, _amount);

    IERC20(ticket).safeTransfer(_to, _amount);

    emit TicketsUnstaked(msg.sender, _to, _amount);
  }

  /**
   * @notice Creates a new delegation.
   This will create a new Delegation contract for the given slot and have it delegate its tickets to the given delegatee.
   If a non-zero lock duration is passed, then the delegatee cannot be changed, nor funding withdrawn, until the lock has expired.
   * @dev The `_delegator` and `_slot` params are used to compute the salt of the delegation
   * @param _delegator Address of the delegator that will be able to handle the delegation
   * @param _slot Slot of the delegation
   * @param _delegatee Address of the delegatee
   * @param _lockDuration Duration of time for which the delegation is locked. Must be less than the max duration.
   * @return Returns the address of the Delegation contract that will hold the tickets
   */
  function createDelegation(
    address _delegator,
    uint256 _slot,
    address _delegatee,
    uint96 _lockDuration
  ) external returns (Delegation) {
    _requireDelegatorOrRepresentative(_delegator);
    _requireDelegateeNotZeroAddress(_delegatee);
    _requireLockDuration(_lockDuration);

    uint96 _lockUntil = _computeLockUntil(_lockDuration);

    Delegation _delegation = _createDelegation(
      _computeSalt(_delegator, bytes32(_slot)),
      _lockUntil
    );

    _setDelegateeCall(_delegation, _delegatee);

    emit DelegationCreated(_delegator, _slot, _lockUntil, _delegatee, _delegation, msg.sender);

    return _delegation;
  }

  /**
   * @notice Updates the delegatee and lock duration for a delegation slot.
   * @dev Only callable by the `_delegator` or their representative.
   * @dev Will revert if delegation is still locked.
   * @param _delegator Address of the delegator
   * @param _slot Slot of the delegation
   * @param _delegatee Address of the delegatee
   * @param _lockDuration Duration of time during which the delegatee cannot be changed nor withdrawn
   * @return The address of the Delegation
   */
  function updateDelegatee(
    address _delegator,
    uint256 _slot,
    address _delegatee,
    uint96 _lockDuration
  ) external returns (Delegation) {
    _requireDelegatorOrRepresentative(_delegator);
    _requireDelegateeNotZeroAddress(_delegatee);
    _requireLockDuration(_lockDuration);

    Delegation _delegation = Delegation(_computeAddress(_delegator, _slot));
    _requireDelegationUnlocked(_delegation);

    uint96 _lockUntil = _computeLockUntil(_lockDuration);

    if (_lockDuration > 0) {
      _delegation.setLockUntil(_lockUntil);
    }

    _setDelegateeCall(_delegation, _delegatee);

    emit DelegateeUpdated(_delegator, _slot, _delegatee, _lockUntil, msg.sender);

    return _delegation;
  }

  /**
   * @notice Fund a delegation by transferring tickets from the caller to the delegation.
   * @dev Callable by anyone.
   * @dev Will revert if delegation does not exist.
   * @param _delegator Address of the delegator
   * @param _slot Slot of the delegation
   * @param _amount Amount of tickets to transfer
   * @return The address of the Delegation
   */
  function fundDelegation(
    address _delegator,
    uint256 _slot,
    uint256 _amount
  ) external returns (Delegation) {
    require(_delegator != address(0), "TWABDelegator/dlgtr-not-zero-adr");
    _requireAmountGtZero(_amount);

    Delegation _delegation = Delegation(_computeAddress(_delegator, _slot));
    IERC20(ticket).safeTransferFrom(msg.sender, address(_delegation), _amount);

    emit DelegationFunded(_delegator, _slot, _amount, msg.sender);

    return _delegation;
  }

  /**
   * @notice Fund a delegation using the `_delegator` stake.
   * @dev Callable only by the `_delegator` or a representative.
   * @dev Will revert if delegation does not exist.
   * @dev Will revert if `_amount` is greater than the staked amount.
   * @param _delegator Address of the delegator
   * @param _slot Slot of the delegation
   * @param _amount Amount of tickets to send to the delegation from the staked amount
   * @return The address of the Delegation
   */
  function fundDelegationFromStake(
    address _delegator,
    uint256 _slot,
    uint256 _amount
  ) external returns (Delegation) {
    _requireDelegatorOrRepresentative(_delegator);
    _requireAmountGtZero(_amount);

    Delegation _delegation = Delegation(_computeAddress(_delegator, _slot));

    _burn(_delegator, _amount);

    IERC20(ticket).safeTransfer(address(_delegation), _amount);

    emit DelegationFundedFromStake(_delegator, _slot, _amount, msg.sender);

    return _delegation;
  }

  /**
   * @notice Withdraw tickets from a delegation. The tickets will be held by this contract and the delegator's stake will increase.
   * @dev Only callable by the `_delegator` or a representative.
   * @dev Will send the tickets to this contract and increase the `_delegator` staked amount.
   * @dev Will revert if delegation is still locked.
   * @param _delegator Address of the delegator
   * @param _slot Slot of the delegation
   * @param _amount Amount of tickets to withdraw
   * @return The address of the Delegation
   */
  function withdrawDelegationToStake(
    address _delegator,
    uint256 _slot,
    uint256 _amount
  ) external returns (Delegation) {
    _requireDelegatorOrRepresentative(_delegator);

    Delegation _delegation = Delegation(_computeAddress(_delegator, _slot));

    _transfer(_delegation, address(this), _amount);

    _mint(_delegator, _amount);

    emit WithdrewDelegationToStake(_delegator, _slot, _amount, msg.sender);

    return _delegation;
  }

  /**
   * @notice Withdraw an `_amount` of tickets from a delegation. The delegator is assumed to be the caller.
   * @dev Tickets are sent directly to the passed `_to` address.
   * @dev Will revert if delegation is still locked.
   * @param _slot Slot of the delegation
   * @param _amount Amount to withdraw
   * @param _to Account to transfer the withdrawn tickets to
   * @return The address of the Delegation
   */
  function transferDelegationTo(
    uint256 _slot,
    uint256 _amount,
    address _to
  ) external returns (Delegation) {
    _requireRecipientNotZeroAddress(_to);

    Delegation _delegation = Delegation(_computeAddress(msg.sender, _slot));
    _transfer(_delegation, _to, _amount);

    emit TransferredDelegation(msg.sender, _slot, _amount, _to);

    return _delegation;
  }

  /**
   * @notice Allow an account to set or unset a `_representative` to handle delegation.
   * @dev If `_set` is `true`, `_representative` will be set as representative of `msg.sender`.
   * @dev If `_set` is `false`, `_representative` will be unset as representative of `msg.sender`.
   * @param _representative Address of the representative
   * @param _set Set or unset the representative
   */
  function setRepresentative(address _representative, bool _set) external {
    require(_representative != address(0), "TWABDelegator/rep-not-zero-addr");

    representatives[msg.sender][_representative] = _set;

    emit RepresentativeSet(msg.sender, _representative, _set);
  }

  /**
   * @notice Returns whether or not the given rep is a representative of the delegator.
   * @param _delegator The delegator
   * @param _representative The representative to check for
   * @return True if the rep is a rep, false otherwise
   */
  function isRepresentativeOf(address _delegator, address _representative)
    external
    view
    returns (bool)
  {
    return representatives[_delegator][_representative];
  }

  /**
   * @notice Allows a user to call multiple functions on the same contract.  Useful for EOA who wants to batch transactions.
   * @param _data An array of encoded function calls.  The calls must be abi-encoded calls to this contract.
   * @return The results from each function call
   */
  function multicall(bytes[] calldata _data) external returns (bytes[] memory) {
    return _multicall(_data);
  }

  /**
   * @notice Alow a user to approve ticket and run various calls in one transaction.
   * @param _amount Amount of tickets to approve
   * @param _permitSignature Permit signature
   * @param _data Datas to call with `functionDelegateCall`
   */
  function permitAndMulticall(
    uint256 _amount,
    Signature calldata _permitSignature,
    bytes[] calldata _data
  ) external {
    _permitAndMulticall(IERC20Permit(address(ticket)), _amount, _permitSignature, _data);
  }

  /**
   * @notice Allows the caller to easily get the details for a delegation.
   * @param _delegator The delegator address
   * @param _slot The delegation slot they are using
   * @return delegation The address that holds tickets for the delegation
   * @return delegatee The address that tickets are being delegated to
   * @return balance The balance of tickets in the delegation
   * @return lockUntil The timestamp at which the delegation unlocks
   * @return wasCreated Whether or not the delegation has been created
   */
  function getDelegation(address _delegator, uint256 _slot)
    external
    view
    returns (
      Delegation delegation,
      address delegatee,
      uint256 balance,
      uint256 lockUntil,
      bool wasCreated
    )
  {
    delegation = Delegation(_computeAddress(_delegator, _slot));
    wasCreated = address(delegation).isContract();
    delegatee = ticket.delegateOf(address(delegation));
    balance = ticket.balanceOf(address(delegation));

    if (wasCreated) {
      lockUntil = delegation.lockUntil();
    }
  }

  /**
   * @notice Computes the address of the delegation for the delegator + slot combination.
   * @param _delegator The user who is delegating tickets
   * @param _slot The delegation slot
   * @return The address of the delegation.  This is the address that holds the balance of tickets.
   */
  function computeDelegationAddress(address _delegator, uint256 _slot)
    external
    view
    returns (address)
  {
    return _computeAddress(_delegator, _slot);
  }

  /**
   * @notice Returns the ERC20 token decimals.
   * @dev This value is equal to the decimals of the ticket being delegated.
   * @return ERC20 token decimals
   */
  function decimals() public view virtual override returns (uint8) {
    return ERC20(address(ticket)).decimals();
  }

  /* ============ Internal Functions ============ */

  /**
   * @notice Computes the address of a delegation contract using the delegator and slot as a salt.
   The contract is a clone, also known as minimal proxy contract.
   * @param _delegator Address of the delegator
   * @param _slot Slot of the delegation
   * @return Address at which the delegation contract will be deployed
   */
  function _computeAddress(address _delegator, uint256 _slot) internal view returns (address) {
    return _computeAddress(_computeSalt(_delegator, bytes32(_slot)));
  }

  /**
   * @notice Computes the timestamp at which the delegation unlocks, after which the delegatee can be changed and tickets withdrawn.
   * @param _lockDuration The duration of the lock
   * @return The lock expiration timestamp
   */
  function _computeLockUntil(uint96 _lockDuration) internal view returns (uint96) {
    unchecked {
      return uint96(block.timestamp) + _lockDuration;
    }
  }

  /**
   * @notice Delegates tickets from the `_delegation` contract to the `_delegatee` address.
   * @param _delegation Address of the delegation contract
   * @param _delegatee Address of the delegatee
   */
  function _setDelegateeCall(Delegation _delegation, address _delegatee) internal {
    bytes4 _selector = ticket.delegate.selector;
    bytes memory _data = abi.encodeWithSelector(_selector, _delegatee);

    _executeCall(_delegation, _data);
  }

  /**
   * @notice Tranfers tickets from the Delegation contract to the `_to` address.
   * @param _delegation Address of the delegation contract
   * @param _to Address of the recipient
   * @param _amount Amount of tickets to transfer
   */
  function _transferCall(
    Delegation _delegation,
    address _to,
    uint256 _amount
  ) internal {
    bytes4 _selector = ticket.transfer.selector;
    bytes memory _data = abi.encodeWithSelector(_selector, _to, _amount);

    _executeCall(_delegation, _data);
  }

  /**
   * @notice Execute a function call on the delegation contract.
   * @param _delegation Address of the delegation contract
   * @param _data The call data that will be executed
   * @return The return datas from the calls
   */
  function _executeCall(Delegation _delegation, bytes memory _data)
    internal
    returns (bytes[] memory)
  {
    Delegation.Call[] memory _calls = new Delegation.Call[](1);
    _calls[0] = Delegation.Call({ to: address(ticket), data: _data });

    return _delegation.executeCalls(_calls);
  }

  /**
   * @notice Transfers tickets from a delegation contract to `_to`.
   * @param _delegation Address of the delegation contract
   * @param _to Address of the recipient
   * @param _amount Amount of tickets to transfer
   */
  function _transfer(
    Delegation _delegation,
    address _to,
    uint256 _amount
  ) internal {
    _requireAmountGtZero(_amount);
    _requireDelegationUnlocked(_delegation);

    _transferCall(_delegation, _to, _amount);
  }

  /* ============ Modifier/Require Functions ============ */

  /**
   * @notice Require to only allow the delegator or representative to call a function.
   * @param _delegator Address of the delegator
   */
  function _requireDelegatorOrRepresentative(address _delegator) internal view {
    require(
      _delegator == msg.sender || representatives[_delegator][msg.sender],
      "TWABDelegator/not-dlgtr-or-rep"
    );
  }

  /**
   * @notice Require to verify that `_delegatee` is not address zero.
   * @param _delegatee Address of the delegatee
   */
  function _requireDelegateeNotZeroAddress(address _delegatee) internal pure {
    require(_delegatee != address(0), "TWABDelegator/dlgt-not-zero-addr");
  }

  /**
   * @notice Require to verify that `_amount` is greater than 0.
   * @param _amount Amount to check
   */
  function _requireAmountGtZero(uint256 _amount) internal pure {
    require(_amount > 0, "TWABDelegator/amount-gt-zero");
  }

  /**
   * @notice Require to verify that `_to` is not address zero.
   * @param _to Address to check
   */
  function _requireRecipientNotZeroAddress(address _to) internal pure {
    require(_to != address(0), "TWABDelegator/to-not-zero-addr");
  }

  /**
   * @notice Require to verify if a `_delegation` is locked.
   * @param _delegation Delegation to check
   */
  function _requireDelegationUnlocked(Delegation _delegation) internal view {
    require(block.timestamp >= _delegation.lockUntil(), "TWABDelegator/delegation-locked");
  }

  /**
   * @notice Require to verify that a `_lockDuration` does not exceed the maximum lock duration.
   * @param _lockDuration Lock duration to check
   */
  function _requireLockDuration(uint256 _lockDuration) internal pure {
    require(_lockDuration <= MAX_LOCK, "TWABDelegator/lock-too-long");
  }
}
