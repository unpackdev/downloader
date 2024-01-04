// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IPoolOnChainPriceFeed.sol";
import "./IERC20.sol";

contract ContractAllowedOnChanPriceFeed {
  ISynthereumPoolOnChainPriceFeed public pool;
  IERC20 public collateral;

  constructor(address _pool, address _collateral) public {
    pool = ISynthereumPoolOnChainPriceFeed(_pool);
    collateral = IERC20(_collateral);
  }

  function mintInPool(
    ISynthereumPoolOnChainPriceFeed.MintParams memory mintParams,
    uint256 approveAmount
  ) external {
    collateral.approve(address(pool), approveAmount);
    pool.mint(mintParams);
  }
}
