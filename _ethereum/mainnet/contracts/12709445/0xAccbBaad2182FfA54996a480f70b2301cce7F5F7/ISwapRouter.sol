// SPDX-License-Identifier: MIT
// @author: https://github.com/SHA-2048

pragma solidity ^0.8.0;

interface ISwapRouter {

    function weth() external returns(address);

    function swapExactTokensForTokens(
        address[] memory _path,
        uint _supplyTokenAmount,
        uint _minOutput
    ) external;

    function compound(
        address[] memory _path,
        uint _amount
    ) external;

}
