// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";

abstract contract MapReducer is Ownable {

  using EnumerableSet for EnumerableSet.AddressSet;

  EnumerableSet.AddressSet private set;

  /// @notice Construct a new Reducer.
  /// @param set_ initial contracts to aggregate.
  constructor(address[] memory set_) {
    for (uint256 i = 0; i < set_.length; i++) {
      add(set_[i]);
    }
  }

  function add(address elem) public onlyOwner returns (bool) {
    require(sane(elem), "!sane");
    return set.add(elem);
  }

  function remove(address elem) public onlyOwner returns (bool) {
    return set.remove(elem);
  }

  function at(uint256 idx) external view returns (address) {
    return set.at(idx);
  }

  function size() external view returns (uint256) {
    return set.length();
  }

  function reduce(address ref) internal view returns (uint256 res) {
    for (uint256 i = 0; i < set.length(); i++) {
      res = SafeMath.add(res, map(set.at(i), ref));
    }
  }

  function sane(address) internal virtual view returns (bool) {
    return true;
  }

  function map(address elem, address ref) internal virtual view returns (uint256);
}