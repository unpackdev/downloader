// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

import "./EnumerableSet.sol";
import "./LowGasSafeMath.sol";
import "./ITokenAdapter.sol";


library ArrayHelper {
  using EnumerableSet for EnumerableSet.AddressSet;
  using LowGasSafeMath for uint256;

/* ========== Type Cast ========== */

  /**
   * @dev Cast an enumerable address set as an address array.
   * The enumerable set library stores the values as a bytes32 array, this function
   * casts it as an address array with a pointer assignment.
   */
  function toArray(EnumerableSet.AddressSet storage set) internal view returns (address[] memory arr) {
    bytes32[] memory bytes32Arr = set._inner._values;
    assembly { arr := bytes32Arr }
  }

  /**
   * @dev Cast an array of IErc20Adapter to an array of address using a pointer assignment.
   * Note: The resulting array is the same as the original, so all changes to one will be
   * reflected in the other.
   */
  function toAddressArray(IErc20Adapter[] memory _arr) internal pure returns (address[] memory arr) {
    assembly { arr := _arr }
  }

/* ========== Math ========== */

  /**
   * @dev Computes the sum of a uint256 array.
   */
  function sum(uint256[] memory arr) internal pure returns (uint256 _sum) {
    uint256 len = arr.length;
    for (uint256 i; i < len; i++) _sum = _sum.add(arr[i]);
  }

/* ========== Removal ========== */

  /**
   * @dev Remove the element at `index` from an array and decrement its length.
   * If `index` is the last index in the array, pops it from the array.
   * Otherwise, stores the last element in the array at `index` and then pops the last element.
   */
  function mremove(uint256[] memory arr, uint256 index) internal pure {
    uint256 len = arr.length;
    if (index != len - 1) {
      uint256 last = arr[len - 1];
      arr[index] = last;
    }
    assembly { mstore(arr, sub(len, 1)) }
  }

  /**
   * @dev Remove the element at `index` from an array and decrement its length.
   * If `index` is the last index in the array, pops it from the array.
   * Otherwise, stores the last element in the array at `index` and then pops the last element.
   */
  function mremove(address[] memory arr, uint256 index) internal pure {
    uint256 len = arr.length;
    if (index != len - 1) {
      address last = arr[len - 1];
      arr[index] = last;
    }
    assembly { mstore(arr, sub(len, 1)) }
  }

  /**
   * @dev Remove the element at `index` from an array and decrement its length.
   * If `index` is the last index in the array, pops it from the array.
   * Otherwise, stores the last element in the array at `index` and then pops the last element.
   */
  function mremove(IErc20Adapter[] memory arr, uint256 index) internal pure {
    uint256 len = arr.length;
    if (index != len - 1) {
      IErc20Adapter last = arr[len - 1];
      arr[index] = last;
    }
    assembly { mstore(arr, sub(len, 1)) }
  }

  /**
   * @dev Remove the element at `index` from an array and decrement its length.
   * If `index` is the last index in the array, pops it from the array.
   * Otherwise, stores the last element in the array at `index` and then pops the last element.
   */
  function remove(bytes32[] storage arr, uint256 index) internal {
    uint256 len = arr.length;
    if (index == len - 1) {
      arr.pop();
      return;
    }
    bytes32 last = arr[len - 1];
    arr[index] = last;
    arr.pop();
  }

  /**
   * @dev Remove the element at `index` from an array and decrement its length.
   * If `index` is the last index in the array, pops it from the array.
   * Otherwise, stores the last element in the array at `index` and then pops the last element.
   */
  function remove(address[] storage arr, uint256 index) internal {
    uint256 len = arr.length;
    if (index == len - 1) {
      arr.pop();
      return;
    }
    address last = arr[len - 1];
    arr[index] = last;
    arr.pop();
  }

/* ========== Search ========== */

  /**
   * @dev Find the index of an address in an array.
   * If the address is not found, revert.
   */
  function indexOf(address[] memory arr, address find) internal pure returns (uint256) {
    uint256 len = arr.length;
    for (uint256 i; i < len; i++) if (arr[i] == find) return i;
    revert("element not found");
  }

  /**
   * @dev Determine whether an element is included in an array.
   */
  function includes(address[] memory arr, address find) internal pure returns (bool) {
    uint256 len = arr.length;
    for (uint256 i; i < len; i++) if (arr[i] == find) return true;
    return false;
  }

/* ========== Sorting ========== */

  /**
   * @dev Given an array of tokens and scores, sort by scores in descending order.
   * Maintains the relationship between elements of each array at the same index.
   */
  function sortByDescendingScore(
    address[] memory addresses,
    uint256[] memory scores
  ) internal pure {
    uint256 len = addresses.length;
    for (uint256 i = 0; i < len; i++) {
      uint256 score = scores[i];
      address _address = addresses[i];
      uint256 j = i - 1;
      while (int(j) >= 0 && scores[j] < score) {
        scores[j + 1] = scores[j];
        addresses[j + 1] = addresses[j];
        j--;
      }
      scores[j + 1] = score;
      addresses[j + 1] = _address;
    }
  }
}