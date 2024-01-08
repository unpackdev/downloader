// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IOracle.sol";

interface IDaoEventsV2 {
    struct Ticket {
        uint256 eventId;
        uint256 seatNo;
        string boughtLocation;
        string eventLocation;
    }

    event SoldTicketDetails1(Ticket);

    struct Event {
        bool oneTimeBuy;
        bool token; // false means free
        bool onsite; // true means event is onsite
        address owner;
        uint256 time;
        uint256 totalQuantity;
        uint256 totalQntySold;
        string name;
        string topic;
        string location;
        string city;
        string ipfsHash;
        bool[] ticketLimited;
        uint256[] tktQnty;
        uint256[] prices;
        uint256[] tktQntySold;
        string[] categories;
    }

    struct SoldTicketStruct {
        bool token;
        uint256 eventId;
        uint256 seatNo;
        address buyer;
        uint256 usdtPrice;
        uint256 phnxPrice;
        uint256 boughtTime;
        uint256 totalTktsSold;
        uint256 categoryTktsSold;
        string category;
    }

    struct BuyTicket {
        uint256 eventId;
        uint256 categoryIndex;
        string boughtLocation;
    }

    event CreatedEvent(address indexed owner, uint256 eventId, Event);

    event SoldTicketDetails2(SoldTicketStruct, address owner);
}
