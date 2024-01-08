// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IBancorPair {
    function reserveBalances()
    external
    view
    returns (
      uint256 reserveBalance0,
      uint256 reserveBalance1
    );
    function reserveTokens()
    external
    view
    returns (
      address[] memory tokens
    );
}