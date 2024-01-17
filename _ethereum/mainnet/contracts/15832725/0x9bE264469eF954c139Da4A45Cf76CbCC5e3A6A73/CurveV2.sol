// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "./IERC20.sol";
import "./ICurveV2.sol";
import "./Utils.sol";
import "./IWETH.sol";
import "./WethProvider.sol";

abstract contract CurveV2 is WethProvider {
    enum CurveV2SwapType {
        EXCHANGE,
        EXCHANGE_UNDERLYING,
        EXCHANGE_GENERIC_FACTORY_ZAP
    }

    struct CurveV2Data {
        uint256 i;
        uint256 j;
        address originalPoolAddress;
        CurveV2SwapType swapType;
    }

    constructor() {}

    function swapOnCurveV2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        CurveV2Data memory curveV2Data = abi.decode(payload, (CurveV2Data));

        address _fromToken = address(fromToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
            _fromToken = WETH;
        }

        Utils.approve(address(exchange), address(_fromToken), fromAmount);
        if (curveV2Data.swapType == CurveV2SwapType.EXCHANGE) {
            ICurveV2Pool(exchange).exchange(curveV2Data.i, curveV2Data.j, fromAmount, 1);
        } else if (curveV2Data.swapType == CurveV2SwapType.EXCHANGE_UNDERLYING) {
            ICurveV2Pool(exchange).exchange_underlying(curveV2Data.i, curveV2Data.j, fromAmount, 1);
        } else if (curveV2Data.swapType == CurveV2SwapType.EXCHANGE_GENERIC_FACTORY_ZAP) {
            IGenericFactoryZap(exchange).exchange(
                curveV2Data.originalPoolAddress,
                curveV2Data.i,
                curveV2Data.j,
                fromAmount,
                1
            );
        }

        if (address(toToken) == Utils.ethAddress()) {
            uint256 receivedAmount = Utils.tokenBalance(WETH, address(this));
            IWETH(WETH).withdraw(receivedAmount);
        }
    }
}
