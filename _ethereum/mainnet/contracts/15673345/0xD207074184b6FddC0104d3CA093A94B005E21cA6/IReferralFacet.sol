// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./LibReferral.sol";

interface IReferralFacet {
    /// @notice Emitted once a given referrer fee has been claimed
    event ClaimReferrerFee(
        address indexed _claimer,
        address indexed _token,
        uint256 _amount
    );

    /// @notice Emitted once the referrals admin has been changed
    event SetReferralAdmin(address indexed _admin);

    /// @notice Emitted once a referrer has been updated
    event SetReferrer(
        address indexed _referrer,
        uint24 _mainPercentage,
        uint24 _secondaryPercentage
    );
    /// @notice Emitted once a metaverse registry referrer has been updated
    event SetMetaverseRegistryReferrer(
        address indexed _metaverseRegistry,
        address indexed _referrer,
        uint24 _percentage
    );

    /// @notice Sets a referral admin
    /// Manages the addition/removal of referrers.
    /// @param _admin The address of the to-be-set admin
    function setReferralAdmin(address _admin) external;

    /// @notice Sets an array of metaverse registry referrers
    /// Adds a referrer to each metaverse registry.
    /// Accrues part of the protocol fees upon each asset rent, which is from the
    /// given metaverse registry.
    /// @dev Metaverse registries, referrers & percentages are followed by array index.
    /// Maximum `percentage` is 100_000 (100%).
    /// Setting the percentage to 0 will no longer accrue fees upon rents from metaverse
    /// registries.
    /// @param _metaverseRegistries The target metaverse registries
    /// @param _referrers The to-be-set referrers for the metaverse registries
    /// @param _percentages The to-be-set referrer percentages for the metaverse registries
    function setMetaverseRegistryReferrers(
        address[] memory _metaverseRegistries,
        address[] memory _referrers,
        uint24[] memory _percentages
    ) external;

    /// @notice Sets an array of referrers
    /// Used as referrers upon listings and rents.
    /// Referrers accrue part of the protocol fees upon each asset rent.
    /// Refererrs may give portion of their part of the protocol fees
    /// to listers/renters, which will serve as:
    /// lister - additional reward upon each rent
    /// renter - rent discount
    /// Referrers can be blacklisted:
    /// * past listings will no longer accrue part of the protocol fees.
    /// * future listings/rents will no longer be allowed.
    /// @dev Referrers and percentages are followed by array index.
    /// Maximum `mainPercentage` is 50_000 (50%), as list and rent referrers
    /// have equal split of the protocol fees.
    /// 'secondaryPercentage` takes a percetange of the calculated `mainPercentage` fraction.
    /// Changing the percentages for a referrer will affect past listings and future listings/rents.
    /// Setting `mainPercentage` to 0 (0%) blacklists the referrer, which does not allow future
    /// listings and rents. All past listings with blacklisted referrer will no longer accrue
    /// neither fees to the referrer, nor additional rewards to the lister.
    /// @param _referrers The to-be-set referrers
    /// @param _mainPercentages The to-be-set main percentages for referrers
    /// @param _secondaryPercentages The to-be-set secondary percentages for referrers
    function setReferrers(
        address[] memory _referrers,
        uint24[] memory _mainPercentages,
        uint24[] memory _secondaryPercentages
    ) external;

    /// @notice Claims unclaimed referrer fees for a given payment token
    /// @dev Does not emit event if amount is 0.
    /// @param _paymentToken The target payment token
    /// @return paymentToken_ The target payment token
    /// @return amount_ The claimed amount
    function claimReferrerFee(address _paymentToken)
        external
        returns (address paymentToken_, uint256 amount_);

    /// @notice Claims unclaimed referrer fees
    /// @dev Does not emit event if amount is 0.
    /// @param _paymentTokens The array of payment tokens
    function claimMultipleReferrerFees(address[] memory _paymentTokens)
        external;

    /// @notice Returns the referral admin
    function referralAdmin() external view returns (address);

    /// @notice Returns the accrued referrer amount for a given payment token
    /// @param _referrer The address of the referrer
    /// @param _token The target payment token
    /// @return amount_ The accrued referrer amount
    function referrerFee(address _referrer, address _token)
        external
        view
        returns (uint256 amount_);

    /// @notice Returns the referrer and percentage for a metaverse registry.
    /// @param _metaverseRegistry The target metaverse registry
    function metaverseRegistryReferrer(address _metaverseRegistry)
        external
        view
        returns (LibReferral.MetaverseRegistryReferrer memory);

    /// @notice Returns the referrer main & secondary percentages
    /// @param _referrer The target referrer
    function referrerPercentage(address _referrer)
        external
        view
        returns (LibReferral.ReferrerPercentage memory);
}
