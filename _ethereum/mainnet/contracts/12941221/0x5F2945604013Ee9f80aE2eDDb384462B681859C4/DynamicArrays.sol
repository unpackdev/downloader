// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

/**
 * @dev Library for handling dynamic in-memory arrays.
 *
 * There is a very good reason for Solidity not supporting this by default -- dynamic
 * arrays in memory completely break memory management for Solidity when used improperly;
 * however, they can be created manually in a safe way so long as the maximum size is known
 * beforehand.
 *
 * This applies primarily to situations where a subset is taken from an existing array
 * by some filtering process.
 *
 * This library should not be used to bypass Solidity's lack of dynamic memory array
 * support in any situation where the code could potentially cause the array to exceed
 * the maximum size assigned in the array creation call. Doing so is likely to have
 * unintended and unpredictable side effects.
 */
library DynamicArrays {
  /**
   * @dev Reserves space in memory for an array of length `size`, but sets the length to 0.
   * This can be safely used for a dynamic array so long as the maximum possible size is
   * known beforehand. If the array can exceed `size`, pushing to it will corrupt memory.
   */
  function dynamicAddressArray(uint256 size) internal pure returns (address[] memory arr) {
    arr = new address[](size);
    assembly { mstore(arr, 0) }
  }

  /**
   * @dev Reserves space in memory for an array of length `size`, but sets the length to 0.
   * This can be safely used for a dynamic array so long as the maximum possible size is
   * known beforehand. If the array can exceed length `size`, pushing to it will corrupt memory.
   */
  function dynamicUint256Array(uint256 size) internal pure returns (uint256[] memory arr) {
    arr = new uint256[](size);
    assembly { mstore(arr, 0) }
  }

  /**
   * @dev Pushes an address to an in-memory array by reassigning the array length and storing
   * the element in the position used by solidity for the current array index.
   * Note: This should ONLY be used on an array created with `dynamicAddressArray`. Using it
   * on a typical array created with `new address[]()` will almost certainly have unintended
   * and unpredictable side effects.
   */
  function dynamicPush(address[] memory arr, address element) internal pure {
    assembly {
      let size := mload(arr)
      let ptr := add(
        add(arr, 32),
        mul(size, 32)
      )
      mstore(ptr, element)
      mstore(arr, add(size, 1))
    }
  }

  /**
   * @dev Pushes a uint256 to an in-memory array by reassigning the array length and storing
   * the element in the position used by solidity for the current array index.
   * Note: This should ONLY be used on an array created with `dynamicUint256Array`. Using it
   * on a typical array created with `new uint256[]()` will almost certainly have unintended
   * and unpredictable side effects.
   */
  function dynamicPush(uint256[] memory arr, uint256 element) internal pure {
    assembly {
      let size := mload(arr)
      let ptr := add(
        add(arr, 32),
        mul(size, 32)
      )
      mstore(ptr, element)
      mstore(arr, add(size, 1))
    }
  }
}