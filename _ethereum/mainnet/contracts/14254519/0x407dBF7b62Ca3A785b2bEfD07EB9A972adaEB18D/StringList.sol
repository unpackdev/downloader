// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StringList {
  /**
   * @dev join list of strings with delimiter
   */
  function join(
    string[] memory list,
    string memory delimiter,
    bool skipEmpty
  ) internal pure returns (string memory) {
    if (list.length == 0) {
      return "";
    }
    string memory result = list[0];
    for (uint256 i = 1; i < list.length; i++) {
      if (skipEmpty && bytes(list[i]).length == 0) continue;
      result = string(abi.encodePacked(result, delimiter, list[i]));
    }
    return result;
  }

  /**
   * @dev concatenate two lists of strings
   */
  function concat(string[] memory list1, string[] memory list2)
    internal
    pure
    returns (string[] memory)
  {
    string[] memory result = new string[](list1.length + list2.length);
    for (uint256 i = 0; i < list1.length; i++) {
      result[i] = list1[i];
    }
    for (uint256 i = 0; i < list2.length; i++) {
      result[list1.length + i] = list2[i];
    }
    return result;
  }
}
