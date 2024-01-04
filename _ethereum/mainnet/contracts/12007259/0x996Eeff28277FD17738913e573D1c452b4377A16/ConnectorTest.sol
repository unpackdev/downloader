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

/**
 * @title   Primitive Connector TEST
 * @author  Primitive
 * @notice  Low-level abstract contract for Primitive Connectors to inherit from.
 * @dev     @primitivefi/v1-connectors@v2.0.0
 */

import "./PrimitiveConnector.sol";

contract ConnectorTest is PrimitiveConnector {
    event Log(address indexed caller);

    constructor(address weth_, address primitiveRouter_)
        public
        PrimitiveConnector(weth_, primitiveRouter_)
    {}

    function depositETH() external payable returns (bool) {
        emit Log(getCaller());
        return _depositETH();
    }

    function withdrawETH() external returns (bool) {
        emit Log(getCaller());
        return _withdrawETH();
    }

    function transferFromCaller(address token, uint256 quantity) external returns (bool) {
        emit Log(getCaller());
        return _transferFromCaller(token, quantity);
    }

    function transferToCaller(address token) external returns (bool) {
        emit Log(getCaller());
        return _transferToCaller(token);
    }

    function transferFromCallerToReceiver(
        address token,
        uint256 quantity,
        address receiver
    ) external returns (bool) {
        emit Log(getCaller());
        return _transferFromCallerToReceiver(token, quantity, receiver);
    }

    function mintOptions(IOption optionToken, uint256 quantity)
        external
        returns (uint256, uint256)
    {
        emit Log(getCaller());
        _transferFromCaller(optionToken.getUnderlyingTokenAddress(), quantity);
        return _mintOptions(optionToken);
    }

    function mintOptionsToReceiver(
        IOption optionToken,
        uint256 quantity,
        address receiver
    ) external returns (uint256, uint256) {
        emit Log(getCaller());
        _transferFromCaller(optionToken.getUnderlyingTokenAddress(), quantity);
        return _mintOptionsToReceiver(optionToken, receiver);
    }

    function mintOptionsFromCaller(IOption optionToken, uint256 quantity)
        external
        returns (uint256, uint256)
    {
        emit Log(getCaller());
        return _mintOptionsFromCaller(optionToken, quantity);
    }

    function closeOptions(IOption optionToken, uint256 short) external returns (uint256) {
        emit Log(getCaller());
        _transferFromCaller(optionToken.redeemToken(), short);
        return _closeOptions(optionToken);
    }

    function exerciseOptions(
        IOption optionToken,
        uint256 amount,
        uint256 strikeAmount
    ) external returns (uint256, uint256) {
        _transferFromCaller(optionToken.getStrikeTokenAddress(), strikeAmount);
        _transferFromCaller(address(optionToken), amount);
        emit Log(getCaller());
        return _exerciseOptions(optionToken, amount);
    }

    function redeemOptions(IOption optionToken, uint256 short)
        external
        returns (uint256)
    {
        _transferFromCaller(optionToken.redeemToken(), short);
        emit Log(getCaller());
        return _redeemOptions(optionToken);
    }

    function transferBalanceToReceiver(address token, address receiver)
        external
        returns (uint256)
    {
        emit Log(getCaller());
        return _transferBalanceToReceiver(token, receiver);
    }
}
