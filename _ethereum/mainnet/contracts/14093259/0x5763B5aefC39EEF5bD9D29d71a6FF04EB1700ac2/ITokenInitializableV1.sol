// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ITokenInitializableV1 standard
 */
interface ITokenInitializableV1 {
    function initialize(
        string calldata name,
        string calldata symbol,
        uint8 decimalsValue,
        address minterAdmin,
        address minter
    ) external;
}
