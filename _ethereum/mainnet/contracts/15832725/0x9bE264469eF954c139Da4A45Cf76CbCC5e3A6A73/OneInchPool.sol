// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "./IERC20.sol";
import "./Utils.sol";
import "./IOneInchPool.sol";

contract OneInchPool {
    function swapOnOneInch(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange
    ) internal {
        address _fromToken = address(fromToken) == Utils.ethAddress() ? address(0) : address(fromToken);
        address _toToken = address(toToken) == Utils.ethAddress() ? address(0) : address(toToken);

        if (address(fromToken) != Utils.ethAddress()) {
            Utils.approve(address(exchange), _fromToken, fromAmount);
        }

        IOneInchPool(exchange).swap{ value: address(fromToken) == Utils.ethAddress() ? fromAmount : 0 }(
            IERC20(_fromToken),
            IERC20(_toToken),
            fromAmount,
            1,
            address(0)
        );
    }
}
