// SPDX-License-Identifier: MIT

import "./TransparentUpgradeableProxy.sol";

pragma solidity ^0.6.0;

contract ProxyFactory {
  function build(
    address _impl,
    address proxyAdmin,
    bytes calldata _data
  ) external returns (address) {
    TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(_impl, proxyAdmin, _data);
    return address(proxy);
  }
}
