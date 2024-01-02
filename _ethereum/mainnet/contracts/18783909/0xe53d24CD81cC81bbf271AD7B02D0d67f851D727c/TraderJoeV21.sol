// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "./IERC20.sol";
import "./IWETH.sol";
import "./WethProvider.sol";
import "./ITraderJoeV21Router.sol";
import "./Utils.sol";

abstract contract TraderJoeV21 is WethProvider {
    struct PartialJoeV21Param {
        ITraderJoeV21Router.RouterPath path;
        uint256 _deadline;
    }

    function swapOnTraderJoeV21(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        PartialJoeV21Param memory data = abi.decode(payload, (PartialJoeV21Param));

        address _fromToken;

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
            _fromToken = WETH;
        } else {
            _fromToken = address(fromToken);
        }

        Utils.approve(address(exchange), _fromToken, fromAmount);

        ITraderJoeV21Router(exchange).swapExactTokensForTokens(fromAmount, 1, data.path, address(this), data._deadline);

        if (address(toToken) == Utils.ethAddress()) {
            IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        }
    }

    function buyOnTraderJoeV21(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        PartialJoeV21Param memory data = abi.decode(payload, (PartialJoeV21Param));

        address _fromToken;

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
            _fromToken = WETH;
        } else {
            _fromToken = address(fromToken);
        }

        Utils.approve(address(exchange), _fromToken, fromAmount);

        ITraderJoeV21Router(exchange).swapTokensForExactTokens(
            toAmount,
            fromAmount,
            data.path,
            address(this),
            data._deadline
        );

        if (address(fromToken) == Utils.ethAddress() || address(toToken) == Utils.ethAddress()) {
            IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        }
    }
}
