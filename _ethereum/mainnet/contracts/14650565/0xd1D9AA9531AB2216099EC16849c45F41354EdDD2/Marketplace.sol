// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract RoboTickets is Ownable {
    IERC20 public RoboToken;

    mapping (uint256 => ticket) public IdToTicket;
    mapping (uint256 => address[]) public IdToUsers;

    struct ticket {
        uint8 maxSupply;
        uint8 totalSupply;
        uint16 id;
        uint256 cost;
        string name;
        bool physical;
    }

    constructor(address _tokenContract) {
        RoboToken = IERC20(_tokenContract);
    }

    function addTicket(ticket memory _ticket) public onlyOwner {
        require(IdToTicket[_ticket.id].maxSupply == 0, "Ticket already exists");
        IdToTicket[_ticket.id] = _ticket;
    }

    function buyTicket(uint256 ticketId) public {
        require(IdToTicket[ticketId].totalSupply < IdToTicket[ticketId].maxSupply, "Max supply reached");
        require(RoboToken.allowance(msg.sender, address(this)) >= IdToTicket[ticketId].cost, "Check the token allowance");
        require(RoboToken.transferFrom(msg.sender, address(this), IdToTicket[ticketId].cost), "Failed to send");
        IdToTicket[ticketId].totalSupply += 1;
        IdToUsers[ticketId].push(msg.sender);
    }

    function getUsers(uint256 ticketId) public view returns(address[] memory) {
        return IdToUsers[ticketId];
    }

    function removeUsers(uint256 ticketId) public onlyOwner {
        delete IdToUsers[ticketId];
    }

    function tokenWithdraw() public onlyOwner {
        uint256 balance = RoboToken.balanceOf(address(this));
        RoboToken.transfer(msg.sender, balance);
    }
}
