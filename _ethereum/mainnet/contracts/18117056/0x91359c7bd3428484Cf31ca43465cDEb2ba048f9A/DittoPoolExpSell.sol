// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./Fee.sol";
import "./DittoPoolExp.sol";
import "./CurveErrorCode.sol";
import "./NftCostData.sol";

import "./FixedPointMathLib.sol";

contract DittoPoolExpSell is DittoPoolExp {
    using FixedPointMathLib for uint256;

    ///@inheritdoc DittoPoolExp
    function bondingCurve() public pure override (DittoPoolExp) returns (string memory curve) {
        return "Curve: EXPSELL";
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
        // NOTE: we assume delta is > 1, as checked by validateDelta()
        return (CurveErrorCode.BUY_NOT_SUPPORTED, 0, 0, 0, nftCostData);
    }
}
