//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "./NameRegistry.sol";
import "./WhitelistRegistry.sol";
import "./ReservedRegistry.sol";
import "./DataTypes.sol";
import "./StringUtils.sol";

/**
 * @title Registry Calls
 * @author namespace.ninja
 * @notice Performs calls and updates registries for the minting process,
 * and returns the asking price for the minting and registration data.
 */
contract RegistryCalls {
    using StringUtils for string;

    /**
     *
     * @param registrationData Registration data
     * @param registries Registry addresses - [0]: nameRegistry, [1]: whitelistRegistry, [2]: reservedRegistry
     * @return askingPrice
     * @return paymentReceiver
     * @return registeredListing
     */
    function callRegistries(
        bytes memory registrationData,
        address[] calldata registries
    )
        external
        payable
        returns (
            uint256 askingPrice,
            address paymentReceiver,
            bytes memory registeredListing
        )
    {
        (bytes32 parentNode, string memory label) = abi.decode(
            registrationData,
            (bytes32, string)
        );

        DomainListingDetails memory listing = NameRegistry(registries[0])
            .getListing(parentNode);

        require(listing.listed, "Name is not listed");

        paymentReceiver = listing.addresses[0];

        // get whitelisting data
        uint8 whitelistType = WhitelistRegistry(registries[1]).whitelistTypes(
            parentNode
        );
        bool isWhitelisted = WhitelistRegistry(registries[1]).isWhitelisted(
            parentNode,
            msg.sender
        );

        // get reserved listing data
        (bool isReserved, uint256 reservedPrice) = ReservedRegistry(
            registries[2]
        ).getReservedDetails(parentNode, keccak256(bytes(label)));

        // remove from whitelist
        if (isWhitelisted) {
            WhitelistRegistry(registries[1]).claim(parentNode, msg.sender);
        }

        askingPrice = _getSubdomainPrice(
            listing.prices,
            listing.basePrice,
            label.strlen(),
            whitelistType,
            isWhitelisted
        );

        registeredListing = abi.encode(
            isWhitelisted,
            whitelistType,
            isReserved,
            listing.deadline,
            listing.basePrice,
            listing.prices,
            reservedPrice
        );
    }

    function _getSubdomainPrice(
        Pricing[] memory prices,
        uint256 basePrice,
        uint256 labelLength,
        uint256 whitelistingType,
        bool isWhitelisted
    ) internal pure returns (uint256) {
        // there is no price if it's a free whitelisting
        if (whitelistingType != 0 && isWhitelisted) {
            if (whitelistingType == WHITELIST_NO_FEES) {
                return 0;
            }
        }

        for (uint256 i = 0; i < prices.length; i++) {
            if (prices[i].letters == labelLength) {
                return prices[i].price;
            }
        }

        return basePrice;
    }
}
