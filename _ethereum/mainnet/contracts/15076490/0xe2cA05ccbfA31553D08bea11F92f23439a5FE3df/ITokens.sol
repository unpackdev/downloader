// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

interface ITokens {
    function mint(
        bytes calldata blob,
        bytes32 metadata,
        address to
    ) external returns (uint256);

    function transfer(
        address from,
        address to,
        bytes calldata blob
    ) external;

    function hasRole(bytes32 role, address account) external returns (bool);
}
