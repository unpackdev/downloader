// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./Address.sol";

abstract contract Utils {
  using Address for address payable;
  error DestinationMissing();
  error FallbackNotAllowed();
  // fee = 0.729% Fee
  uint256 public constant feeDenominator = 100_000;
  uint256 public immutable feeNumerator;
  /**
   * where the fees will end up
   * @notice this address cannot be updated after it is set during constructor
   * @notice the destination must be payable + have a receive function
   * that has gas consumption less than limit
   */
  address payable public immutable destination;
  /**
   * the native address to deposit and withdraw from in the swap methods
   * @notice this address cannot be updated after it is set during constructor
   */
  address payable public immutable wNative;
  constructor(address payable _wNative, address payable _destination, uint256 _fee) {
    wNative = _wNative;
    destination = _destination;
    feeNumerator = _fee;
  }
  /** clamp the amount provided to a maximum, defaulting to provided maximum if 0 provided */
  function clamp(uint256 amount, uint256 max) pure public returns(uint256) {
    return _clamp(amount, max);
  }
  function _clamp(uint256 amount, uint256 max) internal pure returns(uint256) {
    return amount == 0 || amount > max ? max : amount;
  }

  receive() external payable {
    _receiveNative();
  }
  function _receiveNative() internal view {
    // the protocol thanks you for your donation
    if (destination == address(0)) {
      revert DestinationMissing();
    }
  }
}
