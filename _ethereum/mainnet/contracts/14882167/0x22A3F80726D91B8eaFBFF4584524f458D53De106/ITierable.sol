// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/** @title ITierable contract interface.
 */
interface ITierable {
    function tierOf(address account) external returns (int256);
}
