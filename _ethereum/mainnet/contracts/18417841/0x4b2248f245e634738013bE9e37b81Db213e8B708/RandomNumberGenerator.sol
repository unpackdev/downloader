// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract RandomNumberGenerator {
    uint256 private constant MAX_NUMBER = 10000;
    uint256 private seed;
    address private deployer;
    struct RandomNumberData {
        uint256 randomNumber;
        uint256 timestamp;
    }
    RandomNumberData[] private randomNumberHistory;
    event NewRandomNumber(uint256 randomNumber, uint256 timestamp);

    constructor() {
        // Set the seed to a combination of the block timestamp2 and the address of the last miner 1
        seed = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.coinbase))
        );
        // Set the deployer as the contract creator
        deployer = msg.sender;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Caller is not the deployer");
        _;
    }

    function generateRandomNumber() public onlyDeployer {
        // Generate the random number between 1 and MAX_NUMBER
        uint256 randomNumber = (uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    msg.sender,
                    seed
                )
            )
        ) % MAX_NUMBER) + 1;
        // Update the seed for the next random number generation
        seed = randomNumber;
        // Create a new RandomNumberData struct
        RandomNumberData memory data = RandomNumberData(
            randomNumber,
            block.timestamp
        );
        // Add the new random number data to the history
        randomNumberHistory.push(data);
        // Emit the event with the new random number and timestamp
        emit NewRandomNumber(randomNumber, block.timestamp);
    }

    function getHistory() public view returns (RandomNumberData[] memory) {
        return randomNumberHistory;
    }
}