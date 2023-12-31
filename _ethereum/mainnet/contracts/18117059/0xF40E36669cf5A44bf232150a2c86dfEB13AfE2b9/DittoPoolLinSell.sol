// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./Fee.sol";
import "./DittoPoolLin.sol";
import "./CurveErrorCode.sol";
import "./NftCostData.sol";

import "./FixedPointMathLib.sol";

contract DittoPoolLinSell is DittoPoolLin {
    using FixedPointMathLib for uint256;

    ///@inheritdoc DittoPoolLin
    function bondingCurve() public pure override (DittoPoolLin) returns (string memory curve) {
        return "Curve: LINSELL";
    }

    /**
     * @dev See {DittPool-_getBuyInfo}
     */
    function _getBuyInfo(
        uint128, /*basePrice*/
        uint128, /*delta*/
        uint256, /*numItems*/
        bytes calldata /*swapData_*/,
        Fee memory /*fee_*/
    )
        internal
        pure
        override
        returns (
            CurveErrorCode error,
            uint128 newBasePrice,
            uint128 newDelta,
            uint256 inputValue,
            NftCostData[] memory nftCostData
        )
    {
        return (CurveErrorCode.BUY_NOT_SUPPORTED, 0, 0, 0, nftCostData);
    }
}
