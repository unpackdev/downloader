// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;


interface IBondingCalculator {
    function calcDebtRatio(uint pendingDebtDue_, uint managedTokenTotalSupply_) external pure returns (uint debtRatio_);
    function calcBondPremium(uint debtRatio_, uint bondScalingFactor) external pure returns (uint premium_);
    function calcPrincipleValuation(uint k_, uint amountDeposited_, uint totalSupplyOfTokenDeposited_) external pure returns (uint principleValuation_);
    function principleValuation(address principleTokenAddress_, uint amountDeposited_) external view returns (uint principleValuation_);
    function calculateBondInterest(address treasury_, address principleTokenAddress_, uint amountDeposited_, uint bondScalingFactor) external returns (uint interestDue_);
}