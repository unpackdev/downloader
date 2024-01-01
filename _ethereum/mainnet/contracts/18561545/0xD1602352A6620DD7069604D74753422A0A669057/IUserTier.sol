// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./LibGovTierStorage.sol";
import "./LibMarketStorage.sol";

interface IUserTier {
    function getTierDatabyGovBalance(
        address userWalletAddress
    ) external view returns (LibGovTierStorage.TierData memory _tierData);

    function getMaxLoanAmount(
        uint256 _collateralTokeninStable,
        uint256 _tierLevelLTVPercentage
    ) external pure returns (uint256);

    function getMaxLoanAmountToValue(
        uint256 _collateralTokeninStable,
        address _borrower,
        LibMarketStorage.TierType tierType
    ) external view returns (uint256);

    function isCreateLoanTokenUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 collateralInBorrowed,
        address[] memory stakedCollateralTokens,
        LibMarketStorage.TierType tierType
    ) external view returns (uint256);

    function isCreateLoanNftUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 collateralInBorrowed,
        address[] memory stakedCollateralTokens,
        LibMarketStorage.TierType tierType
    ) external view returns (uint256);
}
