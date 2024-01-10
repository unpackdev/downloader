// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./TransparentUpgradeableProxy.sol";
import "./DRIPBOND.sol";

contract DRIPBONDProxy is TransparentUpgradeableProxy {
  constructor() TransparentUpgradeableProxy(address(new DRIPBOND()), address(0xEBfE0Fd21208DC2e1321ACeFeE93904Ba8AEf743), abi.encodeWithSelector(DRIPBOND.initialize.selector)) {}
}
    
