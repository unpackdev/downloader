// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./IMinter.sol";

contract MinterMock is IMinter {
  IERC20 public crv;

  mapping(address => mapping(address => uint256)) public override minted;

  constructor(address _crv) {
    crv = IERC20(_crv);
  }

  function setMinted(
    address wallet,
    address gauge,
    uint256 amount
  ) external {
    minted[wallet][gauge] = amount;
  }

  function mint(address gauge) external override {
    uint256 amount = minted[msg.sender][gauge];
    minted[msg.sender][gauge] = 0;
    crv.transfer(msg.sender, amount);
  }
}
