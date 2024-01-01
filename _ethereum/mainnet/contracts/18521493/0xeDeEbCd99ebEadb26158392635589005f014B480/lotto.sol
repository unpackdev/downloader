/*
*░█████╗░██╗░░██╗██╗░░░░░░█████╗░████████╗████████╗░█████╗░
*██╔══██╗╚██╗██╔╝██║░░░░░██╔══██╗╚══██╔══╝╚══██╔══╝██╔══██╗
*██║░░██║░╚███╔╝░██║░░░░░██║░░██║░░░██║░░░░░░██║░░░██║░░██║
*██║░░██║░██╔██╗░██║░░░░░██║░░██║░░░██║░░░░░░██║░░░██║░░██║
*╚█████╔╝██╔╝╚██╗███████╗╚█████╔╝░░░██║░░░░░░██║░░░╚█████╔╝
*░╚════╝░╚═╝░░╚═╝╚══════╝░╚════╝░░░░╚═╝░░░░░░╚═╝░░░░╚════╝░
*https://0xlotto.online
*/
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "./Strings.sol";

contract LOttO {
    uint256 public ticketPrice = 0.02 ether;
    uint256 public maxTickets = 50;
    uint256 public ticketCommission = 0.005 ether;
    uint256 public duration = 1440 minutes;

    uint256 public expiration;
    address public lotteryOperator;
    uint256 public operatorTotalCommission = 0;
    address public lastWinner;
    uint256 public lastWinnerAmount;

    mapping(address => uint256) public winnings;
    address[] public tickets;

    modifier isOperator() {
        require(msg.sender == lotteryOperator, "Caller is not the operator");
        _;
    }

    modifier isWinner() {
        require(IsWinner(), "Caller is not a winner");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == lotteryOperator, "Caller is not the owner");
        _;
    }

    constructor() {
        lotteryOperator = msg.sender;
        expiration = block.timestamp + duration;
    }

    function getTickets() public view returns (address[] memory) {
        return tickets;
    }

    function getWinningsForAddress(address addr) public view returns (uint256) {
        return winnings[addr];
    }

    function BuyTickets() public payable {
        require(msg.value % ticketPrice == 0, "Invalid ticket price");
        uint256 numOfTicketsToBuy = msg.value / ticketPrice;

        require(numOfTicketsToBuy <= RemainingTickets(), "Not enough tickets available.");

        for (uint256 i = 0; i < numOfTicketsToBuy; i++) {
            tickets.push(msg.sender);
        }
    }

    function DrawWinnerTicket() public isOperator {
        require(tickets.length > 0, "No tickets were purchased");

        bytes32 blockHash = blockhash(block.number - tickets.length);
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, blockHash)));
        uint256 winningTicket = randomNumber % tickets.length;

        address winner = tickets[winningTicket];
        lastWinner = winner;
        winnings[winner] += (tickets.length * (ticketPrice - ticketCommission));
        lastWinnerAmount = winnings[winner];
        operatorTotalCommission += (tickets.length * ticketCommission);
        delete tickets;
        expiration = block.timestamp + duration;
    }

    function restartDraw() public isOperator {
        require(tickets.length == 0, "Cannot restart draw while tickets are still available");
        delete tickets;
        expiration = block.timestamp + duration;
    }

    function checkWinningsAmount() public view returns (uint256) {
        return winnings[msg.sender];
    }

    function WithdrawWinnings() public isWinner {
        uint256 reward2Transfer = winnings[msg.sender];
        winnings[msg.sender] = 0;
        payable(msg.sender).transfer(reward2Transfer);
    }

    function RefundAll() public {
        require(block.timestamp >= expiration, "The lottery has not expired yet");

        for (uint256 i = 0; i < tickets.length; i++) {
            address payable to = payable(tickets[i]);
            tickets[i] = address(0);
            to.transfer(ticketPrice);
        }
        delete tickets;
    }

    function WithdrawCommission() public isOperator {
        uint256 commission2Transfer = operatorTotalCommission;
        operatorTotalCommission = 0;
        payable(msg.sender).transfer(commission2Transfer);
    }

    function IsWinner() public view returns (bool) {
        return winnings[msg.sender] > 0;
    }

    function CurrentWinningReward() public view returns (uint256) {
        return tickets.length * ticketPrice;
    }

    function RemainingTickets() public view returns (uint256) {
        return maxTickets - tickets.length;
    }

    function updateLotteryParameters(uint256 newTicketPrice, uint256 newMaxTickets, uint256 newTicketCommission, uint256 newDuration) public onlyOwner {
        ticketPrice = newTicketPrice;
        maxTickets = newMaxTickets;
        ticketCommission = newTicketCommission;
        duration = newDuration;
    }
}
