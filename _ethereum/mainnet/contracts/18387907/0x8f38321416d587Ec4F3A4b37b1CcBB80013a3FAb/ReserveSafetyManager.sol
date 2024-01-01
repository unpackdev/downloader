// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.10;

import "SafeERC20.sol";
import "ERC20.sol";

import "Governable.sol";
import "DataTypes.sol";
import "DecimalScale.sol";
import "FixedPoint.sol";
import "IGyroVault.sol";
import "IVault.sol";
import "Errors.sol";
import "ISafetyCheck.sol";

contract ReserveSafetyManager is Governable, ISafetyCheck {
    using FixedPoint for uint256;
    using DecimalScale for uint256;

    uint256 public maxAllowedVaultDeviation;
    uint256 public minTokenPrice;

    constructor(
        address _governor,
        uint256 _maxAllowedVaultDeviation,
        uint256 _minTokenPrice
    ) Governable(_governor) {
        maxAllowedVaultDeviation = _maxAllowedVaultDeviation;
        minTokenPrice = _minTokenPrice;
    }

    function setVaultMaxDeviation(uint256 _maxAllowedVaultDeviation) external governanceOnly {
        maxAllowedVaultDeviation = _maxAllowedVaultDeviation;
    }

    function setMinTokenPrice(uint256 _minTokenPrice) external governanceOnly {
        minTokenPrice = _minTokenPrice;
    }

    /// @notice For given token amounts and token prices, calculates the weight of each token with
    /// respect to the quote price as well as the total value of the basket in terms of the quote price
    /// @param amounts an array of token amounts
    /// @param prices an array of prices
    /// @return (weights, total) where the weights is an array and the total a uint
    function _calculateWeightsAndTotal(uint256[] memory amounts, uint256[] memory prices)
        internal
        pure
        returns (uint256[] memory, uint256)
    {
        uint256[] memory weights = new uint256[](prices.length);

        uint256 total = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            uint256 amountInUSD = amounts[i].mulDown(prices[i]);
            total += amountInUSD;
        }

        if (total == 0) {
            return (weights, total);
        }

        for (uint256 i = 0; i < amounts.length; i++) {
            weights[i] = amounts[i].mulDown(prices[i]).divDown(total);
        }

        return (weights, total);
    }

    /// @notice checks for all vaults whether if a particular vault contains a stablecoin that is off its peg,
    /// whether the proposed change to the vault would be reducing the weight of the vault with the failed asset (as desired).
    /// @param metaData an metadata struct containing all the vault information. Must be fully updated with the price
    /// safety and epsilon data.
    /// @return bool of whether all vaults exhibit this weight decreasing behavior
    function _vaultWeightWithOffPegFalls(DataTypes.Metadata memory metaData)
        internal
        pure
        returns (bool)
    {
        for (uint256 i; i < metaData.vaultMetadata.length; i++) {
            DataTypes.VaultMetadata memory vaultData = metaData.vaultMetadata[i];

            if (
                !vaultData.allStablecoinsOnPeg &&
                vaultData.resultingWeight >= vaultData.currentWeight
            ) {
                return false;
            }
        }

        return true;
    }

    /// @notice we allow minting only if depegged stablecoins are above peg
    /// we allow redeeming regardless of whether depegged stablecoins are above or under peg
    /// the price of the stablecoin is adjusted later when computing the reserve value
    /// and the amount that the user can mint/redeem
    function _canOperateWithDepeggedStablecoins(DataTypes.Metadata memory metaData)
        internal
        pure
        returns (bool)
    {
        if (!metaData.mint) return true;

        for (uint256 i; i < metaData.vaultMetadata.length; i++) {
            DataTypes.VaultMetadata memory vaultData = metaData.vaultMetadata[i];
            for (uint256 j; j < vaultData.pricedTokens.length; j++) {
                DataTypes.PricedToken memory pricedToken = vaultData.pricedTokens[j];
                if (pricedToken.isStable && pricedToken.price < pricedToken.priceRange.floor) {
                    return false;
                }
            }
        }
        return true;
    }

    function isRedeemFeasible(DataTypes.Order memory order) internal pure returns (bool) {
        for (uint256 i = 0; i < order.vaultsWithAmount.length; i++) {
            if (
                order.vaultsWithAmount[i].vaultInfo.reserveBalance <
                order.vaultsWithAmount[i].amount
            ) {
                return false;
            }
        }

        return true;
    }

    /// @notice this function takes an order struct and builds the metadata struct, for use in this contract.
    /// @param order an order struct received by the Reserve Safety Manager contract
    /// @return metaData object
    function _buildMetaData(DataTypes.Order memory order)
        internal
        pure
        returns (DataTypes.Metadata memory metaData)
    {
        DataTypes.VaultWithAmount[] memory vaultsWithAmount = order.vaultsWithAmount;

        metaData.mint = order.mint;
        metaData.vaultMetadata = new DataTypes.VaultMetadata[](order.vaultsWithAmount.length);

        uint256[] memory resultingAmounts = new uint256[](vaultsWithAmount.length);
        uint256[] memory prices = new uint256[](vaultsWithAmount.length);

        for (uint256 i = 0; i < vaultsWithAmount.length; i++) {
            if (order.mint) {
                resultingAmounts[i] =
                    vaultsWithAmount[i].vaultInfo.reserveBalance +
                    vaultsWithAmount[i].amount;
            } else {
                resultingAmounts[i] =
                    vaultsWithAmount[i].vaultInfo.reserveBalance -
                    vaultsWithAmount[i].amount;
            }
            resultingAmounts[i] = resultingAmounts[i].scaleFrom(
                vaultsWithAmount[i].vaultInfo.decimals
            );

            metaData.vaultMetadata[i].vault = vaultsWithAmount[i].vaultInfo.vault;
            metaData.vaultMetadata[i].targetWeight = vaultsWithAmount[i].vaultInfo.targetWeight;
            metaData.vaultMetadata[i].currentWeight = vaultsWithAmount[i].vaultInfo.currentWeight;
            metaData.vaultMetadata[i].price = vaultsWithAmount[i].vaultInfo.price;
            metaData.vaultMetadata[i].pricedTokens = vaultsWithAmount[i].vaultInfo.pricedTokens;
            prices[i] = vaultsWithAmount[i].vaultInfo.price;
        }

        (uint256[] memory resultingWeights, ) = _calculateWeightsAndTotal(resultingAmounts, prices);

        for (uint256 i = 0; i < order.vaultsWithAmount.length; i++) {
            metaData.vaultMetadata[i].resultingWeight = resultingWeights[i];
        }
    }

    /// @notice given input metadata, updates it with the information about whether the vault would remain within
    /// an acceptable band (+/- epsilon) around the ideal weight for the vault.
    /// @param metaData a metadata struct containing all the vault information.
    function _updateMetaDataWithEpsilonStatus(DataTypes.Metadata memory metaData) internal view {
        metaData.allVaultsWithinEpsilon = true;

        for (uint256 i = 0; i < metaData.vaultMetadata.length; i++) {
            DataTypes.VaultMetadata memory vaultData = metaData.vaultMetadata[i];
            uint256 scaledEpsilon = vaultData.targetWeight.mulUp(maxAllowedVaultDeviation);
            bool withinEpsilon = vaultData.targetWeight.absSub(vaultData.resultingWeight) <=
                scaledEpsilon;

            metaData.vaultMetadata[i].vaultWithinEpsilon = withinEpsilon;

            if (!withinEpsilon) {
                metaData.allVaultsWithinEpsilon = false;
            }
        }
    }

    /// @notice given input vaultMetadata, updates it with the information about whether the vault contains assets
    /// with safe prices. For a stablecoin, safe means the asset is sufficiently close to the peg. For a
    /// vault consisting of entirely non-stablecoin assets, this means that at least one of the prices is not 'dust',
    /// to avoid numerical error.
    /// @param vaultMetadata a VaultMetadata struct containing information for a particular vault.
    function _updateVaultWithPriceSafety(DataTypes.VaultMetadata memory vaultMetadata)
        internal
        view
    {
        vaultMetadata.allStablecoinsOnPeg = true;
        vaultMetadata.atLeastOnePriceLargeEnough = false;
        for (uint256 i = 0; i < vaultMetadata.pricedTokens.length; i++) {
            DataTypes.PricedToken memory pricedToken = vaultMetadata.pricedTokens[i];
            uint256 tokenPrice = pricedToken.price;
            bool isStable = vaultMetadata.pricedTokens[i].isStable;

            if (
                isStable &&
                (tokenPrice < pricedToken.priceRange.floor ||
                    tokenPrice > pricedToken.priceRange.ceiling)
            ) {
                vaultMetadata.allStablecoinsOnPeg = false;
            }
            if (tokenPrice >= minTokenPrice) {
                vaultMetadata.atLeastOnePriceLargeEnough = true;
            }
        }
    }

    /// @notice given input metadata, updates it with the information about whether all vaults contains assets with
    /// safe prices as determined by the _updateVaultWithPriceSafety function.
    /// @param metaData a metadata struct containing all the vault information.
    function _updateMetadataWithPriceSafety(DataTypes.Metadata memory metaData) internal view {
        metaData.allStablecoinsAllVaultsOnPeg = true;
        metaData.allVaultsUsingLargeEnoughPrices = true;
        for (uint256 i = 0; i < metaData.vaultMetadata.length; i++) {
            DataTypes.VaultMetadata memory vaultData = metaData.vaultMetadata[i];
            _updateVaultWithPriceSafety(vaultData);
            if (!vaultData.allStablecoinsOnPeg) {
                metaData.allStablecoinsAllVaultsOnPeg = false;
            }
            if (!vaultData.atLeastOnePriceLargeEnough) {
                metaData.allVaultsUsingLargeEnoughPrices = false;
            }
        }
    }

    /// @notice given input metadata,
    /// @param metaData a metadata struct containing all the vault information, updated with price safety and the
    /// status of the vault regarding whether it is within epsilon.
    /// @return bool equal to true if for any pool that is outside of epsilon, the weight after the mint/redeem will
    /// be closer to the ideal weight than the current weight is, i.e., the operation promotes rebalancing.
    function _safeToExecuteOutsideEpsilon(DataTypes.Metadata memory metaData)
        internal
        pure
        returns (bool)
    {
        //Check that amount above maxAllowedVaultDeviation is decreasing
        //Check that unhealthy pools have input weight below ideal weight
        //If both true, then mint
        //note: should always be able to mint at the ideal weights!

        for (uint256 i; i < metaData.vaultMetadata.length; i++) {
            DataTypes.VaultMetadata memory vaultMetadata = metaData.vaultMetadata[i];

            if (vaultMetadata.vaultWithinEpsilon) {
                continue;
            }

            uint256 distanceResultingToIdeal = vaultMetadata.resultingWeight.absSub(
                vaultMetadata.targetWeight
            );
            uint256 distanceCurrentToIdeal = vaultMetadata.currentWeight.absSub(
                vaultMetadata.targetWeight
            );

            if (distanceResultingToIdeal >= distanceCurrentToIdeal) {
                return false;
            }
        }

        return true;
    }

    function _isStablecoinSafe(DataTypes.Metadata memory metaData) internal pure returns (bool) {
        return
            metaData.allStablecoinsAllVaultsOnPeg ||
            _canOperateWithDepeggedStablecoins(metaData) ||
            _vaultWeightWithOffPegFalls(metaData);
    }

    /// @inheritdoc ISafetyCheck
    function isMintSafe(DataTypes.Order memory order) public view returns (string memory) {
        DataTypes.Metadata memory metaData = _buildMetaData(order);

        _updateMetadataWithPriceSafety(metaData);
        _updateMetaDataWithEpsilonStatus(metaData);

        if (!metaData.allVaultsUsingLargeEnoughPrices) {
            return Errors.TOKEN_PRICES_TOO_SMALL;
        }

        bool epsilonSafe = metaData.allVaultsWithinEpsilon ||
            _safeToExecuteOutsideEpsilon(metaData);

        if (_isStablecoinSafe(metaData) && epsilonSafe) {
            return "";
        }

        return Errors.NOT_SAFE_TO_MINT;
    }

    /// @inheritdoc ISafetyCheck
    function isRedeemSafe(DataTypes.Order memory order) public view returns (string memory) {
        if (!isRedeemFeasible(order)) {
            return Errors.TRYING_TO_REDEEM_MORE_THAN_VAULT_CONTAINS;
        }

        DataTypes.Metadata memory metaData = _buildMetaData(order);

        _updateMetadataWithPriceSafety(metaData);
        _updateMetaDataWithEpsilonStatus(metaData);

        if (!metaData.allVaultsUsingLargeEnoughPrices) {
            return Errors.TOKEN_PRICES_TOO_SMALL;
        }

        if (metaData.allVaultsWithinEpsilon || _safeToExecuteOutsideEpsilon(metaData)) {
            return "";
        }

        return Errors.NOT_SAFE_TO_REDEEM;
    }

    /// @inheritdoc ISafetyCheck
    function checkAndPersistMint(DataTypes.Order memory order) external view {
        string memory err = isMintSafe(order);
        require(bytes(err).length == 0, err);
    }

    /// @inheritdoc ISafetyCheck
    function checkAndPersistRedeem(DataTypes.Order memory order) external view {
        string memory err = isRedeemSafe(order);
        require(bytes(err).length == 0, err);
    }
}
