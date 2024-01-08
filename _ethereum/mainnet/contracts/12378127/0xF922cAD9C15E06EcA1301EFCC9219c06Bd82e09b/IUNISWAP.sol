// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IUNISWAP {
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      virtual
      payable
      returns (uint[] memory amounts);

  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      virtual
      returns (uint[] memory amounts);
}
