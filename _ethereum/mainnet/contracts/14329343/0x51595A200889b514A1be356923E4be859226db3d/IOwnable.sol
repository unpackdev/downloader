// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

interface IOwnable {
    function owner() external view returns (address);
    function renounceOwnership() external;
    function transferOwnership(address newOwner_) external;
}