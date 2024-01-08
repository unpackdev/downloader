// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IUni {
    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external;
}