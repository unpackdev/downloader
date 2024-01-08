// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IDaoEventsV2.sol";
import "./EventTicketV2.sol";

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract DaoEventsV2 is IDaoEventsV2, Ownable, EventTicketV2, ReentrancyGuard {
    uint256 public eventIds;
    address public tokenAddress;
    IOracle public oracle;
    // address public USDT = 0x0cEbA92298b655C827D224D33461B4A1F9C418a6; // rinkeby new usdt
        address public USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // matic mainnet new usdt


    // Mapping from owner to list of owned events IDs.
    mapping(address => uint256[]) private ownedEvents;
    // Mapping from event ID to event revenue
    mapping(uint256 => uint256) public eventRevenue;
    // Mapping from eventId to Event struct
    mapping(uint256 => Event) public events;
    // Mapping from address to eventId to boughOrNot
    mapping(address => mapping(uint256 => bool)) ticketBought;

    constructor(address _token, address _oracle) {
        tokenAddress = _token;
        oracle = IOracle(_oracle);
    }

    modifier goodTime(uint256 _time) {
        require(_time > block.timestamp, "Invalid Timestamp.");
        _;
    }

    modifier eventExist(uint256 _id) {
        require(_id <= eventIds, "Event does not exist.");
        _;
    }

    function getTicketLimited(uint256 _eventId)
        public
        view
        returns (bool[] memory)
    {
        return events[_eventId].ticketLimited;
    }

    function getTktQnty(uint256 _eventId)
        public
        view
        returns (uint256[] memory)
    {
        return events[_eventId].tktQnty;
    }

    function getPrices(uint256 _eventId)
        public
        view
        returns (uint256[] memory)
    {
        return events[_eventId].prices;
    }

    function getTktQntySold(uint256 _eventId)
        public
        view
        returns (uint256[] memory)
    {
        return events[_eventId].tktQntySold;
    }

    function getCategories(uint256 _eventId)
        public
        view
        returns (string[] memory)
    {
        return events[_eventId].categories;
    }

    function changeToken(address _token) public onlyOwner() {
        tokenAddress = _token;
    }

    function createEvent(Event memory _event) public goodTime(_event.time) {
        // increment the eventId
        eventIds++;

        require(_event.owner == _msgSender(), "Caller must be the owner");
        require(_event.totalQntySold == 0, "Quantity sold must be zero");
        require(
            _event.categories.length == _event.tktQnty.length &&
                _event.categories.length == _event.prices.length &&
                _event.categories.length == _event.tktQntySold.length,
            "Invalid categories"
        );

        uint256 _totalTktQnty;
        uint256 _categoriesLength = _event.categories.length;
        for (uint256 i = 0; i < _categoriesLength; i++) {
            require(
                _event.tktQntySold[i] == 0,
                "Category quantity sold must be zero"
            );

            _totalTktQnty = _totalTktQnty + _event.tktQnty[i];

            if (!_event.ticketLimited[i]) {
                require(
                    _event.tktQnty[i] == 0,
                    "quantity should be zero for unlimited tickets"
                );
            }
        }

        require(
            _event.totalQuantity == _totalTktQnty,
            "Total ticket quantity not match category quantity"
        );

        uint256 _eventId = eventIds;

        // updating state
        events[_eventId] = _event;
        ownedEvents[_msgSender()].push(_eventId);

        // emiting event
        emit CreatedEvent(_msgSender(), _eventId, _event);
    }

    function buyTicket(BuyTicket memory _buyTicket)
        public
        eventExist(_buyTicket.eventId)
        goodTime(events[_buyTicket.eventId].time)
    {
        // increment ticketId
        ticketIds++;

        Event memory _event = events[_buyTicket.eventId];

        uint256 _usdtPrice;
        uint256 _phnxPrice;

        if (!_event.token) {
            // event is free
            _usdtPrice = 0;
            _phnxPrice = 0;
        } else {
            // event is paid
            _usdtPrice = _event.prices[_buyTicket.categoryIndex];
            _phnxPrice = (_usdtPrice * oracle.fetch(USDT)) / 1e18;
        }

        uint256 _ticketId = ticketIds;

        if (_event.ticketLimited[_buyTicket.categoryIndex]) {
            require(
                _event.totalQuantity > _event.totalQntySold &&
                    _event.tktQnty[_buyTicket.categoryIndex] >
                    _event.tktQntySold[_buyTicket.categoryIndex],
                "ticket quantity exceeded"
            );
        }

        if (_event.oneTimeBuy) {
            require(
                !ticketBought[_msgSender()][_buyTicket.eventId],
                "ticket to be bought only one time"
            );
            ticketBought[_msgSender()][_buyTicket.eventId] = true;
        }

        _buyTicketInternal(_buyTicket, _event, _phnxPrice, _ticketId);

        uint256 _totalQuantitySold = events[_buyTicket.eventId].totalQntySold;
        uint256 _categoryTktsSold =
            events[_buyTicket.eventId].tktQntySold[_buyTicket.categoryIndex];

        emit SoldTicketDetails1(
            Ticket(
                _buyTicket.eventId,
                _ticketId,
                _buyTicket.boughtLocation,
                _event.location
            )
        );

        emit SoldTicketDetails2(
            SoldTicketStruct(
                _event.token,
                _buyTicket.eventId,
                _ticketId,
                _msgSender(),
                _usdtPrice,
                _phnxPrice,
                block.timestamp,
                _totalQuantitySold,
                _categoryTktsSold,
                _event.categories[_buyTicket.categoryIndex]
            ),
            _event.owner
        );
    }

    function eventsOf(address _owner) public view returns (uint256[] memory) {
        return ownedEvents[_owner];
    }

    function getEventsCount() public view returns (uint256) {
        return eventIds;
    }

    function _buyTicketInternal(
        BuyTicket memory _buyTicket,
        Event memory _event,
        uint256 _phnxPrice,
        uint256 _ticketId
    ) internal nonReentrant {
        eventRevenue[_buyTicket.eventId] =
            eventRevenue[_buyTicket.eventId] +
            _phnxPrice;
        events[_buyTicket.eventId].totalQntySold =
            events[_buyTicket.eventId].totalQntySold +
            1;
        events[_buyTicket.eventId].tktQntySold[_buyTicket.categoryIndex] =
            events[_buyTicket.eventId].tktQntySold[_buyTicket.categoryIndex] +
            1;

        tickets.push(
            Ticket({
                eventId: _buyTicket.eventId,
                seatNo: _ticketId,
                boughtLocation: _buyTicket.boughtLocation,
                eventLocation: _event.location
            })
        );

        if (_event.token) {
            // event is paid
            // transfer the tokens to event owner
            IERC20(tokenAddress).transferFrom(
                _msgSender(),
                _event.owner,
                _phnxPrice
            );
        }

        // mint ticketId
        _mint(_msgSender(), _ticketId);
    }
}
