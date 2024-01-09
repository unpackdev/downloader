// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "./IGauge.sol";
import "./IERC20.sol";

// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase
contract GaugeMock is IGauge {
  address public override minter;

  address public override crv_token;

  address public override lp_token;

  uint256 public override totalSupply;

  mapping(address => uint256) public override balanceOf;

  constructor(
    address _minter,
    address _crvToken,
    address _lpToken
  ) {
    minter = _minter;
    crv_token = _crvToken;
    lp_token = _lpToken;
  }

  function deposit(uint256 amount, address recipient) public override {
    IERC20(lp_token).transferFrom(msg.sender, address(this), amount);
    balanceOf[recipient] += amount;
    totalSupply += amount;
  }

  function deposit(uint256 amount) external override {
    deposit(amount, msg.sender);
  }

  function withdraw(uint256 amount) external override {
    balanceOf[msg.sender] -= amount;
    totalSupply -= amount;
    IERC20(lp_token).transfer(msg.sender, amount);
  }
}
