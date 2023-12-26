// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "./IERC20.sol";

interface IPiteasRouter {
  struct Detail {
        IERC20 srcToken;
        IERC20 destToken;
        address payable destAccount;
        uint256 srcAmount;
        uint256 destMinAmount;
    }

  function swap(
    Detail memory detail,
    bytes calldata data)
    external payable returns (uint256);
}
