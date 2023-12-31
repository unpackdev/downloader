// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract Lottery {
    address public manager;
    address[] public players;

    uint256 public winnerStake = 90;
    uint256 public teamStake = 100 - winnerStake;

    uint256 public ticketPrice = 0.01 ether;

    constructor() {
        manager = msg.sender;
    }

    function enter(uint256 n) public payable {
        require(n > 0, "Minimum 1 ticket is required.");
        require(msg.value == n * ticketPrice, "Amount is invalid.");
        for (uint256 i = 0; i < n; i++) {
            players.push(msg.sender);
        }
    }

    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encode(block.timestamp, players)));
    }

    function pickWinner() public restricted {
        uint256 winnerAmount = (address(this).balance * winnerStake) / 100;
        uint256 feesAmount = (address(this).balance * teamStake) / 100;
        uint256 index = random() % players.length;
        payable(players[index]).transfer(winnerAmount);
        payable(manager).transfer(feesAmount);
        players = new address[](0);
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
}