// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "./IERC20.sol";
import "./IWETH.sol";
import "./LibOrderV2.sol";
import "./Utils.sol";
import "./LibBytes.sol";
import "./WethProvider.sol";

interface IZeroxV2 {
    function marketSellOrdersNoThrow(
        LibOrderV2.Order[] calldata orders,
        uint256 takerAssetFillAmount,
        bytes[] calldata signatures
    ) external returns (LibOrderV2.FillResults memory);
}

abstract contract ZeroxV2 is WethProvider {
    using LibBytes for bytes;

    struct ZeroxV2Data {
        LibOrderV2.Order[] orders;
        bytes[] signatures;
    }

    address public immutable erc20Proxy;

    constructor(address _erc20Proxy) {
        erc20Proxy = _erc20Proxy;
    }

    function swapOnZeroXv2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
        }

        _swapOn0xV2(fromToken, toToken, fromAmount, exchange, payload);
    }

    function buyOnZeroXv2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        address _fromToken = address(fromToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
            _fromToken = WETH;
        }

        _swapOn0xV2(fromToken, toToken, fromAmount, exchange, payload);

        if (address(fromToken) == Utils.ethAddress()) {
            uint256 remainingAmount = Utils.tokenBalance(address(_fromToken), address(this));
            if (remainingAmount > 0) {
                IWETH(WETH).withdraw(remainingAmount);
            }
        }
    }

    function _swapOn0xV2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes memory payload
    ) private {
        address _fromToken = address(fromToken);
        address _toToken = address(toToken);
        require(_fromToken != _toToken, "fromToken should be different from toToken");

        if (_fromToken == Utils.ethAddress()) {
            _fromToken = WETH;
        } else if (_toToken == Utils.ethAddress()) {
            _toToken = WETH;
        }

        ZeroxV2Data memory data = abi.decode(payload, (ZeroxV2Data));

        for (uint256 i = 0; i < data.orders.length; i++) {
            address srcToken = data.orders[i].takerAssetData.readAddress(16);
            require(srcToken == address(_fromToken), "Invalid from token!!");

            address destToken = data.orders[i].makerAssetData.readAddress(16);
            require(destToken == address(_toToken), "Invalid to token!!");
        }

        Utils.approve(erc20Proxy, address(_fromToken), fromAmount);

        IZeroxV2(exchange).marketSellOrdersNoThrow(data.orders, fromAmount, data.signatures);

        if (address(toToken) == Utils.ethAddress()) {
            uint256 receivedAmount = Utils.tokenBalance(WETH, address(this));
            IWETH(WETH).withdraw(receivedAmount);
        }
    }
}
