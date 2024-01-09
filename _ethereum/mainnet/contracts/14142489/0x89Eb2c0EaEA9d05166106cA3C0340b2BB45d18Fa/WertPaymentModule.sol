// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.6;

import "./IUniswapV2Router02.sol";

contract WertPaymentModule {
  address public router;

  event TokenPurchased(
    address user,
    address token,
    uint256 amountIn,
    uint256 amountOut
  );

  constructor(address _router) public {
    require(_router != address(0), 'UniV2 Router address missing');
    router = _router;
  }

  /**
   * @notice purchase ERC20 token
   * @param _token  ETH amount
   * @param _to  receipient address
   * @return bool
   */
  function purchaseTokenFromETH(address _token, address _to)
    external
    payable
    returns (bool)
  {
    require(msg.value != 0, 'Insufficient ETH balance');

    address[] memory path = new address[](2);
    path[0] = IUniswapV2Router02(router).WETH();
    path[1] = _token;

    uint256[] memory swapResult;
    swapResult = IUniswapV2Router02(router).swapETHForExactTokens{
      value: msg.value
    }(
      IUniswapV2Router02(router).getAmountsOut(msg.value, path)[1], // amountOut
      path, // path
      _to, // recipient address
      block.timestamp + 1200 // deadline
    );

    emit TokenPurchased(msg.sender, _token, msg.value, swapResult[1]);
    return true;
  }
}
