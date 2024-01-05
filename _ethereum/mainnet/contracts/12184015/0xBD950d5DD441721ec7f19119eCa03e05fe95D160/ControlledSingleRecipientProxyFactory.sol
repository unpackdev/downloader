// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "./ControlledSingleRecipient.sol";
import "./ProxyFactory.sol";

/// @title Creates a minimal proxy to the ControlledSingleRecipient prize strategy.  Very cheap to deploy.
contract ControlledSingleRecipientProxyFactory is ProxyFactory {

  ControlledSingleRecipient public instance;

  constructor () public {
    instance = new ControlledSingleRecipient();
  }

  function create() external returns (ControlledSingleRecipient) {
    return ControlledSingleRecipient(deployMinimal(address(instance), ""));
  }

}