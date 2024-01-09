// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./OracleCommon.sol";
import "./IERC20Extended.sol";

/**
 @notice Returns any amount:Max Price, scaled to 18 
 */

contract ICHIMaxOracle is OracleCommon {
    /** 
     @param oneTokenFactory_ oneToken factory to bind to
     @param description_ description has no bearing on logic
     @param indexToken_ token to use for price quotes
     */
    constructor(address oneTokenFactory_, string memory description_, address indexToken_)
        OracleCommon(oneTokenFactory_, description_, indexToken_) {}

    /**
     @notice update is called when a oneToken wants to persist observations
     @dev there is nothing to do in this case
     */
    function update(address /* token */) external override {}

    /**
     @notice returns equivalent amount of index tokens for an amount of baseTokens and volatility metric
     @dev amountTokens:amountUsd is always 1, adjusted for normalized scale, and volatility is always 1
     @param amountUsd US dollar equivalentm, precision 18
     @param volatility metric for future use-cases
     */
    function read(address /* token */, uint256  /*amountTokens*/ ) external pure override returns(uint256 amountUsd, uint256 volatility) {
        amountUsd = 1;
        volatility = 1;
    }

    /**
     @notice returns the tokens needed to reach a target usd value
     @dev token:usdToken is always the largest uint256 number and volatility is always 1
     @param token base token
     @param amountTokens tokens required, token native precision
     @param volatility metric for future use-cases
     */
    function amountRequired(address token, uint256 /*amountUsd*/) external view override returns(uint256 amountTokens, uint256 volatility) {
        amountTokens = normalizedToTokens(token, 2**256-1);
        volatility = 1;
    }
}