// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "./ControlledSingleRecipientHarness.sol";
import "./ProxyFactory.sol";

/// @title Creates a minimal proxy to the ControlledSingleRecipient prize strategy.  Very cheap to deploy.
contract ControlledSingleRecipientHarnessProxyFactory is ProxyFactory {

  ControlledSingleRecipientHarness public instance;

  constructor () public {
    instance = new ControlledSingleRecipientHarness();
  }

  function create() external returns (ControlledSingleRecipientHarness) {
    return ControlledSingleRecipientHarness(deployMinimal(address(instance), ""));
  }

}