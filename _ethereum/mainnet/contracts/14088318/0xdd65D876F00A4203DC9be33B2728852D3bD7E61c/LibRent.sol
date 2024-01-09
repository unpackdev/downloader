// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IERC721.sol";

import "./LibERC721.sol";
import "./LibFee.sol";
import "./LibTransfer.sol";
import "./LibMarketplace.sol";

library LibRent {
    using SafeERC20 for IERC20;

    address constant ETHEREUM_PAYMENT_TOKEN = address(1);

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

    struct RentParams {
        uint256 _assetId;
        uint256 _period;
        address _paymentToken;
        uint256 _amount;
    }

    /// @dev Rents asset for a given period (in seconds)
    /// Rent is added to the queue of pending rents.
    /// Rent start will begin from the last rented timestamp.
    /// If no active rents are found, rents starts from the current timestamp.
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

        bool rentStartsNow = true;
        uint256 rentStart = block.timestamp;
        uint256 lastRentEnd = ms
        .rents[rentParams._assetId][asset.totalRents].end;

        if (lastRentEnd > rentStart) {
            rentStart = lastRentEnd;
            rentStartsNow = false;
        }

        uint256 rentEnd = rentStart + rentParams._period;
        require(
            block.timestamp + asset.maxFutureTime >= rentEnd,
            "rent more than current maxFutureTime"
        );

        uint256 rentPayment = rentParams._period * asset.pricePerSecond;
        require(rentParams._amount == rentPayment, "invalid _amount");
        if (asset.paymentToken == ETHEREUM_PAYMENT_TOKEN) {
            require(msg.value == rentPayment, "invalid msg.value");
        } else {
            require(msg.value == 0, "invalid token msg.value");
        }

        (uint256 rentFee, uint256 protocolFee) = LibFee.distributeFees(
            rentParams._assetId,
            asset.paymentToken,
            rentPayment
        );
        uint256 rentId = LibMarketplace.addRent(
            rentParams._assetId,
            msg.sender,
            rentStart,
            rentEnd
        );

        if (asset.paymentToken != ETHEREUM_PAYMENT_TOKEN) {
            LibTransfer.safeTransferFrom(
                asset.paymentToken,
                msg.sender,
                address(this),
                rentPayment
            );
        }

        emit Rent(
            rentParams._assetId,
            rentId,
            msg.sender,
            rentStart,
            rentEnd,
            asset.paymentToken,
            rentFee,
            protocolFee
        );

        return (rentId, rentStartsNow);
    }
}
