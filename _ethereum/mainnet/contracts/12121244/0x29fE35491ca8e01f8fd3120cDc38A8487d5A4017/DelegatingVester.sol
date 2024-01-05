// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "./SafeMath.sol";


/// @author Alchemy Team
/// @title DelegatingVester
contract DelegatingVester {
  /// @dev The name of this contract
  string public constant name = "Delegating Vesting Contract";

  using SafeMath for uint256;

  address public token;

  uint256 public vestingAmount;
  uint256 public vestingBegin;
  uint256 public vestingEnd;

  address public recipient;
  uint256 public lastUpdate;


  constructor() public {
    // Don't allow implementation to be initialized.
    token = address(1);
  }

  function initialize(
    address token_,
    address recipient_,
    uint256 vestingAmount_,
    uint256 vestingBegin_,
    uint256 vestingEnd_
  ) external
  {
    require(token == address(0), "already initialized");
    require(token_ != address(0), "factory can not be null");

    require(
      vestingBegin_ >= block.timestamp,
      "DelegatingVester::constructor: vesting begin too early"
    );
    require(
      vestingEnd_ > vestingBegin_,
      "DelegatingVester::constructor: vesting end too early"
    );

    token = token_;
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
    IToken(token).delegate(delegatee);
  }

  function setRecipient(address recipient_) external {
    require(
      msg.sender == recipient,
      "DelegatingVester::setRecipient: unauthorized"
    );
    recipient = recipient_;
  }

  function claim() public {
    uint256 amount;
    if (block.timestamp >= vestingEnd) {
      amount = IToken(token).balanceOf(address(this));
    } else {
      amount = vestingAmount.mul(block.timestamp - lastUpdate).div(
        vestingEnd - vestingBegin
      );
      lastUpdate = block.timestamp;
    }
    IToken(token).transfer(recipient, amount);
  }

  fallback() external payable {
    claim();
  }

  receive() external payable {
    claim();
  }
}

interface IToken {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address dst, uint256 rawAmount) external returns (bool);
  function delegate(address delegatee) external;
}