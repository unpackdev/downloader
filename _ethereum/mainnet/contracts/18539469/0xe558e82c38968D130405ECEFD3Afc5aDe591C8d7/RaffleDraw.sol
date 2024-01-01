//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

contract RaffleDraw {
    address public owner;
    address public payout;
    mapping(uint256 => address) public entrants;
    mapping(address => uint256) public ticketsHeld;
    bool public raffleOpen;
    uint256 public drawTimestamp;
    uint256 public drawNo;
    uint256 public ticketPrice;
    uint256 public totalPot;
    uint256 public totalTickets;
    uint256 public totalEntrants;
    uint256 public lastDrawNo;
    uint256 public lastTotalTickets;
    uint256 public lastTotalPot;
    uint256 public lastFirstAmt;
    uint256 public lastSecondAmt;
    uint256 public lastThirdAmt;
    address public lastFirstAddress;
    address public lastSecondAddress;
    address public lastThirdAddress;

    constructor(
        uint256 _timestamp,
        uint256 _ticketPrice,
        address _payout
    ) {
        owner = msg.sender;
        payout = _payout;
        ticketPrice = _ticketPrice;
        raffleOpen = true;
        drawTimestamp = _timestamp;
        drawNo = 0;
    }

    function enter() public payable {
        require(msg.value >= ticketPrice, "Eth send is below ticket price");
        require(raffleOpen, "Raffle not open");
        require(totalEntrants < 1000, "Raffle max entrants reached");
        uint256 ticketQty = msg.value / ticketPrice;
        if (ticketsHeld[msg.sender] == 0) {
            entrants[totalEntrants] = msg.sender;
            totalEntrants++;
        }
        ticketsHeld[msg.sender] += ticketQty;
        totalPot += msg.value;
        totalTickets += ticketQty;
    }

    function getAddresses() public view returns (address[] memory) {
        address[] memory ret = new address[](totalEntrants);
        for (uint256 i = 0; i < totalEntrants; i++) {
            ret[i] = entrants[i];
        }
        return ret;
    }

    function getTicketQty() public view returns (uint256[] memory) {
        uint256[] memory ret = new uint256[](totalEntrants);
        for (uint256 i = 0; i < totalEntrants; i++) {
            ret[i] = ticketsHeld[entrants[i]];
        }
        return ret;
    }

    function draw(
        address _a,
        address _b,
        address _c,
        uint256 _timestamp,
        uint256 _ticketPrice
    ) public payable {
        require(msg.sender == owner, "Caller must be the owner");
        require(raffleOpen, "Raffle not open");
        lastDrawNo = drawNo;
        lastTotalTickets = totalTickets;
        lastTotalPot = totalPot;
        if (totalTickets > 0) {
            lastFirstAddress = _a;
            lastSecondAddress = _b;
            lastThirdAddress = _c;
            lastFirstAmt = totalPot / 2;
            lastSecondAmt = totalPot / 4;
            lastThirdAmt = totalPot / 5;
            payable(_a).transfer(lastFirstAmt);
            payable(_b).transfer(lastSecondAmt);
            payable(_c).transfer(lastThirdAmt);
            payable(payout).transfer(totalPot / 20);
        } else {
            delete lastFirstAddress;
            delete lastSecondAddress;
            delete lastThirdAddress;
            lastFirstAmt = 0;
            lastSecondAmt = 0;
            lastThirdAmt = 0;
        }
        for (uint256 i = 0; i < totalEntrants; i++) {
            delete ticketsHeld[entrants[i]];
            delete entrants[i];
        }
        ticketPrice = _ticketPrice;
        drawTimestamp = _timestamp;
        drawNo++;
        totalPot = 0;
        totalTickets = 0;
        totalEntrants = 0;
    }
}