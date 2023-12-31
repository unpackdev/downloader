// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IPodsOracleUpgradeable.sol";
import "./WaterCommonStorage.sol";
import "./LibPrice.sol";

contract PodsOracleUpgradeable is IPodsOracleUpgradeable {

    /// @notice returns unharvestable pods price in BDV(based on BEAN price)
    /// @dev decimals of price is 18
    function latestPriceOfPods(
        uint256 placeInLine,
        uint256 pods
    ) external view returns (uint256 price) {
        uint256 podIndex = WaterCommonStorage.layout().beanstalk.podIndex();
        uint256 harvestableIndex = WaterCommonStorage.layout().beanstalk.harvestableIndex();
        price = LibPrice.getPriceOfPods(placeInLine, pods, podIndex, harvestableIndex);
    }

    /// @dev see {IPodsOracleUpgradeable} and {LibPrice}
    function priceOfPods(
        uint256 placeInLine,
        uint256 pods,
        uint256 podIndex,
        uint256 harvestableIndex
    ) external pure returns (uint256 price) {
        price = LibPrice.getPriceOfPods(placeInLine, pods, podIndex, harvestableIndex);
    }
}
