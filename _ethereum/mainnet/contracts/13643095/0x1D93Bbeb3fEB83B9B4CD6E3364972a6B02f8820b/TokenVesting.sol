// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Reference
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/drafts/TokenVesting.sol

// Adapted to the above compiler version

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period.
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event TokensReleased(address beneficiary, uint256 unreleased);

  event TokensRevoked(
    address beneficiary,
    address ownerWallet,
    uint256 currentBalance
  );

  // beneficiary of tokens after they are released
  address private immutable _beneficiary;

  // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
  uint256 private immutable _cliff;
  uint256 private immutable _start;
  uint256 private immutable _duration;

  IERC20 private immutable _token;

  uint256 private _released;

  bool private _revoked;

  /**
   * @dev Creates a vesting contract that vests its balance of the ERC20 token to the
   * beneficiary, gradually in a linear fashion until duration. By then all
   * of the balance will have vested.
   * @param beneficiary_ address of the beneficiary to whom vested tokens are transferred
   * @param cliffDuration_ duration in seconds of the cliff in which tokens will begin to vest
   * @param duration_ duration in seconds of the period in which the tokens will vest
   * @param token_ ERC20 token
   */
  constructor(
    address beneficiary_,
    uint256 cliffDuration_,
    uint256 duration_,
    IERC20 token_
  ) {
    require(
      beneficiary_ != address(0),
      "TokenVesting: beneficiary is the zero address"
    );
    // solhint-disable-next-line max-line-length
    require(
      cliffDuration_ <= duration_,
      "TokenVesting: cliff is longer than duration"
    );
    require(duration_ > 0, "TokenVesting: duration is 0");

    _beneficiary = beneficiary_;
    _duration = duration_;
    _start = block.timestamp; // start immediately
    _cliff = block.timestamp.add(cliffDuration_);

    _token = token_;
  }

  /**
   * @return the address of the token.
   */
  function tokenAddress() external view returns (address) {
    return address(_token);
  }

  /**
   * @return the beneficiary of the tokens.
   */
  function beneficiary() external view returns (address) {
    return _beneficiary;
  }

  /**
   * @return the cliff time of the token vesting.
   */
  function cliff() external view returns (uint256) {
    return _cliff;
  }

  /**
   * @return the start time of the token vesting.
   */
  function start() external view returns (uint256) {
    return _start;
  }

  /**
   * @return the duration of the token vesting.
   */
  function duration() external view returns (uint256) {
    return _duration;
  }

  /**
   * @return the amount of the token released.
   */
  function released() external view returns (uint256) {
    return _released;
  }

  /**
   * @return the token vesting revoked status.
   */
  function revoked() external view returns (bool) {
    return _revoked;
  }

  /**
   * @notice Revoke the token vesting and
   * also withdraw the remaining balance to the specified "ownerWallet"
   */
  function revokeTokenVesting(address ownerWallet) external onlyOwner {
    require(ownerWallet != address(0), "TokenVesting: invalid ownerWallet");

    _revoked = true;

    uint256 currentBalance = _token.balanceOf(address(this));
    if (currentBalance > 0) {
      _token.safeTransfer(ownerWallet, currentBalance);
    }

    emit TokensRevoked(_beneficiary, ownerWallet, currentBalance);
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   */
  function release() public {
    require(_revoked == false, "TokenVesting: revoked");

    uint256 unreleased = _releasableAmount();

    require(unreleased > 0, "TokenVesting: no tokens are due");

    _released = _released.add(unreleased);

    _token.safeTransfer(_beneficiary, unreleased);

    emit TokensReleased(_beneficiary, unreleased);
  }

  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   */
  function _releasableAmount() private view returns (uint256) {
    return _vestedAmount().sub(_released);
  }

  /**
   * @dev Calculates the amount that has already vested.
   */
  function _vestedAmount() private view returns (uint256) {
    uint256 currentBalance = _token.balanceOf(address(this));
    uint256 totalBalance = currentBalance.add(_released);

    if (block.timestamp < _cliff) {
      return 0;
    } else if (block.timestamp >= _start.add(_duration)) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(_start)).div(_duration);
    }
  }
}
