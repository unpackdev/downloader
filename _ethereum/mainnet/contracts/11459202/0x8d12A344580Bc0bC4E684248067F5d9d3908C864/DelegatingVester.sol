// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeMath.sol";


contract DelegatingVester {
  /// @dev The name of this contract
  string public constant name = "Indexed Team Vesting Contract";

  using SafeMath for uint256;

  address public immutable ndx;

  uint256 public immutable vestingAmount;
  uint256 public immutable vestingBegin;
  uint256 public immutable vestingEnd;

  address public recipient;
  uint256 public lastUpdate;

  constructor(
    address ndx_,
    address recipient_,
    uint256 vestingAmount_,
    uint256 vestingBegin_,
    uint256 vestingEnd_
  ) public {
    require(
      vestingBegin_ >= block.timestamp,
      "DelegatingVester::constructor: vesting begin too early"
    );
    require(
      vestingEnd_ > vestingBegin_,
      "DelegatingVester::constructor: vesting end too early"
    );

    ndx = ndx_;
    recipient = recipient_;

    vestingAmount = vestingAmount_;
    vestingBegin = vestingBegin_;
    vestingEnd = vestingEnd_;

    lastUpdate = vestingBegin_;
  }

  function delegate(address delegatee) external {
    require(
      msg.sender == recipient,
      "DelegatingVester::delegate: unauthorized"
    );
    INdx(ndx).delegate(delegatee);
  }

  function setRecipient(address recipient_) external {
    require(
      msg.sender == recipient,
      "DelegatingVester::setRecipient: unauthorized"
    );
    recipient = recipient_;
  }

  function claim() external {
    uint256 amount;
    if (block.timestamp >= vestingEnd) {
      amount = INdx(ndx).balanceOf(address(this));
    } else {
      amount = vestingAmount.mul(block.timestamp - lastUpdate).div(
        vestingEnd - vestingBegin
      );
      lastUpdate = block.timestamp;
    }
    INdx(ndx).transfer(recipient, amount);
  }
}

interface INdx {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address dst, uint256 rawAmount) external returns (bool);
  function delegate(address delegatee) external;
}
