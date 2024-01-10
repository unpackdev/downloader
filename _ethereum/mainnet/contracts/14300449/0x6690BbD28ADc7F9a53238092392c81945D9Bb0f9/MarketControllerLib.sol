// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SeenTypes.sol";

/**
 * @title MarketControllerLib
 *
 * @dev Provides access to the the MarketController Storage and Intializer slots for MarketController facets
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
library MarketControllerLib {

    bytes32 constant MARKET_CONTROLLER_STORAGE_POSITION = keccak256("seen.haus.market.controller.storage");
    bytes32 constant MARKET_CONTROLLER_INITIALIZERS_POSITION = keccak256("seen.haus.market.controller.initializers");

    struct MarketControllerStorage {

        // the address of the Seen.Haus NFT contract
        address nft;

        // the address of the xSEEN ERC-20 Seen.Haus staking contract
        address payable staking;

        // the address of the Seen.Haus multi-sig wallet
        address payable multisig;

        // address of the Seen.Haus lots-based escrow ticketing contract
        address lotsTicketer;

        // address of the Seen.Haus items-based escrow ticketing contract
        address itemsTicketer;

        // the default escrow ticketer type to use for physical consignments unless overridden with setConsignmentTicketer
        SeenTypes.Ticketer defaultTicketerType;

        // the minimum amount of xSEEN ERC-20 a caller must hold to participate in VIP events
        uint256 vipStakerAmount;

        // the percentage that will be taken as a fee from the net of a Seen.Haus sale or auction
        uint16 primaryFeePercentage;         // 1.75% = 175, 100% = 10000

        // the percentage that will be taken as a fee from the net of a Seen.Haus sale or auction (after royalties)
        uint16 secondaryFeePercentage;         // 1.75% = 175, 100% = 10000

        // the maximum percentage of a Seen.Haus sale or auction that will be paid as a royalty
        uint16 maxRoyaltyPercentage;  // 1.75% = 175, 100% = 10000

        // the minimum percentage a Seen.Haus auction bid must be above the previous bid to prevail
        uint16 outBidPercentage;      // 1.75% = 175, 100% = 10000

        // next consignment id
        uint256 nextConsignment;

        // whether or not external NFTs can be sold via secondary market
        bool allowExternalTokensOnSecondary;

        // consignment id => consignment
        mapping(uint256 => SeenTypes.Consignment) consignments;

        // consignmentId to consignor address
        mapping(uint256 => address) consignors;

        // consignment id => ticketer type
        mapping(uint256 => SeenTypes.Ticketer) consignmentTicketers;

        // escrow agent address => feeBasisPoints
        mapping(address => uint16) escrowAgentToFeeBasisPoints;

    }

    struct MarketControllerInitializers {

        // MarketConfigFacet initialization state
        bool configFacet;

        // MarketConfigFacet initialization state
        bool configAdditionalFacet;

        // MarketClerkFacet initialization state
        bool clerkFacet;

    }

    function marketControllerStorage() internal pure returns (MarketControllerStorage storage mcs) {
        bytes32 position = MARKET_CONTROLLER_STORAGE_POSITION;
        assembly {
            mcs.slot := position
        }
    }

    function marketControllerInitializers() internal pure returns (MarketControllerInitializers storage mci) {
        bytes32 position = MARKET_CONTROLLER_INITIALIZERS_POSITION;
        assembly {
            mci.slot := position
        }
    }

}