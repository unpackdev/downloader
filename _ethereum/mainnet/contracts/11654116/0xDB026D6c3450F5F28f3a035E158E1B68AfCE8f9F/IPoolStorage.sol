// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./IPool.sol";
import "./IFinder.sol";
import "./EnumerableSet.sol";
import "./FixedPoint.sol";

interface ISynthereumPoolStorage {
  struct Storage {
    ISynthereumFinder finder;
    uint8 version;
    IERC20 collateralToken;
    IERC20 syntheticToken;
    bool isContractAllowed;
    EnumerableSet.AddressSet derivatives;
    FixedPoint.Unsigned startingCollateralization;
    ISynthereumPool.Fee fee;
    uint256 totalFeeProportions;
    mapping(address => uint256) nonces;
  }
}
