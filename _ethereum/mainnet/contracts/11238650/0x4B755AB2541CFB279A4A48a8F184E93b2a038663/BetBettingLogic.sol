pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;

import "./BetDataStructure.sol";

import "./Statistics.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./BetWinner.sol";
import "./BetTokenSender.sol";

abstract contract BetBettingLogic is ReentrancyGuard, BetDataStructure, Ownable, BetWinner, BetTokenSender {
    SignableStatistics public stats;

    uint public ticketPrice;

    constructor (uint _ticketPrice) public {
        ticketPrice = _ticketPrice;
    }

    function setTicketPrice (uint _ticketPrice) public onlyOwner {
        ticketPrice = _ticketPrice;
    }

    function changeClaimPercentage (uint _claimPercentage) public onlyOwner {
        claimPercentage = _claimPercentage;
    }

    event AddedBet (uint weekId, address better, uint ticketPrice, uint32 deaths, uint32 infections, uint betId);
    event WeekConcluded (uint weekId, uint32 deaths, uint32 infections, address winner, uint32 winningDeaths, uint32 winningInfections, uint winningBetId);

    function _bet (address better, uint amountSent, bytes memory betData) internal _allowedToBet nonReentrant {
        require(amountSent == ticketPrice);
        (uint32 deaths, uint32 infections) = abi.decode(betData, (uint32, uint32));

        BetWeek storage betWeek = betWeeks[getWeek()];

        betWeek.betters.push(better);
        betWeek.deaths.push(deaths);
        betWeek.infections.push(infections);
        betWeek.total += ticketPrice;

        emit AddedBet(getWeek(), better, amountSent, deaths, infections, (betWeek.infections.length - 1));
    }

    function concludeWeek (uint weekId, uint32 deaths, uint32 infections, uint winnerIndex) public onlyOwner {
        require(weekId < getWeek(), "Still in week");
        BetWeek storage week = betWeeks[weekId];
        require(week.concluded == false, "Week already concluded");

        week.finalDeaths = deaths;
        week.finalInfections = infections;
        week.concluded = true;

        address winnerAddress = week.betters[winnerIndex];
        uint32 winningDeaths = week.deaths[winnerIndex];
        uint32 winningInfections = week.infections[winnerIndex];

        send(winnerAddress, (week.total / 100) * (100 - claimPercentage));
        send(owner(), (week.total / 100) * claimPercentage);

        emit WeekConcluded (weekId, deaths, infections, winnerAddress, winningDeaths, winningInfections, winnerIndex);

        week.concluded = true;
    }

    modifier _allowedToBet () {
        require(allowedToBet(), "Betting is not open today");
        _;
    }

    uint8 closeDay = 4;
    uint8 startDay = 10;

    function setCloseDay (uint8 _closeDay) onlyOwner public {
        closeDay = _closeDay;
    }

    function setStartDay (uint8 _startDay) onlyOwner public {
        startDay = _startDay;
    }

    function allowedToBet () public view returns (bool) {
        uint8 currentDay = getDay();
        // uint currentWeek = getWeek();
        if (startDay == 10) {
            return currentDay < closeDay;
        } else {
            return currentDay > startDay && currentDay < closeDay;
        }
    }

    function getDay () public view returns (uint8 _day) {
        _day = uint8((block.timestamp / 1 days) % 7);
    }

    function getWeek () public view returns (uint _week) {
        _week = block.timestamp / 1 weeks;       
    }
}