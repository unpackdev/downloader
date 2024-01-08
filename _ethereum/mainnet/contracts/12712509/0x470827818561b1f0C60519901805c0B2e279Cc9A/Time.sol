// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Time is ERC20 {

    uint256 constant DAY_IN_SECONDS = 86400;
    
    uint256 lastTimeClaim;
    uint256 timeFrequency;
    address timeGuardian;
    address timeBank; // exchange address
    event RewardSent(
        address timeMiner,
        uint256 reward,
        uint256 timeReleased,
        uint256 timestamp
    );
    event TimeFrequencyEvent(uint256 timeFrequency);
    event TimeBankEvent(address timeBank);

    constructor() ERC20("Time", "TIME") {
        lastTimeClaim = block.timestamp;
        timeGuardian = msg.sender;
        timeFrequency = DAY_IN_SECONDS;
        _mint(
            address(this),
            (block.timestamp - 1230940800) * 10**uint256(decimals())
        ); // the starting time anniversary
        _burn(
            address(this),
            (block.timestamp - 1230940800) * 10**uint256(decimals())
        );
    }

    function mineTime() public {
        require(
            (block.timestamp - lastTimeClaim) >= timeFrequency,
            "TIME is released one day every day"
        );
        uint256 reward =
            (block.timestamp - lastTimeClaim - timeFrequency) *
                10**uint256(decimals());
        uint256 timeReleased = timeFrequency * 10**uint256(decimals());
        _mint(timeBank, timeReleased); // Time Contract recieves a day - 5 sec ideally
        _mint(msg.sender, reward); // Time Distributor recieves 5 seconds
        lastTimeClaim = block.timestamp;
        emit RewardSent(
            msg.sender,
            reward,
            timeReleased,
            lastTimeClaim
        );
    }

    function setTimeBank(address Bank) public {
        require(msg.sender == timeGuardian, "you are not the Time guardian");
        timeBank = Bank;
        emit TimeBankEvent(timeBank);
    }

    function setTimeFrequency(uint256 frequency) public {
        require(msg.sender == timeGuardian, "you are not the Time guardian");
        timeFrequency = frequency;
        emit TimeFrequencyEvent(timeFrequency);
    }

    function getLastTimeClaim() public view returns (uint256) {
        return lastTimeClaim;
    }

    function getTimeBankAddress() public view returns (address) {
        return timeBank;
    }

}
