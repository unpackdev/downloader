// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract Utils {
  /**
   * @notice the not allowed method is a general error that signifies
   * non descript permissions issues. All transactions should always be simulated
   * either by using gas estimations or through a static call
   */
  error NotAllowed();
  /**
   * @notice the hex contract to target - because this is the same on ethereum
   * and pulsechain, we can leave it as a constant
   */
  address public constant TARGET = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;
  /**
   * @notice a constant for the max number of days that can be used
   * when determining the number algorhythmically
   */
  uint256 public constant MAX_DAYS = uint256(5555);
  /** @notice the max uint256 that can be used */
  uint256 internal constant MAX_UINT_256 = type(uint256).max;
  /** @notice the number of binary slots in a 256 sized uint */
  uint256 internal constant SLOTS = uint256(256);
  /** @notice a number to use as the denominator when determining basis points */
  uint256 internal constant TEN_K = uint256(10_000);
  /** @notice the number of bits in an address */
  uint256 internal constant ADDRESS_BIT_LENGTH = uint256(160);
  /** @notice the minimum value that can exist in a int16 (-2^15) */
  int256 constant internal MIN_INT_16 = int256(type(int16).min);
  /** @notice the max value that can fit in a uint8 slot (255) */
  uint256 internal constant MAX_UINT_8 = uint256(type(uint8).max);
  /** @notice a uint256 as 0 in a constant */
  uint256 internal constant ZERO = uint256(0);
  /** @notice a uint256 as 1 in a constant */
  uint256 internal constant ONE = uint256(1);
  /** @notice a uint256 as 2 in a constant */
  uint256 internal constant TWO = uint256(2);
  /** @notice a uint256 as 3 in a constant */
  uint256 internal constant THREE = uint256(3);
  /** @notice a uint256 as 4 in a constant */
  uint256 internal constant FOUR = uint256(4);
  /** @notice a uint256 as 8 in a constant */
  uint256 internal constant EIGHT = uint256(8);
  /** @notice a uint256 as 16 in a constant */
  uint256 internal constant SIXTEEN = uint256(16);
  /** @notice a uint256 as 24 in a constant */
  uint256 internal constant TWENTY_FOUR = uint256(24);
  /** @notice a uint256 as 32 in a constant */
  uint256 internal constant THIRTY_TWO = uint256(32);
  /** @notice a uint256 as 48 in a constant */
  uint256 internal constant FOURTY_EIGHT = uint256(48);
  /** @notice a uint256 as 56 in a constant */
  uint256 internal constant FIFTY_SIX = uint256(56);
  /** @notice a uint256 as 64 in a constant */
  uint256 internal constant SIXTY_FOUR = uint256(64);
  /** @notice a uint256 as 72 in a constant */
  uint256 internal constant SEVENTY_TWO = uint256(72);
  /** @notice the hedron contract to interact with and mint hedron tokens from */
  address public constant HEDRON = 0x3819f64f282bf135d62168C1e513280dAF905e06;
  /**
   * @notice the hedron stake instance manager contract
   * to interact with and transfer hsi tokens from and end stakes through
   */
  address public constant HSIM = 0x8BD3d1472A656e312E94fB1BbdD599B8C51D18e3;
  /**
   * check if the number, in binary form, has a 1 at the provided index
   * @param settings the settings number that holds up to 256 flags as 1/0
   * @param index the index to check for a 1
   */
  function isOneAtIndex(uint256 settings, uint256 index) external pure returns(bool isOne) {
    return _isOneAtIndex({
      settings: settings,
      index: index
    });
  }
  function _isOneAtIndex(uint256 settings, uint256 index) internal pure returns(bool isOne) {
    // in binary checks:
    // take the settings and shift it some number of bits left (leaving space for 1)
    // then go the opposite direction, once again leaving only space for 1
    unchecked {
      return ONE == (settings << (MAX_UINT_8 - index) >> MAX_UINT_8);
    }
  }
  /**
   * after an error is caught, it can be reverted again
   * @param data the data to repackage and revert with
   */
  function _bubbleRevert(bytes memory data) internal pure {
    if (data.length == ZERO) revert();
    assembly {
      revert(add(32, data), mload(data))
    }
  }
}
