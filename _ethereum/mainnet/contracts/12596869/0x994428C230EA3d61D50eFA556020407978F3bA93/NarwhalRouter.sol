// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./NarwhalLibrary.sol";
import "./TransferHelper.sol";
import "./INarwhalRouter.sol";
import "./IUniswapV2Factory.sol";
import "./IERC20.sol";
import "./IWETH.sol";


contract NarwhalRouter is INarwhalRouter {
  using TransferHelper for address;
  using NarwhalLibrary for bytes32;

  address public immutable override WETH;

  modifier ensure(uint256 deadline) {
    require(deadline >= block.timestamp, "NarwhalRouter: EXPIRED");
    _;
  }

  constructor(address _WETH) {
    WETH = _WETH;
  }

  receive() external payable {
    assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
  }

  // **** SWAP ****
  // requires the initial amount to have already been sent to the first pair
  function _swap(
    uint256[] memory amounts,
    bytes32[] memory path,
    address _to
  ) private {
    for (uint256 i; i < path.length; i++) {
      (bool zeroForOne, address pair) = path[i].unpack();
      uint256 amountOut = amounts[i + 1];
      (uint256 amount0Out, uint256 amount1Out) = zeroForOne ? (uint256(0), amountOut) : (amountOut, uint256(0));
      address to = i < path.length - 1 ? path[i + 1].readPair() : _to;
      IUniswapV2Pair(pair).swap(amount0Out, amount1Out, to, new bytes(0));
    }
  }

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external override ensure(deadline) returns (uint256[] memory amounts) {
    amounts = NarwhalLibrary.getAmountsOut(amountIn, path);
    require(amounts[amounts.length - 1] >= amountOutMin, "NarwhalRouter: INSUFFICIENT_OUTPUT");
    path[0].tokenIn().safeTransferFrom(
      msg.sender,
      path[0].readPair(),
      amounts[0]
    );
    _swap(amounts, path, to);
  }

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external override ensure(deadline) returns (uint256[] memory amounts) {
    amounts = NarwhalLibrary.getAmountsIn(amountOut, path);
    require(amounts[0] <= amountInMax, "NarwhalRouter: EXCESSIVE_INPUT");
    path[0].tokenIn().safeTransferFrom(
      msg.sender,
      path[0].readPair(),
      amounts[0]
    );
    _swap(amounts, path, to);
  }

  function swapExactETHForTokens(
    uint256 amountOutMin,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external payable override ensure(deadline) returns (uint256[] memory amounts) {
    require(path[0].tokenIn() == WETH, "NarwhalRouter: INVALID_PATH");
    amounts = NarwhalLibrary.getAmountsOut(msg.value, path);
    require(amounts[amounts.length - 1] >= amountOutMin, "NarwhalRouter: INSUFFICIENT_OUTPUT");
    IWETH(WETH).deposit{value: amounts[0]}();
    assert(IWETH(WETH).transfer(path[0].readPair(), amounts[0]));
    _swap(amounts, path, to);
  }

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external override ensure(deadline) returns (uint256[] memory amounts) {
    require(path[path.length - 1].tokenOut() == WETH, "NarwhalRouter: INVALID_PATH");
    amounts = NarwhalLibrary.getAmountsIn(amountOut, path);
    require(amounts[0] <= amountInMax, "NarwhalRouter: EXCESSIVE_INPUT");
    path[0].tokenIn().safeTransferFrom(
      msg.sender,
      path[0].readPair(),
      amounts[0]
    );
    _swap(amounts, path, address(this));
    IWETH(WETH).withdraw(amounts[amounts.length - 1]);
    TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
  }

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external override ensure(deadline) returns (uint256[] memory amounts) {
    require(path[path.length - 1].tokenOut() == WETH, "NarwhalRouter: INVALID_PATH");
    amounts = NarwhalLibrary.getAmountsOut(amountIn, path);
    require(amounts[amounts.length - 1] >= amountOutMin, "NarwhalRouter: INSUFFICIENT_OUTPUT");
    path[0].tokenIn().safeTransferFrom(
      msg.sender,
      path[0].readPair(),
      amounts[0]
    );
    _swap(amounts, path, address(this));
    IWETH(WETH).withdraw(amounts[amounts.length - 1]);
    TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
  }

  function swapETHForExactTokens(
    uint256 amountOut,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external payable override ensure(deadline) returns (uint256[] memory amounts) {
    require(path[0].tokenIn() == WETH, "NarwhalRouter: INVALID_PATH");
    amounts = NarwhalLibrary.getAmountsIn(amountOut, path);
    require(amounts[0] <= msg.value, "NarwhalRouter: EXCESSIVE_INPUT");
    IWETH(WETH).deposit{value: amounts[0]}();
    assert(IWETH(WETH).transfer(path[0].readPair(), amounts[0]));
    _swap(amounts, path, to);
    if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]); // refund dust eth, if any
  }

  function getAmountsOut(uint256 amountIn, bytes32[] memory path)
    public
    view
    override
    returns (uint256[] memory amounts)
  {
    return NarwhalLibrary.getAmountsOut(amountIn, path);
  }

  function getAmountsIn(uint256 amountOut, bytes32[] memory path)
    public
    view
    override
    returns (uint256[] memory amounts)
  {
    return NarwhalLibrary.getAmountsIn(amountOut, path);
  }
}
