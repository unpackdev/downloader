// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface INarwhalRouter {
  function WETH() external view returns (address);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function getAmountsOut(uint256 amountIn, bytes32[] calldata path) external view returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, bytes32[] calldata path) external view returns (uint256[] memory amounts);
}
