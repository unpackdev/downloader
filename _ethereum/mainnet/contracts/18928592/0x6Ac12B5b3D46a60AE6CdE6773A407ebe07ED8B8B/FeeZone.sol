// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ZoneInterface.sol";
import "./ConsiderationStructs.sol";
import "./ERC165Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./StringsUpgradeable.sol";

error OnlySeaportAddress();
error InvalidOrderType();
error InvalidOrderPrice();
error FeesConsiderationsHigherThanOrderPrice();
error InvalidOrderTotals();
error InvalidTokenCurrency();
error InconsistentTokens();

/**
 * @title FeeZone
 * @dev A contract to validate listing orders with a tip fee in the considerations.
 */
contract FeeZone is
    ERC165Upgradeable,
    ZoneInterface,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;

    enum OrderType {
        Listing,
        Offer
    }

    address internal seaportAddress;
    address internal wethAddress;

    mapping(address => bool) internal supportedCurrencies;

    // Event declaration for SaleAttributed
    event SaleAttributed(uint256 indexed galleryId, bytes32 indexed orderHash);

    modifier onlySeaport() {
        if (_msgSender() != seaportAddress) {
            revert OnlySeaportAddress();
        }

        _;
    }

    function initialize() external initializer {
        __Context_init();
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /**
     * @dev Validates the order with the given `zoneParameters`. Called by
     *      Consideration whenever any extraData is provided by the caller.
     *
     * @param zoneParameters The parameters for the order.
     *
     * @return validOrderMagicValue The validOrder magic value.
     */
    function validateOrder(
        ZoneParameters calldata zoneParameters
    ) external override onlySeaport returns (bytes4 validOrderMagicValue) {
        // Extract the order type and order price from the zoneHash
        (OrderType orderType, uint256 orderPrice) = decodeZoneHash(
            zoneParameters.zoneHash
        );

        // Initialize a variable to track the total amount and total order price
        uint256 totalAmount = 0;
        uint256 totalOrderPrice = 0;

        (totalAmount, totalOrderPrice) = calculateOrderTotals(
            orderType,
            orderPrice,
            zoneParameters
        );

        // Validate that the total amount is equal to the total order price
        // and if the order price is greater than zero, total amount should also be greater than zero
        if (
            orderPrice != 0 &&
            (totalOrderPrice != totalAmount || totalAmount <= 0)
        ) {
            revert InvalidOrderTotals();
        }

        // Get the galleryId from the extraData in the zoneParameters
        uint256 galleryId = getGalleryIdFromExtraData(zoneParameters.extraData);

        // Emit the event with the orderHash and galleryId
        emit SaleAttributed(galleryId, zoneParameters.orderHash);

        // Return the magic value indicating a valid order
        return ZoneInterface.validateOrder.selector;
    }

    /**
     * @dev Decodes the order type, fee percentage, and order price from the zoneHash.
     *
     * @param zoneHash The encoded order type, fee percentage, and order price.
     *
     * @return orderType The decoded order type.
     * @return orderPrice The decoded order price.
     */

    function decodeZoneHash(
        bytes32 zoneHash
    ) internal pure returns (OrderType orderType, uint256 orderPrice) {
        uint8 orderTypeFromHash = uint8(zoneHash[0]);
        if (orderTypeFromHash > 1) {
            revert InvalidOrderType();
        }

        orderType = OrderType(orderTypeFromHash);

        // Extract bytes corresponding to the orderPrice
        bytes memory orderPriceBytes = slice(zoneHash, 1, 31); // Extract bytes 1 to 31
        orderPrice = abi.decode(
            abi.encodePacked(bytes1(0), orderPriceBytes),
            (uint256)
        );
    }

    /**
     * @dev Calculates the total amount and total order price from the zone parameters.
     *
     * @param orderType The type of order, i.e listing or offer.
     * @param orderPrice The price decoded from the zoneHash.
     * @param zoneParameters The parameters for the order.
     *
     * @return totalAmount The amount paid for the NFT calculated from zoneParameters.
     * @return totalOrderPrice the total price calculated from orderPrice and units fulfilled
     */
    function calculateOrderTotals(
        OrderType orderType,
        uint256 orderPrice,
        ZoneParameters calldata zoneParameters
    ) internal view returns (uint256 totalAmount, uint256 totalOrderPrice) {
        uint256 tokenAmount = 0;
        address currencyTokenAddress;

        if (orderType == OrderType.Listing) {
            currencyTokenAddress = zoneParameters.consideration[0].token;

            totalAmount = getTotalConsiderationAmount(
                zoneParameters.consideration,
                currencyTokenAddress
            );
            tokenAmount = getTokenAmountFromListing(zoneParameters.offer);
        } else if (orderType == OrderType.Offer) {
            currencyTokenAddress = zoneParameters.offer[0].token;

            totalAmount = getTotalOfferAmount(zoneParameters.offer);
            tokenAmount = getTokenAmountFromOffer(
                zoneParameters.consideration,
                orderPrice,
                currencyTokenAddress
            );
        }

        totalOrderPrice = orderPrice * tokenAmount;
        return (totalAmount, totalOrderPrice);
    }

    // Helper function to calculate total consideration amount
    function getTotalConsiderationAmount(
        ReceivedItem[] memory considerations,
        address currencyTokenAddress
    ) internal view returns (uint256 totalAmount) {
        for (uint256 i = 0; i < considerations.length; i++) {
            totalAmount += considerations[i].amount;

            if (considerations[i].token != currencyTokenAddress) {
                revert InconsistentTokens();
            }

            if (!supportedCurrencies[considerations[i].token]) {
                revert InvalidTokenCurrency();
            }
        }
    }

    // Helper function to get the NFT amount in listing
    function getTokenAmountFromListing(
        SpentItem[] memory offers
    ) internal pure returns (uint256 tokenAmount) {
        for (uint256 i = 0; i < offers.length; i++) {
            if (
                offers[i].itemType == ItemType(2) ||
                offers[i].itemType == ItemType(3)
            ) {
                tokenAmount = offers[i].amount;
                break;
            }
        }
    }

    // Helper function to calculate the offer amount (weth[ERC20])
    function getTotalOfferAmount(
        SpentItem[] memory offers
    ) internal view returns (uint256 totalAmount) {
        for (uint256 i = 0; i < offers.length; i++) {
            if (offers[i].itemType == ItemType(1)) {
                totalAmount += offers[i].amount;

                if (!supportedCurrencies[offers[i].token]) {
                    revert InvalidTokenCurrency();
                }
            }
        }
    }

    // Helper function to get the NFT amount in offer
    function getTokenAmountFromOffer(
        ReceivedItem[] memory considerations,
        uint256 orderPrice,
        address currencyTokenAddress
    ) internal view returns (uint256 tokenAmount) {
        uint256 feesConsiderationAmount = 0;

        for (uint256 i = 0; i < considerations.length; i++) {
            if (
                considerations[i].itemType == ItemType(2) ||
                considerations[i].itemType == ItemType(3)
            ) {
                tokenAmount = considerations[i].amount;
            } else {
                if (considerations[i].token != currencyTokenAddress) {
                    revert InconsistentTokens();
                }

                if (!supportedCurrencies[considerations[i].token]) {
                    revert InvalidTokenCurrency();
                }

                feesConsiderationAmount += considerations[i].amount;
            }
        }

        if (feesConsiderationAmount > orderPrice * tokenAmount) {
            revert FeesConsiderationsHigherThanOrderPrice();
        }
    }

    // Helper function to decode galleryId from extraData
    function getGalleryIdFromExtraData(
        bytes calldata extraData
    ) internal pure returns (uint256 galleryId) {
        // Check if extraData is provided and has sufficient length for a galleryId
        if (extraData.length >= 32) {
            // Decode the galleryId from the extraData
            galleryId = abi.decode(extraData[:32], (uint256));
        }
    }

    // Helper function to slice bytes from a bytes32 variable
    function slice(
        bytes32 data,
        uint256 start,
        uint256 length
    ) internal pure returns (bytes memory) {
        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = data[start + i];
        }
        return result;
    }

    /**
     * @dev Returns the metadata for this zone.
     */
    function getSeaportMetadata()
        external
        pure
        override
        returns (
            string memory name,
            Schema[] memory schemas // map to Seaport Improvement Proposal IDs
        )
    {
        schemas = new Schema[](1);
        schemas[0].id = 3003; // Example ID, update as necessary
        schemas[0].metadata = new bytes(0);

        return ("FeeZone", schemas);
    }

    /**
     * @dev Checks if the contract supports a given interface.
     *
     * @param interfaceId The ID of the interface to check.
     *
     * @return bool True if the contract supports the interface, false otherwise.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC165Upgradeable, ZoneInterface) returns (bool) {
        return
            interfaceId == type(ZoneInterface).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Sets the address of the Seaport contract.
     *
     * @param seaportContractAddress The address of the Seaport contract.
     */
    function setSeaportAddress(
        address seaportContractAddress
    ) external onlyOwner {
        seaportAddress = seaportContractAddress;
    }

    /**
     * @dev Adds or removes the support for any currency token.
     *
     * @param currencyAddress The token address of the currency.
     * @param status The status of the token whether it is supported or not.
     */
    function updateCurrencySupport(
        address currencyAddress,
        bool status
    ) external onlyOwner {
        // update the currency support for this contract
        supportedCurrencies[currencyAddress] = status;
    }
}
