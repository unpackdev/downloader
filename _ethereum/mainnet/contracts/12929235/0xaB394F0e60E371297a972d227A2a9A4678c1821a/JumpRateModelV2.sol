// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.6.12;

import "./BaseJumpRateModelV2.sol";
import "./InterestRateModelInterface.sol";


/**
  * @title MOAR's JumpRateModel Contract V2 for V2 mTokens
  * @notice Supports only for V2 mTokens
  */
contract JumpRateModelV2 is BaseJumpRateModelV2  {

    constructor(uint baseRatePerYear, uint multiplierPerYear, uint jumpMultiplierPerYear, uint kink_, address owner_) 
    	BaseJumpRateModelV2(baseRatePerYear,multiplierPerYear,jumpMultiplierPerYear,kink_,owner_) public {}
}
