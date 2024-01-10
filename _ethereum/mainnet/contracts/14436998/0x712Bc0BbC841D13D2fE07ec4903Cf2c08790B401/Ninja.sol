// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract NinjaTickets is Ownable {
    IERC20 public StealthToken;

    mapping (uint256 => ticket) public IdToTicket;
    mapping (uint256 => address[]) public IdToUsers;

    struct ticket {
      string name;
      uint256 cost;
      uint256 id;
      uint256 totalSupply;
      uint256 maxSupply;
    }

    constructor(address _tokenContract) {
        StealthToken = IERC20(_tokenContract);
    }

    function addTicket(ticket memory _ticket) public onlyOwner {
        require(IdToTicket[_ticket.id].maxSupply == 0, "Ticket already exists");
        IdToTicket[_ticket.id] = _ticket;
    }

    function buyTicket(uint256 ticketId) public {
        require(IdToTicket[ticketId].totalSupply < IdToTicket[ticketId].maxSupply, "Max supply reached");

        uint256 allowance = StealthToken.allowance(msg.sender, address(this));
        require(allowance >= IdToTicket[ticketId].cost, "Check the token allowance");
        require(StealthToken.transferFrom(msg.sender, address(this), IdToTicket[ticketId].cost), "Failed to send");

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
        uint256 balance = StealthToken.balanceOf(address(this));
        StealthToken.transfer(msg.sender, balance);
    }
}