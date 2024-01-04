//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./TransferHelper.sol";
import "./ITube.sol";
import "./IWETH.sol";
import "./ISwap.sol";
import "./UniswapV2Library.sol";

contract Swap is ISwap, Ownable {
  modifier ensure(uint deadline) {
    require(deadline >= block.timestamp, "Swap::expired");
    _;
  }

  address public factory;
  address public weth;

  constructor (
    address _weth,
    address _factory
  ) public {
    weth = _weth;
    factory = _factory;
  }

  function _swap(uint[] memory amounts, address[] memory path, address _to) private {
    for (uint i; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);
      (address token0,) = UniswapV2Library.sortTokens(input, output);
      uint amountOut = amounts[i + 1];
      (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
      address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
      IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
    }
  }

  function swap(
    address tube,
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable override ensure(deadline) returns (uint finalAmount) {
    ITube _tube = ITube(tube);
    uint256 tubeFee = _tube.depositFee();

    require(msg.value >= tubeFee, "Swap::swap::insufficient balance for tube fee");

    uint[] memory amounts;
    if (msg.value - tubeFee > 0) {
      require(path[0] == weth, "Swap::swap::invalid path");
      uint swapAmount = msg.value - tubeFee;
      amounts = UniswapV2Library.getAmountsOut(factory, swapAmount, path);
      require(amounts[amounts.length - 1] >= amountOutMin, "Swap::swap::insufficient output amount");
      amountIn = swapAmount;
      IWETH(weth).deposit{value: swapAmount}();
      assert(IWETH(weth).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
    } else {
      amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
      require(amounts[amounts.length - 1] >= amountOutMin, "Swap::swap::insufficient output amount");
      amountIn = amounts[0];
      TransferHelper.safeTransferFrom(
        path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
      );
    }
    
    _swap(amounts, path, address(this));

    finalAmount = amounts[path.length - 1];

    _deposit(_tube, tubeFee, path[path.length - 1], to, finalAmount);

    emit Swaped(msg.sender, path[0], path[path.length - 1], amountIn, finalAmount, to);
  }

  function _deposit(ITube tube, uint256 tubeFee, address token, address to, uint256 amount) internal {
    IERC20 finalToken = IERC20(token);
    uint256 allowance = finalToken.allowance(address(this), address(tube));
    if (allowance < amount) {
      require(finalToken.approve(address(tube), 2**256 - 1), "Swap::swap::approve token fail");
    }
  
    tube.depositTo{value: tubeFee}(token, to, amount); 
  }

  function quote(
    uint amountA,
    uint reserveA,
    uint reserveB
  ) public pure override returns (uint amountB) {
    return UniswapV2Library.quote(amountA, reserveA, reserveB);
  }

  function getAmountOut(
    uint amountIn,
    uint reserveIn,
    uint reserveOut
  ) public pure override returns (uint amountOut) {
    return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
  }

  function getAmountIn(
    uint amountOut,
    uint reserveIn,
    uint reserveOut
  ) public pure override returns (uint amountIn) {
    return UniswapV2Library.getAmountOut(amountOut, reserveIn, reserveOut);
  }

  function getAmountsOut(
    uint amountIn,
    address[] memory path
  ) public view override returns (uint[] memory amounts) {
    return UniswapV2Library.getAmountsOut(factory, amountIn, path);
  }

  function getAmountsIn(
    uint amountOut,
    address[] memory path
  ) public view override returns (uint[] memory amounts) {
    return UniswapV2Library.getAmountsIn(factory, amountOut, path);
  }

  function withdrawToken(
    address token,
    address to,
    uint256 amount
  ) external onlyOwner {
    TransferHelper.safeTransfer(token, to, amount);
  }

  function withdrawETH(
    address to,
    uint256 amount
  ) external onlyOwner {
    TransferHelper.safeTransferETH(to, amount);
  }
}
