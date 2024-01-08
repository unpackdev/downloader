// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

import "./TransparentUpgradeableProxy.sol";

contract UniswapV2AccountantProxy is TransparentUpgradeableProxy {
  constructor(address _logic, address _proxyAdmin)
    public
    TransparentUpgradeableProxy(_logic, _proxyAdmin, '')
  {}
}
