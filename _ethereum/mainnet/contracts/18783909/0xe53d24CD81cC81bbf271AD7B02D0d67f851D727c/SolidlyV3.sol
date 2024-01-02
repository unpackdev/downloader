// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;
pragma abicoder v2;

import "./Utils.sol";
import "./IWETH.sol";
import "./WethProvider.sol";
import "./ISolidlyV3Pool.sol";

abstract contract SolidlyV3 is WethProvider {
    struct SolidlyV3Data {
        address recipient;
        bool zeroForOne;
        uint160 sqrtPriceLimitX96;
    }

    function swapOnSolidlyV3(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address targetExchange,
        bytes calldata payload
    ) internal {
        SolidlyV3Data memory data = abi.decode(payload, (SolidlyV3Data));

        address _fromToken;

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
            _fromToken = WETH;
        } else {
            _fromToken = address(fromToken);
        }

        Utils.approve(address(targetExchange), address(_fromToken), fromAmount);

        ISolidlyV3Pool(targetExchange).swap(
            data.recipient,
            data.zeroForOne,
            int256(fromAmount),
            data.sqrtPriceLimitX96
        );

        if (address(toToken) == Utils.ethAddress()) {
            IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        }
    }

    function buyOnSolidlyV3(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address targetExchange,
        bytes calldata payload
    ) internal {
        SolidlyV3Data memory data = abi.decode(payload, (SolidlyV3Data));

        address _fromToken;

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
            _fromToken = WETH;
        } else {
            _fromToken = address(fromToken);
        }

        Utils.approve(address(targetExchange), _fromToken, fromAmount);

        ISolidlyV3Pool(targetExchange).swap(data.recipient, data.zeroForOne, int256(-toAmount), data.sqrtPriceLimitX96);

        if (address(fromToken) == Utils.ethAddress() || address(toToken) == Utils.ethAddress()) {
            IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        }
    }
}
