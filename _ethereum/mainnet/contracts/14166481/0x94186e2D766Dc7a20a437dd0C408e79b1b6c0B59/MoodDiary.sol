//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./console.sol";

contract MoodDiary {
    string private mood;

    function setMood(string memory _mood) public {
        mood = _mood;
    }

    function getMood() public view returns (string memory) {
        return mood;
    }
}
