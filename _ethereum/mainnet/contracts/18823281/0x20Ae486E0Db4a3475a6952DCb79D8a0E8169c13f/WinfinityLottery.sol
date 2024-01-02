/*

WINFINITY + LOTTERY

Website:  https://winfinity.bet
Telegram: https://t.me/winfinitybet
Twitter:  https://twitter.com/winfinitybet
Bot:      https://t.me/winfinitybet_bot
dApp:     https://app.winfinity.bet
Docs:     https://docs.winfinity.bet

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract WinfinityLottery is Ownable, ReentrancyGuard {

    address payable private revshareAddress;

    uint256 private revsharePercentage = 20;

    bytes32 public merkleRoot;
    mapping(address => uint256) public claimed;

    uint256 public ticketsPerRound;
    uint256 public availableTickets;
    uint256 public ticketPrice;

    bool private newTicketSetupPending;
    uint256 private newTicketPrice;

    event TicketsBought(address from, uint256 amount, uint256 price);
    event SetupChanged(uint256 newPrice, uint256 newTicketAmount);
    event WinClaimed(address from, uint256 amount);

    constructor(address _revshareAddress) {
        revshareAddress = payable(_revshareAddress);

        // Start values
        ticketsPerRound = 100;
        availableTickets = 100;
        ticketPrice = 0.01 ether;
    }

    function setTicketParams(uint256 newPrice, uint256 newTicketsPerRound) external onlyOwner {
        require(newPrice > 0 && newTicketsPerRound >= 10, "Ticket sales not active");
        require(newPrice != ticketPrice || newTicketsPerRound != ticketsPerRound, "No changes made");

        if (newPrice != ticketPrice) {
            newTicketPrice = newPrice;
        }

        if (newTicketsPerRound != ticketsPerRound) {
            ticketsPerRound = newTicketsPerRound;
        }

        newTicketSetupPending = true;
    }

    function manuallyEndRound() external onlyOwner {
        // Winners will be selected among current entries
        // Winners will share prize pool accumulated up until this point
        emit TicketsBought(address(0), availableTickets, 0);
        availableTickets = ticketsPerRound;
        if (newTicketSetupPending) {
            ticketPrice = newTicketPrice;
            newTicketSetupPending = false;
            emit SetupChanged(newTicketPrice, ticketsPerRound);
        }
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function claim(uint256 totalAmount, bytes32[] calldata proof) external nonReentrant {
        require(merkleRoot != bytes32(0), "No merkle root set");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, totalAmount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid merkle proof");

        require(totalAmount > claimed[msg.sender], "Wins already claimed");
        uint256 claimableAmount = totalAmount - claimed[msg.sender];

        (bool success, ) = address(msg.sender).call{value: claimableAmount}("");
        require(success);

        claimed[msg.sender] += claimableAmount;

        emit WinClaimed(msg.sender, claimableAmount);
    }

    // Ticket amount is calculated from received ETH value
    function buyTickets() public payable {
        require(ticketPrice > 0, "Ticket price is not set");
        require(msg.value >= ticketPrice, "Not enough funds for a ticket");
        require(availableTickets > 0, "Tickets are sold out");

        uint256 ticketsAmount = msg.value / ticketPrice;

        if (ticketsAmount > availableTickets) {
            ticketsAmount = availableTickets;
        }
        
        require(msg.value >= (ticketsAmount * ticketPrice), "Not enough funds for ticket amount");
        availableTickets -= ticketsAmount;

        uint256 ticketsCost = ticketsAmount * ticketPrice;
        uint256 refundableAmount = msg.value - ticketsCost;

        uint256 revshareAmount = (ticketsCost * revsharePercentage) / 100;
        (bool rSuccess, ) = address(revshareAddress).call{value: revshareAmount}("");
        require(rSuccess);

        if (refundableAmount > 0) {
            (bool refunded, ) = address(msg.sender).call{value: refundableAmount}("");
            require(refunded);
        }

        emit TicketsBought(msg.sender, ticketsAmount, (ticketPrice * (100 - revsharePercentage))/100);

        if (availableTickets == 0) {
            availableTickets = ticketsPerRound;
            if (newTicketSetupPending) {
                ticketPrice = newTicketPrice;
                newTicketSetupPending = false;
                emit SetupChanged(newTicketPrice, ticketsPerRound);
            }
        }
    }

    receive() external payable {
        buyTickets();
    }
}
