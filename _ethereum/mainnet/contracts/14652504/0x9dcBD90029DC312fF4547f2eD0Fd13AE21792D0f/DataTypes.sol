// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library DataTypes {
    struct ReserveData {
        //this current state of the asset;
        bool isActive;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the last update time of the reserve
        uint40 lastUpdateTimestamp;
        //address of the ktoken
        address kTokenAddress;
        //address of the debt token
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        // Reserve factor
        uint16 factor;
        uint8 decimals;
        //the id of the reserve.Represents the position in the list of the active reserves.
        uint8 id;
    }
}
