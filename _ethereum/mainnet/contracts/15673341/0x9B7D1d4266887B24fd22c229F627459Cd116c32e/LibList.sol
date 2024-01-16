// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./LibERC721.sol";
import "./LibFee.sol";
import "./LibReferral.sol";
import "./LibTransfer.sol";
import "./LibMarketplace.sol";

library LibList {
    event List(
        uint256 _assetId,
        uint256 _metaverseId,
        address indexed _metaverseRegistry,
        uint256 indexed _metaverseAssetId,
        uint256 _minPeriod,
        uint256 _maxPeriod,
        uint256 _maxFutureTime,
        address indexed _paymentToken,
        uint256 _pricePerSecond
    );

    /// @notice Provides asset of the given metaverse registry for rental.
    /// Transfers and locks the provided metaverse asset to the contract.
    /// and mints an asset, representing the locked asset.
    /// Listing with a referrer might lead to additional rewards upon rents.
    /// Additional reward may vary depending on the referrer's requested portion for listers.
    /// If the referrer is blacklisted after the listing,
    /// listers will not receive additional rewards.
    /// See {IReferralFacet-setMetaverseRegistryReferrers}, {IReferralFacet-setReferrers}.
    /// @param _metaverseId The id of the metaverse
    /// @param _metaverseRegistry The registry of the metaverse
    /// @param _metaverseAssetId The id from the metaverse registry
    /// @param _minPeriod The minimum number of time (in seconds) the asset can be rented
    /// @param _maxPeriod The maximum number of time (in seconds) the asset can be rented
    /// @param _maxFutureTime The timestamp delta after which the protocol will not allow
    /// the asset to be rented at an any given moment.
    /// @param _paymentToken The token which will be accepted as a form of payment.
    /// Provide 0x0000000000000000000000000000000000000001 for ETH.
    /// @param _pricePerSecond The price for rental per second
    /// @param _referrer The target referrer
    /// @return The newly created asset id.
    function list(
        uint256 _metaverseId,
        address _metaverseRegistry,
        uint256 _metaverseAssetId,
        uint256 _minPeriod,
        uint256 _maxPeriod,
        uint256 _maxFutureTime,
        address _paymentToken,
        uint256 _pricePerSecond,
        address _referrer
    ) internal returns (uint256) {
        require(
            _metaverseRegistry != address(0),
            "_metaverseRegistry must not be 0x0"
        );
        require(
            LibMarketplace.supportsRegistry(_metaverseId, _metaverseRegistry),
            "_registry not supported"
        );
        require(_minPeriod != 0, "_minPeriod must not be 0");
        require(_maxPeriod != 0, "_maxPeriod must not be 0");
        require(_minPeriod <= _maxPeriod, "_minPeriod more than _maxPeriod");
        require(
            _maxPeriod <= _maxFutureTime,
            "_maxPeriod more than _maxFutureTime"
        );
        require(
            LibFee.supportsTokenPayment(_paymentToken),
            "payment type not supported"
        );
        if (_referrer != address(0)) {
            LibReferral.ReferrerPercentage memory rp = LibReferral
                .referralStorage()
                .referrerPercentages[_referrer];
            require(rp.mainPercentage > 0, "_referrer not whitelisted");
        }

        uint256 asset = LibERC721.safeMint(msg.sender);
        {
            LibMarketplace.MarketplaceStorage storage ms = LibMarketplace
                .marketplaceStorage();
            ms.assets[asset] = LibMarketplace.Asset({
                metaverseId: _metaverseId,
                metaverseRegistry: _metaverseRegistry,
                metaverseAssetId: _metaverseAssetId,
                paymentToken: _paymentToken,
                minPeriod: _minPeriod,
                maxPeriod: _maxPeriod,
                maxFutureTime: _maxFutureTime,
                pricePerSecond: _pricePerSecond,
                status: LibMarketplace.AssetStatus.Listed,
                totalRents: 0
            });
            LibReferral.referralStorage().listReferrer[asset] = _referrer;

            LibTransfer.erc721SafeTransferFrom(
                _metaverseRegistry,
                msg.sender,
                address(this),
                _metaverseAssetId
            );
        }
        emit List(
            asset,
            _metaverseId,
            _metaverseRegistry,
            _metaverseAssetId,
            _minPeriod,
            _maxPeriod,
            _maxFutureTime,
            _paymentToken,
            _pricePerSecond
        );
        return asset;
    }
}
