// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.6.12;

import "./InterestRateModelInterface.sol";

abstract contract AbstractInterestRateModel is InterestRateModelInterface {

    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;
}