// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

interface IPausable {
    function pause() external;
    function unpause() external;
}