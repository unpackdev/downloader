// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

interface IPermittableToken {
    function allowance(
        address holder,
        address spender
    )
        external
        view
        returns (uint256);

    function approve(
        address spender,
        uint256 value
    )
        external
        returns (bool);

    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external;

    function transfer(
        address to,
        uint256 value
    )
        external
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        external
        returns (bool);

    function balanceOf(
        address account
    )
        external
        view
        returns (uint256);
}
