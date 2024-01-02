// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IIDRegistry {
    function isWhitelisted(
        address account,
        bytes32 compliance
    ) external view returns (bool);

    function addToWhitelist(address account, bytes32 compliance) external;
}
