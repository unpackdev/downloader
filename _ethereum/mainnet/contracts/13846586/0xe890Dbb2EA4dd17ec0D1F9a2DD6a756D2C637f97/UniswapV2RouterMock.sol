// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "./IERC20.sol";

// solhint-disable no-unused-vars
contract UniswapV2RouterMock {
  mapping(bytes32 => uint256[]) internal _amountsOut;
  address internal _pair;

  constructor(address pair) {
    _pair = pair;
  }

  function setAmountsOut(address[] calldata path, uint256[] calldata amountsOut) external {
    _amountsOut[keccak256(abi.encodePacked(path))] = amountsOut;
  }

  function getAmountsOut(uint256, address[] calldata path) external view returns (uint256[] memory amounts) {
    amounts = _amountsOut[keccak256(abi.encodePacked(path))];
  }

  function swapExactTokensForTokens(
    uint256,
    uint256,
    address[] calldata path,
    address,
    uint256
  ) external returns (uint256[] memory amounts) {
    amounts = _amountsOut[keccak256(abi.encodePacked(path))];
    IERC20(path[path.length - 1]).transfer(msg.sender, amounts[amounts.length - 1]);
  }

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256,
    uint256,
    address,
    uint256
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    )
  {
    IERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired);
    IERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired);
    amountA = amountADesired;
    amountB = amountBDesired;
    liquidity = IERC20(_pair).balanceOf(address(this));
    IERC20(_pair).transfer(msg.sender, liquidity);
  }
}
