// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC20.sol";

/**

Create a token that implements the Chad burn.

 */
contract LightningBolt is ERC20 {
  address public uniswapV2Pair = 0x2DB071E62C052f9709F916A585cc9249D46Da778;

  constructor() ERC20("LightningBolt Token", "THUNDER", 18) {
    _mint(msg.sender, 1_000_000_000 * 1e18);
  }

  function burn(address from, uint256 amount) external {
    _burn(from, amount);
  }
}
