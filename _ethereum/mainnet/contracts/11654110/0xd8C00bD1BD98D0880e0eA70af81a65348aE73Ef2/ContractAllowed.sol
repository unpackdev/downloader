// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IPool.sol";
import "./IERC20.sol";

contract ContractAllowed {
  ISynthereumPool public pool;
  IERC20 public collateral;

  constructor(address _pool, address _collateral) public {
    pool = ISynthereumPool(_pool);
    collateral = IERC20(_collateral);
  }

  function mintInPool(
    ISynthereumPool.MintParameters memory mintParams,
    ISynthereumPool.Signature memory signature,
    uint256 approveAmount
  ) external {
    collateral.approve(address(pool), approveAmount);
    pool.mint(mintParams, signature);
  }
}
