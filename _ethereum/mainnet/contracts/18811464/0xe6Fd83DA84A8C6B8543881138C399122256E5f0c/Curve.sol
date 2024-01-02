//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./ICurve.sol";
import "./LibAsset.sol";
import "./IERC20.sol";

contract Curve {
    struct CurveData {
        int128 i;
        int128 j;
        uint256 deadline;
        bool underlyingSwap;
    }

    function swapOnCurve(
        address fromToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        CurveData memory curveData = abi.decode(payload, (CurveData));
    
        LibAsset.approveERC20(IERC20(fromToken), exchange, fromAmount);
        
        if (curveData.underlyingSwap) {
            ICurvePool(exchange).exchange_underlying(curveData.i, curveData.j, fromAmount, 1);
        } else {
            ICurvePool(exchange).exchange(curveData.i, curveData.j, fromAmount, 1);
        }
    }

    function quoteOnCurve(
        address,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal view returns(uint256){
        CurveData memory curveData = abi.decode(payload, (CurveData));
        return ICurvePool(exchange).get_dy(curveData.i, curveData.j, fromAmount);
    }
}