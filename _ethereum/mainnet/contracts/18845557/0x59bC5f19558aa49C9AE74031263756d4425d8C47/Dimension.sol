/*
  Website: https://www.dimensionai.io/
  Medium: https://medium.com/@dimensionai
  Docs: https://docs.dimensionai.io/
  Twitter: https://twitter.com/DimensionAIeth
  Telegram: https://t.me/dimensionportal
  ENS: dimensionai.eth
*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Dimension is ERC20 {
  constructor() public ERC20("Dimension", "DIM") {
      _mint(msg.sender, 1_000_000 * 10 ** 18);
  }
}
