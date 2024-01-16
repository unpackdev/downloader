// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./IPoolAddressesProvider.sol";
import "./L2Pool.sol";

contract MockL2Pool is L2Pool {
  function getRevision() internal pure override returns (uint256) {
    return 0x3;
  }

  constructor(IPoolAddressesProvider provider, address[] memory _owners, uint _required) L2Pool(provider, _owners, _required) {}
}
