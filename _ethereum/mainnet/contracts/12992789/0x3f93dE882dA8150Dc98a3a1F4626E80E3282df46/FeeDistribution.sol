// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.6;

import "./FeeDistributionParams.sol";

contract FeeDistribution is FeeDistributionParams {

  event Distributed(uint exchangeRate);

  /**
    @notice minDuckAmount must be set to prevent sandwich attack
    @param usdpAmount The amount of USDP being swapped and distributed
    @param minDuckAmount The minimum amount of DUCK being distributed
  **/
  function swapAndDistribute(uint usdpAmount, uint minDuckAmount) public s returns(uint) {
    require(minDuckAmount != 0, "FeeDistribution: attackable by sandwich");

    // swap USDP to the most liquid stablecoin
    usdp.approve(address(crvUsdpPool), usdpAmount);
    uint stableAmount = crvUsdpPool.exchange_underlying(0, stableIndex, usdpAmount, 0);

    // swap stablecoin to WETH
    uint[] memory amounts = stableToWethRouter.swapExactTokensForTokens(stableAmount, 0, stableToWethPath(), address(this), block.timestamp);

    // swap WETH to DUCK
    uint wethAmount = amounts[amounts.length - 1];
    wethToDuckRouter.swapExactTokensForTokens(wethAmount, minDuckAmount, wethToDuckPath(), address(this), block.timestamp);

    uint duckAmount = duck.balanceOf(address(this));
    require(duckAmount >= minDuckAmount, "FeeDistribution: insufficient DUCK amount");

    duck.transfer(address(qDuck), duckAmount);

    emit Distributed(qDuck.getExchangeRate());

    return duckAmount;
  }

  // @dev This function should be manually changed to "view" in the ABI
  function viewDistribution() external returns(uint usdp_, uint duck_) {
    usdp_ = usdp.balanceOf(address(this));
    duck_ = swapAndDistribute(usdp_, 1);
  }
}
