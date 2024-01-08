/*
  .oooooo.              o8o                           o8o                     
 d8P'  `Y8b             `"'                           `"'                     
888           .ooooo.  oooo  ooo. .oo.   oooo    ooo oooo   .oooo.o  .ooooo.  
888          d88' `88b `888  `888P"Y88b   `88.  .8'  `888  d88(  "8 d88' `88b 
888          888   888  888   888   888    `88..8'    888  `"Y88b.  888ooo888 
`88b    ooo  888   888  888   888   888     `888'     888  o.  )88b 888    .o 
 `Y8bood8P'  `Y8bod8P' o888o o888o o888o     `8'     o888o 8""888P' `Y8bod8P' 
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./DateTime.sol";

/**
 * @title Vesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * creator.
 */
contract Vesting is Initializable {
  using SafeERC20 for IERC20;

  event Released(uint256 amount);
  event Revoked();

  address public creator;
  IERC20 public token;
  address public beneficiary;
  uint256 public start;
  uint256 public cliff;
  uint256 public releasePerMonth;
  uint256 public noOfMonths;

  uint256 public released = 0;
  bool public revoked = false;

  modifier onlyCreator() {
    require(msg.sender == creator, "ERR__UNAUTHORIZED");
    _;
  }

  constructor() initializer {}

  /**
   * @dev Initializes a vesting contract that vests its balance of an ERC20 token to the
   * _beneficiary, gradually in a step fashion until _start + _noOfMonths. By then all
   * of the balance will have vested.
   * @param _token address of the token to be held
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _start timestamp in seconds at which vesting starts
   * @param _cliff cliff period in months during which tokens will be locked
   * @param _totalTokens total number of tokens to vest
   * @param _noOfMonths total number of months in the vesting period
   */
  function initialize(
    address _creator,
    address _token,
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _totalTokens,
    uint256 _noOfMonths
  ) public initializer {
    require(
      _beneficiary != address(0),
      "ERR__BENEFICIARY_CANNOT_BE_ZERO_ADDRESS"
    );
    require(
      _cliff <= _noOfMonths,
      "ERR__CLIFF_CANNOT_BE_GREATER_THAN_TOTAL_MONTHS"
    );
    require(
      IERC20(_token).balanceOf(_creator) >= _totalTokens,
      "ERR__INSUFFICIENT_TOKEN_BALANCE"
    );

    creator = _creator;
    token = IERC20(_token);
    beneficiary = _beneficiary;
    start = _start;
    cliff = DateTime.addMonths(_start, _cliff);
    releasePerMonth = _totalTokens / _noOfMonths;
    noOfMonths = _noOfMonths;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   */
  function release() public {
    uint256 unreleased = releasableAmount();
    require(unreleased > 0, "ERR__ZERO_RELEASABLE_TOKENS");
    released = released + (unreleased);
    token.safeTransfer(beneficiary, unreleased);
    emit Released(unreleased);
  }

  /**
   * @notice Allows the creator to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the creator.
   */
  function revoke() public onlyCreator {
    require(!revoked, "ERR__ALREADY_REVOKED");
    uint256 balance = token.balanceOf(address(this));
    uint256 unreleased = releasableAmount();
    uint256 refund = balance - unreleased;
    revoked = true;
    token.safeTransfer(creator, refund);
    emit Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   */
  function releasableAmount() public view returns (uint256) {
    return vestedAmount() - released;
  }

  /**
   * @dev Calculates the amount that has already vested.
   */
  function vestedAmount() public view returns (uint256) {
    if (block.timestamp < cliff) {
      // if cliff has not passed, return 0
      return 0;
    } else if (
      block.timestamp >= DateTime.addMonths(start, noOfMonths) || revoked
    ) {
      // if vesting is complete, or vesting is revoked, return remaining balance (releasableAmount) + released
      return token.balanceOf(address(this)) + released;
    } else {
      // if in between vesting, return releasePerMonth * no. of months passed from the start of vesting
      return releasePerMonth * (DateTime.diffMonths(start, block.timestamp));
    }
  }

  /**
   * @dev Calculates the timestamp when next batch of tokens will be unlocked
   */
  function nextUnlock() public view returns (uint256) {
    if (block.timestamp < cliff) {
      // if cliff has not passed, return cliff
      return cliff;
    } else if (block.timestamp >= DateTime.addMonths(start, noOfMonths)) {
      // if vesting is complete, return last unlock date i.e, last vesting date
      return DateTime.addMonths(start, noOfMonths);
    } else {
      // if in between vesting, return start + months passed + 1
      uint256 monthsPassed = DateTime.diffMonths(start, block.timestamp);
      return DateTime.addMonths(start, monthsPassed + 1);
    }
  }
}
