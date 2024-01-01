// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.22;

import "./IERC20.sol";

contract RecoverContract {
  address private constant _receiver = 0xC15E66eA086c82553859A2C62DB47e5270A137Ec;
  address private constant _usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  function recover() external {
    IERC20(_usdc).transfer(_receiver, IERC20(_usdc).balanceOf(address(this)));
  }
}
