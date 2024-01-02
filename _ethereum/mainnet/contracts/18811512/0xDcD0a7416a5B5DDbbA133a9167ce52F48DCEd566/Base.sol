// SPDX-License-Identifier: GPL-3.0

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./Module.sol";
import "./Wallet.sol";

pragma solidity ^0.8.19;

/// Allows configuration of modules and execution of transactions
contract Base is Wallet, Initializable, OwnableUpgradeable {
  /// The name of this contract
  string public constant name = "Federation Base v0.1";

  /// The max amount of blocks that a module can request a lock
  uint256 public maxLockDurationBlocks;

  /// Mapping of module lock requests
  mapping(address => uint256) internal _lock;

  /// Enabled modules
  mapping(address => bool) internal _enabled;

  /// Reverts if the sender is not an already enabled module
  modifier onlyEnabled() {
    if (!_enabled[msg.sender]) {
      revert NotEnabled();
    }

    _;
  }

  /// Do not leave implementation uninitialized
  constructor() {
    _disableInitializers();
  }

  /// Init wallet with owner and list of initial enabled modules and their config
  function initialize(address _owner) external initializer {
    __Ownable_init();

    maxLockDurationBlocks = 50_400; // ~7 day default @ 7200 blocks per day

    if (msg.sender != _owner) {
      _transferOwnership(_owner);
    }
  }

  /// Execute a transaction in this scope on behalf of an enabled module
  function execute(address _target, uint256 _value, bytes calldata _data)
    external
    onlyEnabled
    returns (bytes memory)
  {
    (bool success, bytes memory res) = _target.call{ value: _value }(_data);
    if (!success) {
      // the call reverted without a reason or a custom error
      if (res.length == 0) revert TransactionReverted();

      // bubble up errors from call
      assembly {
        revert(add(32, res), mload(res))
      }
    }

    emit ExecuteTransaction(msg.sender, _target, _value);

    return res;
  }

  /// Enables or disables a module
  function setModule(address _module, bool _enable) external onlyOwner {
    if (_enabled[_module] == _enable) {
      return;
    }

    // if we are disabling a module, revert if it holds an active lock
    if (!_enable && _lock[_module] > block.number) {
      revert LockActive();
    }

    _enabled[_module] = _enable;
    emit SetModule(_module, _enable);
  }

  /// Request a module lock for a certain about of blocks. Prevents disabling a
  /// module if it requires execution access to the wallet to complete an operation
  /// If a lock is already active, returns the amount of blocks left until released
  function requestLock(uint256 _blocks) external onlyEnabled returns (uint256) {
    if (_blocks > maxLockDurationBlocks) {
      revert LockDurationRequestTooLong();
    }

    uint256 endBlock = block.number + _blocks;

    // don't release locks earlier than a previous request from a module
    // otherwise the base wallet owner can grief modules by disabling them before
    // important operations need to occur
    if (_lock[msg.sender] > endBlock) {
      return _lock[msg.sender] - block.number;
    }

    _lock[msg.sender] = endBlock;
    emit RequestLock(msg.sender, endBlock);

    return endBlock;
  }

  /// Module request to release it's lock before the requested lock duration ends
  function releaseLock() external onlyEnabled {
    _lock[msg.sender] = 0;
    emit ReleaseLock(msg.sender);
  }

  /// Module request for checking if it has an active lock. Allows modules to
  /// to prevent certain operations to avoid griefing
  function hasActiveLock() external view onlyEnabled returns (bool) {
    return _lock[msg.sender] >= block.number;
  }

  /// Management function to update the max number of blocks a module lock can
  /// be claimed
  function setMaxLockDurationBlocks(uint256 _blocks) external onlyOwner {
    maxLockDurationBlocks = _blocks;
    emit MaxLockDurationBlocksChanged(_blocks);
  }

  /// Returns true if the module is enabled
  function moduleEnabled(address _module) external view returns (bool) {
    return _enabled[_module];
  }

  /// Can receive ETH
  receive() external payable { }
}
