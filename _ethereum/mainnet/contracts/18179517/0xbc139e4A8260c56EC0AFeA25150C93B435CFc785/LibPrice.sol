// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library LibPrice {
    /// @dev factor to consider decimals of price and BEAN
    /// 10 ^ (18 - 6)
    uint256 private constant BDV_FACTOR = 1e12;

    // getter for price
    /**
     * @notice Get price for any pods (decimals 18)
     * @param placeInLine with decimals 6
     * @param pods with decimals 6
     * @param podIndex with decimals 6
     * @param harvestableIndex with decimals 6
     * @return price pods price
     * @dev   pods price = (1 - (placeInLine + pods/2 - harvestableIndex)/(podIndex-harvestableIndex)) * pods
     */
    function getPriceOfPods(
        uint256 placeInLine,
        uint256 pods,
        uint256 podIndex,
        uint256 harvestableIndex
    ) internal pure returns (uint256) {
        uint256 unharvestable = podIndex - harvestableIndex;
        uint256 accumulatedPrice;
        if (unharvestable == 0 || placeInLine + pods <= harvestableIndex) {
            return pods * BDV_FACTOR;
        } else if (placeInLine <= harvestableIndex) {
            accumulatedPrice = (harvestableIndex - placeInLine) * BDV_FACTOR;
            pods -= (harvestableIndex - placeInLine);
            placeInLine = harvestableIndex;  
        }
        uint256 numerator = podIndex - placeInLine - pods / 2;
        return accumulatedPrice + ((numerator * pods) * BDV_FACTOR) / unharvestable;
    }
}
