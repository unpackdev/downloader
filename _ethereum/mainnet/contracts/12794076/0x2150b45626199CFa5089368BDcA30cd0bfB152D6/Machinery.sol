// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./EnumerableSet.sol";
import "./IMachinery.sol";
import "./IMechanicsRegistry.sol";

abstract
contract Machinery is IMachinery {
  using EnumerableSet for EnumerableSet.AddressSet;

  IMechanicsRegistry internal MechanicsRegistry;

  constructor(address _mechanicsRegistry) {
    _setMechanicsRegistry(_mechanicsRegistry);
  }

  function _setMechanicsRegistry(address _mechanicsRegistry) internal {
    MechanicsRegistry = IMechanicsRegistry(_mechanicsRegistry);
  }

  // View helpers
  function mechanicsRegistry() external view override returns (address _mechanicRegistry) {
    return address(MechanicsRegistry);
  }
  function isMechanic(address _mechanic) public view override returns (bool _isMechanic) {
    return MechanicsRegistry.isMechanic(_mechanic);
  }

}
