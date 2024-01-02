// SPDX-License-Identifier: MIT
// Derby Finance - 2022
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/utils/TokenTimelock.sol)

pragma solidity ^0.8.11;

import "./SafeERC20.sol";

import "./console.sol";

contract TokenTimelock {
  using SafeERC20 for IERC20;

  IERC20 private immutable token;

  address private beneficiary;
  address private immutable admin;

  uint256 public startTimestamp;
  uint256 public monthDuration;
  uint256 public tokensPerMonth;
  uint256 public claimed;

  bool public initialized;

  modifier onlyAdmin() {
    require(msg.sender == admin, "!admin");
    _;
  }

  modifier onlyBeneficiary() {
    require(msg.sender == beneficiary, "!beneficiary");
    _;
  }

  constructor(address _token) {
    admin = msg.sender;
    token = IERC20(_token);
  }

  function init(
    address _beneficiary,
    uint256 _amount,
    uint256 _startTimestamp, // timestamp after the cliff
    uint256 _numberOfMonths,
    uint256 _monthDurationUnix
  ) external onlyAdmin {
    require(!initialized, "already initialized");

    token.safeTransferFrom(msg.sender, address(this), _amount);

    startTimestamp = _startTimestamp;
    monthDuration = _monthDurationUnix; // unix // 1 month == 2629743
    beneficiary = _beneficiary;
    tokensPerMonth = _amount / _numberOfMonths;
    initialized = true;
  }

  function claimableTokens() public view returns (uint256) {
    require(initialized, "!initialized");
    if (startTimestamp > block.timestamp) return 0;

    uint256 timePassed = block.timestamp - startTimestamp;
    uint256 monthsPassed = timePassed / monthDuration;
    uint256 tokenBalance = token.balanceOf(address(this));
    uint256 amount = (monthsPassed * tokensPerMonth) - claimed + tokensPerMonth;
    uint256 tokens = amount > tokenBalance ? tokenBalance : amount;

    return tokens;
  }

  function release() external onlyBeneficiary {
    require(initialized, "!initialized");
    uint256 amount = claimableTokens();
    require(amount > 0, "Nothing to claim");

    claimed += amount;

    token.safeTransfer(beneficiary, amount);
  }
}
