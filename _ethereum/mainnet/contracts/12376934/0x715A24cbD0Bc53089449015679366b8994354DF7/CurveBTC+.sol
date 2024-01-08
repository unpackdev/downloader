// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./CompositePlus.sol";

/**
 * @title CurveBTC+ token contract.
 * 
 * CurveBTC+ is a composite plus backed by a basket of Curve BTC CRV LPs,
 * including vault LPs backed by Curve BTC CRV.
 */
contract CurveBTCPlus is CompositePlus {

    /**
     * @dev Initializes the CurveBTC+ contract.
     */
    function initialize() public initializer {
        CompositePlus.initialize("Curve BTC Plus", "CurveBTC+");
    }
}