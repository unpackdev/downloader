// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.6.2;

import "./Utilities.sol";

/// @notice This contract manages 'dripping assets' from a droplet and acts as a wrapper/gatekeeper
/// around the assets for `rollupBridge`.
/// The `rollupBridge` can only be set once and has an activation delay of `ACTIVATION_DELAY`.
contract DropletWrapper is Utilities {
  struct PendingChange {
    uint64 activationDate;
    address reserve;
  }

  /// @dev Address that can claim `SOURCE_TOKEN`.
  address rollupBridge;
  /// @dev Used for temporary state until `rollupBridge` is set.
  PendingChange public pendingChange;

  /// @dev Owner of this contract that can propose changes.
  function OWNER () internal view virtual returns (address) {
  }

  /// @dev The droplet this contract drips from.
  function DROPLET () internal view virtual returns (address) {
  }

  /// @dev The address of the ERC-20 token this contract manages.
  function SOURCE_TOKEN () internal view virtual returns (address) {
  }

  /// @dev How long (in seconds) we have to wait once the change of `rollupBridge` can be applied.
  function ACTIVATION_DELAY () internal view virtual returns (uint256) {
  }

  /// @notice Drips funds from `DROPLET` and calls `rollupBridge` with `data` as calldata.
  function execute (bytes calldata data) external {
    require(rollupBridge != address(0));

    // drip any funds
    IDroplet(DROPLET()).drip();
    // check balance
    uint256 balance = Utilities._safeBalance(SOURCE_TOKEN(), address(this));
    // approve
    Utilities._safeApprove(SOURCE_TOKEN(), rollupBridge, balance);

    (bool success,) = rollupBridge.call(data);
    require(success);
  }

  /// @notice Sets the `rollupBridge`. Must be called 2 times,
  /// once for initalization and afterwards for activation.
  /// This function also allows to overwrite a yet pending change.
  function setReserve (address reserve) external {
    require(msg.sender == OWNER());
    require(rollupBridge == address(0));
    require(reserve != address(0));

    PendingChange memory _pendingChange = pendingChange;
    if (_pendingChange.reserve == reserve) {
      require(block.timestamp >= _pendingChange.activationDate, 'EARLY');
      rollupBridge = reserve;
    } else {
      _pendingChange.reserve = reserve;
      _pendingChange.activationDate = uint64(block.timestamp + ACTIVATION_DELAY());
      // save
      pendingChange = _pendingChange;
    }
  }

  /// @notice Allows to recover `token` except `SOURCE_TOKEN`.
  /// Transfers `token` to `msg.sender`.
  /// @param token The address of the ERC-20 token to recover.
  function recoverLostTokens (address token) external {
    require(token != SOURCE_TOKEN());

    Utilities._safeTransfer(token, msg.sender, Utilities._safeBalance(token, address(this)));
  }
}
