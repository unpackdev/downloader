// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

import "./ILiquidityDex.sol";
import "./IBancorNetwork.sol";
import "./IBancorContractRegistry.sol";
import "./IWETH.sol";
import "./console.sol";

contract BancorDex is ILiquidityDex, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IBancorContractRegistry public bancorRegistry = IBancorContractRegistry(0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4);
  bytes32 public bancorNetworkName = bytes32("BancorNetwork"); // "BancorNetwork"

  receive() external payable {}

  address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public bancorEth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  address public affiliateAccount = address(0);
  uint256 public affiliateFee = 0;

  constructor() public {
  }

  function getBancorNetworkContract() public returns(IBancorNetwork){
    return IBancorNetwork(bancorRegistry.addressOf(bancorNetworkName));
  }

  function configure(address newAffiliateAccount, uint256 newAffiliateFee) external onlyOwner {
    affiliateAccount = newAffiliateAccount;
    affiliateFee = newAffiliateFee;
  }

  // BancorDex's doSwap doesn't expect any address in the path to be bancorETH
  // they have to be regular tokens.
  function doSwap(
    uint256 amountIn,
    uint256 minAmountOut,
    address spender,
    address target,
    address[] memory path // only used for source and destination token
  ) public override returns(uint256) {
    address buyToken = path[path.length - 1];
    address sellToken = path[0];
    address finalTarget = target;

    IBancorNetwork network = getBancorNetworkContract();
    IERC20(sellToken).safeTransferFrom(spender, address(this), amountIn);

    if (sellToken == weth) {
      IWETH(weth).withdraw(amountIn);
      sellToken = bancorEth;
    } else {
      IERC20(sellToken).safeIncreaseAllowance(address(network), amountIn);
    }

    if (buyToken == weth) {
      buyToken = bancorEth;
      // we will be receiving eth here, and wrap it back to WETH
      target = address(this);
    }

    address[] memory actualPath = network.conversionPath(
      sellToken,
      buyToken
    );

    uint256 outTokenReturned = network.convertByPath{value: sellToken == bancorEth ? amountIn : 0}(
      actualPath,
      amountIn,
      minAmountOut,
      target, // beneficiary
      affiliateAccount,
      affiliateFee
    );

    // If buyToken is bancorEth, then this contract has received ETH after the swap.
    // ETH should be wrapped back to WETH
    if(buyToken == bancorEth) {
      uint256 ethBalance = address(this).balance;
      IWETH(weth).deposit{value: ethBalance}();
      outTokenReturned = IERC20(weth).balanceOf(address(this));
      IERC20(weth).safeTransfer(finalTarget, outTokenReturned);
    }

    return outTokenReturned;
  }

  // can receive ETH directly.
  fallback () payable external {}

}
