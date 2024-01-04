// SPDX-License-Identifier: MIT
// Copyright 2021 Primitive Finance
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.2;

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IOption.sol";
import "./IERC20Permit.sol";

interface IPrimitiveSwaps {
    // ==== External Functions ====

    function openFlashLong(
        IOption optionToken,
        uint256 amountOptions,
        uint256 maxPremium
    ) external returns (bool);

    function openFlashLongWithPermit(
        IOption optionToken,
        uint256 amountOptions,
        uint256 maxPremium,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    function openFlashLongWithDAIPermit(
        IOption optionToken,
        uint256 amountOptions,
        uint256 maxPremium,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    function openFlashLongWithETH(IOption optionToken, uint256 amountOptions)
        external
        payable
        returns (bool);

    function closeFlashLong(
        IOption optionToken,
        uint256 amountRedeems,
        uint256 minPayout
    ) external returns (bool);

    function closeFlashLongForETH(
        IOption optionToken,
        uint256 amountRedeems,
        uint256 minPayout
    ) external returns (bool);

    // ===== Callback =====

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    // ==== View ====

    function getRouter() external view returns (IUniswapV2Router02);

    function getFactory() external view returns (IUniswapV2Factory);

    function getOptionPair(IOption option)
        external
        view
        returns (
            IUniswapV2Pair,
            address,
            address
        );

    function getOpenPremium(IOption optionToken, uint256 quantity)
        external
        view
        returns (uint256, uint256);

    function getClosePremium(IOption optionToken, uint256 quantity)
        external
        view
        returns (uint256, uint256);
}
