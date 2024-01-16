// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IMMContract {
    // Returns the module type of the template.
    function contractType() external pure returns (bytes32);

    // Returns the version of the template.
    function contractVersion() external pure returns (uint8);
}
