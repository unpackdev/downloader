// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface ISeries {
    function initialize(
        address owner_,
        string memory name_
    ) external;

    function owner() external returns (address);
    function getName() external returns (string memory);
}