// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

// solhint-disable-next-line max-line-length
import "./AppreciatingFiatCollateral.sol";
import "./MorphoTokenisedDeposit.sol";
import "./OracleLib.sol";
// solhint-disable-next-line max-line-length
import "./AggregatorV3Interface.sol";
import "./IERC20Metadata.sol";
import "./Fixed.sol";

/**
 * @title MorphoFiatCollateral
 * @notice Collateral plugin for a Morpho pool with fiat collateral, like USDC or USDT
 * Expected: {tok} != {ref}, {ref} is pegged to {target} unless defaulting, {target} == {UoA}
 */
contract MorphoFiatCollateral is AppreciatingFiatCollateral {
    using OracleLib for AggregatorV3Interface;

    uint256 private immutable oneShare;
    int8 private immutable refDecimals;

    /// @param config Configuration of this collateral
    /// config.erc20 must be a MorphoTokenisedDeposit
    /// @param revenueHiding {1} A value like 1e-6 that represents the maximum refPerTok to hide
    constructor(CollateralConfig memory config, uint192 revenueHiding)
        AppreciatingFiatCollateral(config, revenueHiding)
    {
        require(address(config.erc20) != address(0), "missing erc20");
        MorphoTokenisedDeposit vault = MorphoTokenisedDeposit(address(config.erc20));
        oneShare = 10**vault.decimals();
        refDecimals = int8(uint8(IERC20Metadata(vault.asset()).decimals()));
    }

    /// @return {ref/tok} Actual quantity of whole reference units per whole collateral tokens
    function _underlyingRefPerTok() internal view override returns (uint192) {
        return
            shiftl_toFix(
                MorphoTokenisedDeposit(address(erc20)).convertToAssets(oneShare),
                -refDecimals
            );
    }
}
