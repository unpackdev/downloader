// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

interface IProxyInitialize {
    function initialize(
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 amount,
        bool mintable,
        address owner
    ) external;
}
