// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Sphinx.sol"; // Import the Sphinx token contract
import "./SphinxRandomNumber.sol"; // Import the SphinxRandomNumber contract
import "./Ownable.sol"; // Import OpenZeppelin's Ownable contract

contract SphinxWinnerPicker is Ownable {
    Sphinx private tokenContract;
    SphinxRandomNumber private randomNumberContract;

    uint256 private lastRequestId;
    mapping(uint256 => bool) private requestProcessed;
    address[] public previousWinners; // Array to store previous winners
    address public currentWinner; // Variable to store the current winner

    event WinnerPicked(address winner, uint256 timestamp);

    constructor(address _tokenContractAddress, address _randomNumberContractAddress, address _owner) Ownable(_owner) {
        tokenContract = Sphinx(_tokenContractAddress);
        randomNumberContract = SphinxRandomNumber(_randomNumberContractAddress);
    }

    function pickWinner() public onlyOwner {
        lastRequestId = randomNumberContract.requestRandomWords();
        requestProcessed[lastRequestId] = false;
    }

    function processWinner(uint256 requestId) public onlyOwner {
        require(requestProcessed[requestId] == false, "Request already processed");
        (bool fulfilled, uint256 randomWord) = randomNumberContract.getRequestStatus(requestId);

        require(fulfilled, "Random number not yet fulfilled");

        address[] memory holders = tokenContract.getTokenHolders();
        require(holders.length > 0, "No token holders found");

        uint256 winnerIndex = randomWord % holders.length;
        address winner = holders[winnerIndex];

        previousWinners.push(winner); // Store the winner's address in the history
        currentWinner = winner; // Update the current winner
        emit WinnerPicked(winner, block.timestamp);
        requestProcessed[requestId] = true;
    }

    function getCurrentWinner() public view returns (address) {
        return currentWinner;
    }
}

