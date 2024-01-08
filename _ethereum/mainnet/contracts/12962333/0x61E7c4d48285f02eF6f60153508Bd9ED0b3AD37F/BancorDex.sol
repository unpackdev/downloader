// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

import "./ILiquidityDex.sol";
import "./IBancorNetwork.sol";

contract BancorDex is ILiquidityDex, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  receive() external payable {}

  address public bancorRouter;

  address public affiliateAccount = address(0);
  uint256 public affiliateFee = 0;

  constructor(address routerAddress) public {
    bancorRouter = routerAddress;
  }

  function configure(address newAffiliateAccount, uint256 newAffiliateFee) external onlyOwner {
    affiliateAccount = newAffiliateAccount;
    affiliateFee = newAffiliateFee;
  }

  function doSwap(
    uint256 amountIn,
    uint256 minAmountOut,
    address spender,
    address target,
    address[] memory path
  ) public override returns(uint256) {
    address sellToken = path[0];

    IERC20(sellToken).safeTransferFrom(spender, address(this), amountIn);
    IERC20(sellToken).safeIncreaseAllowance(bancorRouter, amountIn);

    uint256 outTokenReturned = IBancorNetwork(bancorRouter)
      .convertByPath(
        path,
        amountIn,
        minAmountOut,
        target, // beneficiary
        affiliateAccount,
        affiliateFee
      );

    return outTokenReturned;
  }
}
