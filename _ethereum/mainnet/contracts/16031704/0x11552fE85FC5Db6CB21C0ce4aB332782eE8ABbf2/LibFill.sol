// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LibOrder.sol";
import "./SafeMathUpgradeable.sol";
import "./MathUpgradeable.sol";

library LibFill {
    using SafeMathUpgradeable for uint256;

    struct FillResult {
        uint256 leftValue;
        uint256 rightValue;
    }

    /**
     * @dev Should return filled values
     * @param leftOrder left order
     * @param rightOrder right order
     * @param leftOrderFill current fill of the left order (0 if order is unfilled)
     * @param rightOrderFill current fill of the right order (0 if order is unfilled)
     * @param leftIsMakeFill true if left orders fill is calculated from the make side, false if from the take side
     * @param rightIsMakeFill true if right orders fill is calculated from the make side, false if from the take side
     */
    function _fillOrder(
        LibOrder.Order calldata leftOrder,
        LibOrder.Order calldata rightOrder,
        uint256 leftOrderFill,
        uint256 rightOrderFill,
        bool leftIsMakeFill,
        bool rightIsMakeFill
    ) internal view returns (FillResult memory) {
        (uint256 leftMakeValue, uint256 leftTakeValue) = LibOrder
            ._calculateRemaining(leftOrder, leftOrderFill, leftIsMakeFill);
        (uint256 rightMakeValue, uint256 rightTakeValue) = LibOrder
            ._calculateRemaining(rightOrder, rightOrderFill, rightIsMakeFill);

        //We have 2 cases here:
        if (rightTakeValue > leftMakeValue) {
            //1nd: left order should be fully filled
            return
                _fillLeft(
                    leftMakeValue,
                    leftTakeValue,
                    rightOrder.makeAsset.value,
                    rightOrder.takeAsset.value
                );
        } //2st: right order should be fully filled or 3d: both should be fully filled if required values are the same
        return
            _fillRight(
                leftOrder.makeAsset.value,
                leftOrder.takeAsset.value,
                rightMakeValue,
                rightTakeValue,
                leftOrder
            );
    }

    function _fillRight(
        uint256 leftMakeValue,
        uint256 leftTakeValue,
        uint256 rightMakeValue,
        uint256 rightTakeValue,
        LibOrder.Order calldata leftOrder
    ) internal view returns (FillResult memory result) {
        uint256 makerValue = LibMath._safeGetPartialAmountFloor(
            rightTakeValue,
            leftMakeValue,
            leftTakeValue
        );
        // check if it is the seller accepted offer
        if (msg.sender == leftOrder.maker) {
            return FillResult(rightTakeValue, rightMakeValue);
        }

        require(makerValue <= rightMakeValue, "_fillRight: unable to fill");
        return FillResult(rightTakeValue, makerValue);
    }

    function _fillLeft(
        uint256 leftMakeValue,
        uint256 leftTakeValue,
        uint256 rightMakeValue,
        uint256 rightTakeValue
    ) internal pure returns (FillResult memory result) {
        uint256 rightTake = LibMath._safeGetPartialAmountFloor(
            leftTakeValue,
            rightMakeValue,
            rightTakeValue
        );
        require(rightTake <= leftMakeValue, "_fillLeft: unable to fill");
        return FillResult(leftMakeValue, leftTakeValue);
    }

    function _fillAuctionOrder(
        LibOrder.Order calldata leftOrder,
        LibOrder.Order calldata rightOrder,
        uint256 leftOrderFill,
        uint256 rightOrderFill,
        bool leftIsMakeFill,
        bool rightIsMakeFill
    ) internal pure returns (FillResult memory) {
        (uint256 leftMakeValue, uint256 leftTakeValue) = LibOrder
            ._calculateRemaining(leftOrder, leftOrderFill, leftIsMakeFill);
        (uint256 rightMakeValue, uint256 rightTakeValue) = LibOrder
            ._calculateRemaining(rightOrder, rightOrderFill, rightIsMakeFill);
        require(leftTakeValue <= rightMakeValue, "Lower than reserved price");
        uint256 makerValue = LibMath._safeGetPartialAmountFloor(
            rightTakeValue,
            leftMakeValue,
            rightMakeValue
        );
        require(
            makerValue <= rightMakeValue,
            "fillAuctionOrder: unable to fill"
        );

        return FillResult(rightTakeValue, rightMakeValue);
    }
}
