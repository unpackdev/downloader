// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "./Bundle.sol";

contract BundleLR is Bundle {
  constructor(address _storage, address _underlying, address _vault) Bundle(_storage, _underlying, _vault) public {
  }
}
