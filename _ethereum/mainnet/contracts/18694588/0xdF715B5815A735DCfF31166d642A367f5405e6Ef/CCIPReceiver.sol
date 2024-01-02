// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./IAny2EVMMessageReceiver.sol";
import "./Client.sol";

/// @title CCIPReceiver - Base contract for CCIP applications that can receive messages.
abstract contract CCIPReceiver is IAny2EVMMessageReceiver {
  address internal router;
  address internal immutable linkToken;

  error InvalidRouter(address router);

  constructor(address _router, address _link) {
    router = _router;
    linkToken = _link;
  }

  /// @inheritdoc IAny2EVMMessageReceiver
  function ccipReceive(Client.Any2EVMMessage calldata message) external virtual override onlyRouter {
    _ccipReceive(message);
  }

  /// @notice Override this function in your implementation.
  /// @param message Any2EVMMessage
  function _ccipReceive(Client.Any2EVMMessage memory message) internal virtual;

  /////////////////////////////////////////////////////////////////////
  // Plumbing
  /////////////////////////////////////////////////////////////////////

  /// @notice Return the current router
  /// @return router address
  function getRouter() public view returns (address) {
    return router;
  }

  function _setRouter(address newRouter) internal {
    router = newRouter;
  }

  /// @dev only calls from the set router are accepted.
  modifier onlyRouter() {
    if (msg.sender != router) revert InvalidRouter(msg.sender);
    _;
  }
}
