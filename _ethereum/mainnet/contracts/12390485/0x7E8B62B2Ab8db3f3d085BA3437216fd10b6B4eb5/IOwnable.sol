// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Interface of Ownable
 */
interface IOwnable {
    function owner() external view returns (address);
}
