// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./FeedRegistryInterface.sol";

contract MockConsumer {
  FeedRegistryInterface private s_FeedRegistry;

  constructor(
    FeedRegistryInterface FeedRegistry
  ) {
    s_FeedRegistry = FeedRegistry;
  }

  function getFeedRegistry()
    public
    view
    returns (
      FeedRegistryInterface
    )
  {
    return s_FeedRegistry;
  }

  function read(
    address asset,
    address denomination
  )
    public
    view
    returns (
      int256
    )
  {
    return s_FeedRegistry.latestAnswer(asset, denomination);
  }
}
