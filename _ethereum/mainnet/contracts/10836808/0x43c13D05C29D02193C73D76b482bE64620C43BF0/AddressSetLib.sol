pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library AddressSetLib {
  struct AddressSet {
    mapping (address => bool) uniq;
    address[] set;
  }
  function insert(AddressSet storage addressSet, address item) internal {
    if (addressSet.uniq[item]) return;
    addressSet.set.push(item);
  }
  function get(AddressSet storage addressSet, uint256 i) internal view returns (address) {
    return addressSet.set[i];
  }
  function size(AddressSet storage addressSet) internal view returns (uint256) {
    return addressSet.set.length;
  }
}
