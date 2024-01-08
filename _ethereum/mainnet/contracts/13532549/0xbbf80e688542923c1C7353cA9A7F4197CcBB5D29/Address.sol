// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

library UpgradesAddress {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly { size := extcodesize(account) }
    return size > 0;
  }
}
