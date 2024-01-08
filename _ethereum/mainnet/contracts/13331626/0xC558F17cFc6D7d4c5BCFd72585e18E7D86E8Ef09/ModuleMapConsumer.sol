// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./IModuleMap.sol";

abstract contract ModuleMapConsumer is Initializable {
  IModuleMap public moduleMap;

  function __ModuleMapConsumer_init(address moduleMap_) internal initializer {
    moduleMap = IModuleMap(moduleMap_);
  }
}
