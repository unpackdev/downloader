// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "IVaultPriceOracle.sol";

import "FixedPoint.sol";

abstract contract BaseVaultPriceOracle is IVaultPriceOracle {
    using FixedPoint for uint256;

    /// @inheritdoc IVaultPriceOracle
    function getPriceUSD(IGyroVault vault, DataTypes.PricedToken[] memory underlyingPricedTokens)
        external
        view
        returns (uint256)
    {
        uint256 poolTokenPriceUSD = getPoolTokenPriceUSD(vault, underlyingPricedTokens);
        return poolTokenPriceUSD.mulDown(vault.exchangeRate());
    }

    /// @notice returns the price of the underlying pool token (e.g. BPT token)
    /// rather than the price of the vault token itself
    function getPoolTokenPriceUSD(
        IGyroVault vaultAddress,
        DataTypes.PricedToken[] memory underlyingPricedTokens
    ) public view virtual returns (uint256);
}
