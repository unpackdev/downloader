// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum PriceFeedType {
    CHAINLINK_ORACLE,
    YEARN_ORACLE,
    CURVE_2LP_ORACLE,
    CURVE_3LP_ORACLE,
    CURVE_4LP_ORACLE,
    ZERO_ORACLE
}

interface IPriceFeedType {
    function priceFeedType() external returns (PriceFeedType);

    function dependsOnAddress() external returns (bool);
}
