// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Console.sol";
import "./BaseHelper.sol";

contract CurveHelper is BaseHelper {
  using Address for address;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  function swap(string memory /* path */, uint256 /* amount */, uint256 /* min */, address /* dest */) override external returns (uint256 swapped) {
    swapped = 0;
  }

}
