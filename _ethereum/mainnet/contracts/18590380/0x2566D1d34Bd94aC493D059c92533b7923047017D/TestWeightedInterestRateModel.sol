// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./WeightedInterestRateModel.sol";

/**
 * @title Test Contract Wrapper for WeightedInterestRateModel
 * @author MetaStreet Labs
 */
contract TestWeightedInterestRateModel is WeightedInterestRateModel {
    /**************************************************************************/
    /* Constructor */
    /**************************************************************************/

    constructor(WeightedInterestRateModel.Parameters memory parameters) WeightedInterestRateModel(parameters) {}

    /**************************************************************************/
    /* Wrapper for Primary API */
    /**************************************************************************/

    /**
     * @dev External wrapper function for _rate()
     */
    function rate(
        uint256 amount,
        uint64[] memory rates,
        LiquidityLogic.NodeSource[] memory nodes,
        uint16 count
    ) external pure returns (uint256) {
        return _rate(amount, rates, nodes, count);
    }

    /**
     * @dev External wrapper function for _distribute()
     */
    function distribute(
        uint256 amount,
        uint256 interest,
        LiquidityLogic.NodeSource[] memory nodes,
        uint16 count
    ) external view returns (uint128[] memory) {
        _distribute(amount, interest, nodes, count);

        uint128[] memory pending = new uint128[](count);
        for (uint256 i; i < count; i++) {
            pending[i] = nodes[i].pending;
        }
        return pending;
    }
}
