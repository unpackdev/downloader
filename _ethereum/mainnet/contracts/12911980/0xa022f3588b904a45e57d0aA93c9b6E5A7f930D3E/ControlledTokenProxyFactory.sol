// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./ProxyFactory.sol";
import "./ControlledToken.sol";

contract ControlledTokenProxyFactory is ProxyFactory {

  ControlledToken public instance;

  constructor () public {
    instance = new ControlledToken();
  }

  function create() external returns (ControlledToken) {
    return ControlledToken(deployMinimal(address(instance), ""));
  }
}
