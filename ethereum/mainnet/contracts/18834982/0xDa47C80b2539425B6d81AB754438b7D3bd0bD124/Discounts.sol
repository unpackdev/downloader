// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.23;

// This is developed with OpenZeppelin contracts v4.9.3.
import "./MathUpgradeable.sol";

library Discounts {
    // _______________ Structs _______________

    struct Discount {
        /*
         * The amount from which the `discountPercentage` per cent discount applies.
         *
         * Warning. `fromAmount` should include decimals.
         */
        uint256 fromAmount;
        // The discount amount in per cent for amounts starting from `fromAmount`.
        uint256 discountPercentage;
    }

    struct DiscountList {
        // This sequence should be sorted in ascending order of the `fromAmount` fields.
        Discount[] discounts;
    }

    // _______________ Constants _______________

    uint256 internal constant ONE_HUNDRED_PERCENT = 10000; // 100.00%.

    // _______________ Errors _______________

    error PercentageGTOneHundred(uint256 _discountPercentage, uint256 _oneHundredPercent);

    error AscendingOrderRequired(uint256 _prevIndex, uint256 _index);

    // _______________ Internal functions _______________

    /**
     * @notice Replaces the current discounts (`DiscountList.discounts`) with `_discounts`.
     *
     * Requirements:
     * - Each discount percentage should be less than or equal to `ONE_HUNDRED_PERCENT`.
     * - `_discounts` should be sorted in ascending order of the `fromAmount` and `discountPercentage` values.
     *
     * @param _list A `DiscountList` object or its storage pointer.
     * @param _discounts The ascending array of discounts to which the current discounts' array is replaced.
     */
    // prettier-ignore
    function setDiscounts(DiscountList storage _list, Discount[] calldata _discounts) internal {
        uint256 newSize = _discounts.length;
        uint256 i;
        if (newSize != 0) {
            for (i = 1; i < newSize; ++i)
                if (
                    _discounts[i - 1].fromAmount >= _discounts[i].fromAmount ||
                        _discounts[i - 1].discountPercentage >= _discounts[i].discountPercentage
                ) revert AscendingOrderRequired(i - 1, i);

            if (_discounts[newSize - 1].discountPercentage > ONE_HUNDRED_PERCENT)
                revert PercentageGTOneHundred(_discounts[newSize - 1].discountPercentage, ONE_HUNDRED_PERCENT);
        }

        uint256 size = _list.discounts.length;
        if (newSize >= size) {
            for (i = 0; i < size; ++i)
                _list.discounts[i] = _discounts[i];
            for (; i < newSize; ++i)
                _list.discounts.push(_discounts[i]);
        } else {
            for (i = 0; i < newSize; ++i)
                _list.discounts[i] = _discounts[i];
            for (; i < size; ++i)
                _list.discounts.pop();
        }
    }

    /**
     * Calculates `_price` discounted by `discountPercentage`% if there is a discount for `_amount`.
     *
     * @param _list It is a `DiscountList` object or its storage pointer.
     * @param _amount The amount for which the discount is calculated.
     * @param _price The price of `_amount`.
     *
     * @return `_price` discounted by `discountPercentage`%.
     */
    // prettier-ignore
    function calculateDiscountedPrice(
        DiscountList storage _list,
        uint256 _amount,
        uint256 _price
    ) internal view returns (uint256) {
        uint256 sz = _list.discounts.length;
        if (sz != 0 && _amount >= _list.discounts[0].fromAmount)
            for (uint256 i = sz - 1; i >= 0; --i)
                if (_amount >= _list.discounts[i].fromAmount)
                    return MathUpgradeable.mulDiv(
                        _price,
                        ONE_HUNDRED_PERCENT - _list.discounts[i].discountPercentage,
                        ONE_HUNDRED_PERCENT,
                        MathUpgradeable.Rounding.Up
                    );
        return _price;
    }

    function get(DiscountList storage _list) internal view returns (Discount[] memory) {
        return _list.discounts;
    }
}
