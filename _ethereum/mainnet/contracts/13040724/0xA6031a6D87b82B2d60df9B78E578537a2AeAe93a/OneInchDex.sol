pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ILiquidityDex.sol";
import "./IMooniSwap.sol";
import "./IWETH.sol";

contract OneInchDex is ILiquidityDex, Ownable {
  using SafeERC20 for IERC20;

  receive() external payable {}

  address public referral;
  address public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  address public oneInch = address(0x111111111117dC0aa78b770fA6A738034120C302);
  address public swise = address(0x48C3399719B582dD63eB5AADf12A40B4C3f52FA2);

  mapping(address => mapping(address => address)) public pools;

  constructor(address _referral) public {
    referral = _referral;
    pools[oneInch][swise] = address(0xcB0169060834b6Ff8B9BDC455a9c93c75A3c1F57);
    pools[swise][oneInch] = address(0xcB0169060834b6Ff8B9BDC455a9c93c75A3c1F57);
    pools[oneInch][weth] = address(0x0EF1B8a0E726Fc3948E15b23993015eB1627f210);
    pools[weth][oneInch] = address(0x0EF1B8a0E726Fc3948E15b23993015eB1627f210);
  }

  function changeReferral (address newReferral) external onlyOwner {
    referral = newReferral;
  }

  function changePool (address _token0, address _token1, address _pool) external onlyOwner {
    pools[_token0][_token1] = _pool;
    pools[_token1][_token0] = _pool;
  }

  function doSwap(
    uint256 amountIn,
    uint256 minAmountOut,
    address spender,
    address target,
    address[] memory path
  ) public override returns(uint256 result) {
    require(path.length == 2, "Only supports single swaps");
    address buyToken = path[1];
    address sellToken = path[0];

    address pool = pools[sellToken][buyToken];
    require(pool != address(0), "pool not set");

    IERC20(sellToken).safeTransferFrom(spender, address(this), amountIn);
    IERC20(sellToken).safeIncreaseAllowance(pool, amountIn);

    result = IMooniSwap(pool).swapFor{value: sellToken == weth ? amountIn : 0}
      (sellToken == weth ? address(0) : sellToken,
        buyToken == weth ? address(0) : buyToken,
        amountIn, minAmountOut, referral,
        buyToken == weth ? address(this) : payable(target)
      );

    if (buyToken == weth) {
      IWETH(weth).deposit{value: result}();
      IERC20(weth).safeTransfer(target, result);
    }
  }
}
