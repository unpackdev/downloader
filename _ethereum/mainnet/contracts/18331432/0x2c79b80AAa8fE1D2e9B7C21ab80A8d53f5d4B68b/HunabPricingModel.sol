// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./Math.sol";

/**
 * @title Hunab pricing model by the bonding curve.
 *
 * See details in https://hunab.gitbook.io/whitepaper/core-concept/bonding-curve.
 */
contract HunabPricingModel {
    using Math for uint256;

    // alpha = 1.625, that is 13/8
    uint256 public constant ALPHA_NUMERATOR = 13; // numerator of the alpha factor
    uint256 public constant ALPHA_DENOMINATOR = 8; // denominator of the alpha factor

    uint256 public constant BETA = 18000; // beta factor
    uint256 public constant GAMMA = 0; // gamma factor

    /**
     * @notice Get the mint price by the given total supply.
     * @param totalSupply The total supply
     * @return price The mint price
     */
    function getMintPrice(uint256 totalSupply) public pure returns (uint256) {
        // alpha = 1.625
        // x^alpha = x^1.625 = (x^13)^1/8 = (((x^13)^1/2)^1/2)^1/2
        return
            (((totalSupply + 1) ** ALPHA_NUMERATOR).sqrt().sqrt().sqrt() *
                10 ** 18).ceilDiv(BETA) + GAMMA;
    }

    /**
     * @notice Get the burn price by the given total supply.
     * @param totalSupply The total supply
     * @return price The burn price
     */
    function getBurnPrice(uint256 totalSupply) public pure returns (uint256) {
        // refer to `getMintPrice`
        return
            ((totalSupply ** ALPHA_NUMERATOR).sqrt().sqrt().sqrt() * 10 ** 18)
                .ceilDiv(BETA) + GAMMA;
    }

    /**
     * @notice Get the extractable fund for the Hunab Revolution contract during redemption.
     * @param redemptionIndex The redemption index
     * @return extractableFund The extractable fund
     */
    function getExtractableFund(
        uint256 redemptionIndex
    ) public pure returns (uint256) {
        // refer to `getMintPrice`
        return
            ((redemptionIndex ** ALPHA_NUMERATOR).sqrt().sqrt().sqrt() *
                10 ** 18).ceilDiv(BETA) + GAMMA;
    }
}
