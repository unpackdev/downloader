// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @title Deri Protocol liquidator qualifier interface
 */
interface ILiquidatorQualifier {

    /**
     * @dev Check if `liquidator` is a qualified liquidator to call the `liquidate` function in PerpetualPool
     */
    function isQualifiedLiquidator(address liquidator) external view returns (bool);

}
