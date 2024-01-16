// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IERC721.sol";

import "./LibERC721.sol";
import "./LibFee.sol";
import "./LibReferral.sol";
import "./LibTransfer.sol";
import "./LibMarketplace.sol";

library LibRent {
    using SafeERC20 for IERC20;

    event Rent(
        uint256 indexed _assetId,
        uint256 _rentId,
        address indexed _renter,
        uint256 _start,
        uint256 _end,
        address indexed _paymentToken,
        uint256 _rent,
        uint256 _protocolFee
    );
    event AccrueReferralFee(
        uint256 indexed _assetId,
        uint256 _rentId,
        address indexed _referrer,
        address indexed _paymentToken,
        uint256 _fee
    );

    struct RentParams {
        uint256 _assetId;
        uint256 _period;
        uint256 _maxRentStart;
        address _paymentToken;
        uint256 _amount;
        address _referrer;
    }

    struct DistributionParams {
        uint256 assetId;
        uint256 rentId;
        address metaverseRegistry;
        address paymentToken;
        uint256 rentPayment;
        address rentReferrer;
    }

    struct RentDistribution {
        // The cost, which the renter has to send/approve
        uint256 renterCost;
        // The reward accrued to the lister
        uint256 listerReward;
        // The total protocol fee
        uint256 protocolFee;
    }

    /// @dev Rents asset for a given period (in seconds)
    /// Rent is added to the queue of pending rents.
    /// Rent start will begin from the last rented timestamp.
    /// If no active rents are found, rents starts from the current timestamp.
    /// Protocol fee may be split into multiple referrals.
    /// Priority is the following:
    /// 1. Metaverse registry referrer: If the given asset metaverse registry has a metaverse
    /// referrer, it accrues a percent of the protocol fees to that referrer.
    /// 2.1. List referrer: Takes percentage of the leftovers based on `mainPercentage`.
    /// `mainPercentage` has a maximum percentage of 50 due to rent referrer.
    /// The lister itself might take percentage of the list referral based on `secondaryPercentage`,
    /// adding an additional amount to the rent reward.
    /// 2.2. Rent referrer: Takes percentage of the leftovers based on `mainPercentage`.
    /// `mainPercentage` has a maximum percentage of 50 due to list referrer.
    /// The renter itself might take percentage of the rent referral based on `secondaryPercentage`,
    /// which will serve as discount to the initial rent amount.
    /// 3. Protocol: Everything left is for the protocol.
    /// See {IReferralFacet-setMetaverseRegistryReferrers}, {IReferralFacet-setReferrers}.
    function rent(RentParams memory rentParams)
        internal
        returns (uint256, bool)
    {
        LibMarketplace.MarketplaceStorage storage ms = LibMarketplace
            .marketplaceStorage();

        require(LibERC721.exists(rentParams._assetId), "_assetId not found");
        LibMarketplace.Asset memory asset = ms.assets[rentParams._assetId];
        require(
            asset.status == LibMarketplace.AssetStatus.Listed,
            "_assetId not listed"
        );
        require(
            rentParams._period >= asset.minPeriod,
            "_period less than minPeriod"
        );
        require(
            rentParams._period <= asset.maxPeriod,
            "_period more than maxPeriod"
        );
        require(
            rentParams._paymentToken == asset.paymentToken,
            "invalid _paymentToken"
        );
        if (rentParams._referrer != address(0)) {
            LibReferral.ReferrerPercentage memory rp = LibReferral
                .referralStorage()
                .referrerPercentages[rentParams._referrer];
            require(rp.mainPercentage > 0, "_referrer not whitelisted");
        }

        bool rentStartsNow = true;
        uint256 rentStart = block.timestamp;
        uint256 lastRentEnd = ms
        .rents[rentParams._assetId][asset.totalRents].end;

        if (lastRentEnd > rentStart) {
            rentStart = lastRentEnd;
            rentStartsNow = false;
        }
        require(
            rentStart <= rentParams._maxRentStart,
            "rent start exceeds maxRentStart"
        );

        uint256 rentEnd = rentStart + rentParams._period;
        require(
            block.timestamp + asset.maxFutureTime >= rentEnd,
            "rent more than current maxFutureTime"
        );

        uint256 rentPayment = rentParams._period * asset.pricePerSecond;

        uint256 rentId = LibMarketplace.addRent(
            rentParams._assetId,
            msg.sender,
            rentStart,
            rentEnd
        );
        RentDistribution memory rds = distributeFees(
            DistributionParams({
                assetId: rentParams._assetId,
                rentId: rentId,
                metaverseRegistry: asset.metaverseRegistry,
                paymentToken: asset.paymentToken,
                rentPayment: rentPayment,
                rentReferrer: rentParams._referrer
            })
        );

        require(rentParams._amount == rds.renterCost, "invalid _amount");
        if (asset.paymentToken == LibTransfer.ETHEREUM_PAYMENT_TOKEN) {
            require(msg.value == rds.renterCost, "invalid msg.value");
        } else {
            require(msg.value == 0, "invalid token msg.value");
        }

        if (asset.paymentToken != LibTransfer.ETHEREUM_PAYMENT_TOKEN) {
            LibTransfer.safeTransferFrom(
                asset.paymentToken,
                msg.sender,
                address(this),
                rds.renterCost
            );
        }

        emit Rent(
            rentParams._assetId,
            rentId,
            msg.sender,
            rentStart,
            rentEnd,
            asset.paymentToken,
            rds.listerReward,
            rds.protocolFee
        );

        return (rentId, rentStartsNow);
    }

    function distributeFees(DistributionParams memory params)
        internal
        returns (RentDistribution memory rds)
    {
        LibFee.FeeStorage storage fs = LibFee.feeStorage();
        LibReferral.ReferralStorage storage rs = LibReferral.referralStorage();

        rds.protocolFee =
            (params.rentPayment * fs.feePercentages[params.paymentToken]) /
            LibFee.FEE_PRECISION;
        rds.listerReward = params.rentPayment - rds.protocolFee;
        rds.renterCost = params.rentPayment;

        {
            LibReferral.MetaverseRegistryReferrer memory mrr = rs
                .metaverseRegistryReferrers[params.metaverseRegistry];

            if (mrr.percentage > 0) {
                uint256 metaverseReferralAmount = (rds.protocolFee *
                    mrr.percentage) / LibFee.FEE_PRECISION;
                rs.referrerFees[mrr.referrer][
                    params.paymentToken
                ] += metaverseReferralAmount;
                rds.protocolFee -= metaverseReferralAmount;

                emit AccrueReferralFee(
                    params.assetId,
                    params.rentId,
                    mrr.referrer,
                    params.paymentToken,
                    metaverseReferralAmount
                );
            }
        }

        uint256 referralFeesLeft = rds.protocolFee;

        if (referralFeesLeft > 0) {
            {
                address listReferrer = rs.listReferrer[params.assetId];
                if (listReferrer != address(0)) {
                    LibReferral.ReferrerPercentage memory rp = rs
                        .referrerPercentages[listReferrer];

                    if (rp.mainPercentage > 0) {
                        uint256 totalReferralFee = (referralFeesLeft *
                            rp.mainPercentage) / LibFee.FEE_PRECISION;
                        rds.protocolFee -= totalReferralFee;

                        uint256 listerFee = (totalReferralFee *
                            rp.secondaryPercentage) / LibFee.FEE_PRECISION;
                        rds.listerReward += listerFee;

                        uint256 referrerFee = totalReferralFee - listerFee;

                        rs.referrerFees[listReferrer][
                            params.paymentToken
                        ] += referrerFee;
                        emit AccrueReferralFee(
                            params.assetId,
                            params.rentId,
                            listReferrer,
                            params.paymentToken,
                            referrerFee
                        );
                    }
                }
            }

            {
                if (params.rentReferrer != address(0)) {
                    LibReferral.ReferrerPercentage memory rp = rs
                        .referrerPercentages[params.rentReferrer];

                    uint256 totalReferralFee = (referralFeesLeft *
                        rp.mainPercentage) / LibFee.FEE_PRECISION;
                    rds.protocolFee -= totalReferralFee;

                    uint256 renterDiscount = (totalReferralFee *
                        rp.secondaryPercentage) / LibFee.FEE_PRECISION;
                    rds.renterCost -= renterDiscount;

                    uint256 referrerFee = totalReferralFee - renterDiscount;
                    rs.referrerFees[params.rentReferrer][
                        params.paymentToken
                    ] += referrerFee;

                    emit AccrueReferralFee(
                        params.assetId,
                        params.rentId,
                        params.rentReferrer,
                        params.paymentToken,
                        referrerFee
                    );
                }
            }
        }

        fs.assetRentFees[params.assetId][params.paymentToken] += rds
            .listerReward;
        fs.protocolFees[params.paymentToken] += rds.protocolFee;

        return rds;
    }
}
