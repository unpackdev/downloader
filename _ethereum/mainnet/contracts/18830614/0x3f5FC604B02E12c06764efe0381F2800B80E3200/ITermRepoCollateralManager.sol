//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

import "./ITermRepoLocker.sol";

/// @notice ITermManager represents a contract that manages all
interface ITermRepoCollateralManager {
    function termRepoLocker() external view returns (ITermRepoLocker);

    function deMinimisMarginThreshold() external view returns (uint256);

    function netExposureCapOnLiquidation() external view returns (uint256);

    function initialCollateralRatios(
        address collateralToken
    ) external view returns (uint256);

    function liquidatedDamages(
        address collateralToken
    ) external view returns (uint256);

    /// @param borrower The address of the borrower
    /// @param collateralToken The collateral token address to query
    /// @return uint256 The amount of collateralToken locked on behalf of borrower
    function getCollateralBalance(
        address borrower,
        address collateralToken
    ) external view returns (uint256);

    /// @param borrower The address of the borrower
    /// @return The market value of borrower"s locked collateral denominated in USD
    function getCollateralMarketValue(
        address borrower
    ) external view returns (uint256);

    /// @param borrower The address of the borrower
    /// @param closureAmounts An array specifying the amounts of Term Repo exposure the liquidator proposes to cover in liquidation; an amount is required to be specified for each collateral token
    function batchDefault(
        address borrower,
        uint256[] calldata closureAmounts
    ) external;

    /// @param borrower The address of the borrower
    /// @param closureAmounts An array specifying the amounts of Term Repo exposure the liquidator proposes to cover in liquidation; an amount is required to be specified for each collateral token
    function batchLiquidation(
        address borrower,
        uint256[] calldata closureAmounts
    ) external;

    /// @param borrower The address of the borrower
    /// @return Boolean testing whether the given borrower is in shortfall or margin deficit
    function isBorrowerInShortfall(
        address borrower
    ) external view returns (bool);
}
