// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./Clones.sol";
import "./Address.sol";
import "./ICreatorLogicInitializer.sol";

contract ExchangeArtCreatorProxyFactory {
  event ProxyCreated(address proxy);

  // todo: perhaps use deterministic cloning here?

  constructor() {}

  function createProxy(
    address implementation,
    string memory name,
    string memory symbol
  ) external returns (address) {
    address proxy = Clones.clone(implementation);

    ICreatorLogicInitializer(proxy).initialize(name, symbol, msg.sender);

    emit ProxyCreated(proxy);

    return proxy;
  }
}
