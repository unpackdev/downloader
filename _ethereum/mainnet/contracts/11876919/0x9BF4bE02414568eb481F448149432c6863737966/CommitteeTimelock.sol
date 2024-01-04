// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeMath.sol";

import "./ICommitteeTimelock.sol";


/**
 * @dev Timelock contract with an admin and superUser, where the admin
 * must wait for the timelock and the superUser can immediately execute
 * or cancel a transaction.
 *
 * The superUser is meant to be the timelock contract for a governance DAO,
 * while the admin is a committee with delegated power over some sensitive
 * function or assets.
 */
contract CommitteeTimelock is ICommitteeTimelock {
  using SafeMath for uint256;

  uint256 public constant override GRACE_PERIOD = 14 days;
  uint256 public constant override MINIMUM_DELAY = 2 days;
  uint256 public constant override MAXIMUM_DELAY = 30 days;

  address public immutable override superUser;

  address public override admin;
  address public override pendingAdmin;
  uint256 public override delay;

  modifier isAdmin {
    require(
      msg.sender == admin || msg.sender == superUser,
      "CommitteeTimelock::isAdmin: Call must come from admin or superUser."
    );
    _;
  }

  mapping(bytes32 => bool) public override queuedTransactions;

  constructor(address admin_, address superUser_, uint256 delay_) public {
    admin = admin_;
    superUser = superUser_;
    delay = delay_;
  }

  fallback() external payable {}

  function setDelay(uint256 delay_) public override {
    require(
      msg.sender == address(this),
      "CommitteeTimelock::setDelay: Call must come from Timelock."
    );
    require(
      delay_ >= MINIMUM_DELAY,
      "CommitteeTimelock::setDelay: Delay must exceed minimum delay."
    );
    require(
      delay_ <= MAXIMUM_DELAY,
      "CommitteeTimelock::setDelay: Delay must not exceed maximum delay."
    );
    delay = delay_;

    emit NewDelay(delay);
  }

  function acceptAdmin() public override {
    require(
      msg.sender == pendingAdmin,
      "CommitteeTimelock::acceptAdmin: Call must come from pendingAdmin."
    );
    admin = msg.sender;
    pendingAdmin = address(0);

    emit NewAdmin(admin);
  }

  function setPendingAdmin(address pendingAdmin_) public override {
    require(
      msg.sender == address(this),
      "CommitteeTimelock::setPendingAdmin: Call must come from Timelock."
    );
    pendingAdmin = pendingAdmin_;

    emit NewPendingAdmin(pendingAdmin);
  }

  function queueTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public override isAdmin returns (bytes32) {
    require(
      eta >= getBlockTimestamp().add(delay),
      "CommitteeTimelock::queueTransaction: Estimated execution block must satisfy delay."
    );
    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    require(
      queuedTransactions[txHash] == false,
      "CommitteeTimelock::queueTransaction: Transaction already queued."
    );
    queuedTransactions[txHash] = true;

    emit QueueTransaction(txHash, target, value, signature, data, eta);
    return txHash;
  }

  function cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public override isAdmin {
    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = false;

    emit CancelTransaction(txHash, target, value, signature, data, eta);
  }

  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public payable override isAdmin returns (bytes memory) {
    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    require(
      queuedTransactions[txHash],
      "CommitteeTimelock::executeTransaction: Transaction hasn't been queued."
    );
    require(
      getBlockTimestamp() >= eta,
      "CommitteeTimelock::executeTransaction: Transaction hasn't surpassed time lock."
    );
    require(
      getBlockTimestamp() <= eta.add(GRACE_PERIOD),
      "CommitteeTimelock::executeTransaction: Transaction is stale."
    );
    return _executeTransaction(
      txHash,
      target,
      value,
      signature,
      data,
      eta
    );
  }

  function sudo(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data
  ) public payable override returns (bytes memory) {
    require(msg.sender == superUser, "CommitteeTimelock::sudo: Caller is not superUser.");
    uint256 eta = now;
    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    return _executeTransaction(
      txHash,
      target,
      value,
      signature,
      data,
      eta
    );
  }

  function _executeTransaction(
    bytes32 txHash,
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) internal returns (bytes memory) {
    queuedTransactions[txHash] = false;

    bytes memory callData;

    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    (bool success, bytes memory returnData) = target.call{value: value}(callData);
    require(
      success,
      "CommitteeTimelock::executeTransaction: Transaction execution reverted."
    );

    emit ExecuteTransaction(txHash, target, value, signature, data, eta);

    return returnData;
  }

  function getBlockTimestamp() internal view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp;
  }
}
