// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISushimiToken {
    function burnFrom(
        address from,
        uint256 amount
    ) external;
}