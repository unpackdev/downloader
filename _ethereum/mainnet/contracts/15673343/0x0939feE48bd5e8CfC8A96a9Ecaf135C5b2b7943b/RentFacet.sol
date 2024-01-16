// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC721Consumable.sol";
import "./IRentFacet.sol";
import "./LibERC721.sol";
import "./LibTransfer.sol";
import "./LibOwnership.sol";
import "./LibFee.sol";
import "./LibRent.sol";

contract RentFacet is IRentFacet {
    /// @notice Rents an asset for a given period.
    /// Charges user for the rent upfront. Rent starts from the last rented timestamp
    /// or from the current timestamp of the transaction.
    /// Protocol fee may be split into multiple referrals.
    /// Discount from the initial rent amount may be found depending on the metaverse
    /// registry and rent referrers.
    /// See {IReferralFacet-setMetaverseRegistryReferrers}, {IReferralFacet-setReferrers}.
    /// @dev Call {IRentFacet-calculateRentFee} to get the correct amount and payment token
    /// required for the given period and referrer.
    /// @param _assetId The target asset
    /// @param _period The target rental period (in seconds)
    /// @param _maxRentStart The maximum rent start allowed for the given rent
    /// @param _paymentToken The current payment token for the asset
    /// @param _amount The target amount to be paid for the rent
    /// @param _referrer The target referrer
    /// @return rentId_ The id of the rent for the target asset
    /// @return rentStartsNow_ Whether the rents begins in the current block
    function rent(
        uint256 _assetId,
        uint256 _period,
        uint256 _maxRentStart,
        address _paymentToken,
        uint256 _amount,
        address _referrer
    ) external payable returns (uint256 rentId_, bool rentStartsNow_) {
        (rentId_, rentStartsNow_) = LibRent.rent(
            LibRent.RentParams({
                _assetId: _assetId,
                _period: _period,
                _maxRentStart: _maxRentStart,
                _paymentToken: _paymentToken,
                _amount: _amount,
                _referrer: _referrer
            })
        );
    }

    /// @notice Gets all data for a specific rent of an asset
    /// @param _assetId The taget asset
    /// @param _rentId The target rent
    function rentAt(uint256 _assetId, uint256 _rentId)
        external
        view
        returns (LibMarketplace.Rent memory)
    {
        return LibMarketplace.rentAt(_assetId, _rentId);
    }

    /// @notice Returns an asset rent fee based on period and referrer
    /// Calculates the rent fee based on asset, period and referrer.
    /// A rent fee discount might appear depending on referral
    /// percentages.
    /// @dev Reverts if the _referrer is not whitelisted.
    /// Portions of the protocol fee might be given as discount depending
    /// referrals. Priority is the following:
    /// 1. Metaverse registry referrer: If the given asset metaverse registry has a metaverse
    /// referrer, it accrues a percent of the protocol fees to that referrer.
    /// 2. Rent referrer: Takes percentage from (protocol fees - metaverse registry fee) based on `mainPercentage`.
    /// `mainPercentage` has a maximum percentage of 50 due to list referrer.
    /// The renter itself might take percentage of the rent referral based on `secondaryPerceange`,
    /// which will serve as discount to the initial rent amount.
    /// @param _assetId The target asset
    /// @param _period The target rental period (in seconds)
    /// @param _referrer The address of the referrer
    /// @return paymentToken_ The target payment token
    /// @return amount_ The amount that has to be paid
    function calculateRentFee(
        uint256 _assetId,
        uint256 _period,
        address _referrer
    ) external view returns (address paymentToken_, uint256 amount_) {
        require(LibERC721.exists(_assetId), "_assetId not found");

        LibMarketplace.Asset memory asset = LibMarketplace.assetAt(_assetId);
        uint256 amount = _period * asset.pricePerSecond;

        if (_referrer == address(0)) {
            return (asset.paymentToken, amount);
        }

        LibReferral.ReferrerPercentage memory rp = LibReferral
            .referralStorage()
            .referrerPercentages[_referrer];
        require(rp.mainPercentage > 0, "_referrer not whitelisted");

        uint256 protocolFee = (amount *
            LibFee.feeStorage().feePercentages[asset.paymentToken]) /
            LibFee.FEE_PRECISION;

        LibReferral.MetaverseRegistryReferrer memory mrr = LibReferral
            .referralStorage()
            .metaverseRegistryReferrers[asset.metaverseRegistry];
        uint256 metaverseReferralAmount = (protocolFee * mrr.percentage) /
            LibFee.FEE_PRECISION;

        uint256 feesLeft = protocolFee - metaverseReferralAmount;

        uint256 rentReferrerFee = (feesLeft * rp.mainPercentage) /
            LibFee.FEE_PRECISION;
        uint256 renterDiscount = (rentReferrerFee * rp.secondaryPercentage) /
            LibFee.FEE_PRECISION;
        return (asset.paymentToken, amount - renterDiscount);
    }
}
