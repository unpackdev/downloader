// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title SeenTypes
 *
 * @notice Enums and structs used by the Seen.Haus contract ecosystem.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract SeenTypes {

    enum Market {
        Primary,
        Secondary
    }

    enum MarketHandler {
        Unhandled,
        Auction,
        Sale
    }

    enum Clock {
        Live,
        Trigger
    }

    enum Audience {
        Open,
        Staker,
        VipStaker
    }

    enum Outcome {
        Pending,
        Closed,
        Canceled
    }

    enum State {
        Pending,
        Running,
        Ended
    }

    enum Ticketer {
        Default,
        Lots,
        Items
    }

    struct Token {
        address payable creator;
        uint16 royaltyPercentage;
        bool isPhysical;
        uint256 id;
        uint256 supply;
        string uri;
    }

    struct Consignment {
        Market market;
        MarketHandler marketHandler;
        address payable seller;
        address tokenAddress;
        uint256 tokenId;
        uint256 supply;
        uint256 id;
        bool multiToken;
        bool released;
        uint256 releasedSupply;
        uint16 customFeePercentageBasisPoints;
        uint256 pendingPayout;
    }

    struct Auction {
        address payable buyer;
        uint256 consignmentId;
        uint256 start;
        uint256 duration;
        uint256 reserve;
        uint256 bid;
        Clock clock;
        State state;
        Outcome outcome;
    }

    struct Sale {
        uint256 consignmentId;
        uint256 start;
        uint256 price;
        uint256 perTxCap;
        State state;
        Outcome outcome;
    }

    struct EscrowTicket {
        uint256 amount;
        uint256 consignmentId;
        uint256 id;
        string itemURI;
    }

}