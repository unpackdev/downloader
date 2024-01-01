// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract BillyTheGoat {
    uint public foodEaten;

    event FeedBilly(uint amount);

    function feedBilly(uint _amount) public {
        foodEaten += _amount;
        emit FeedBilly(_amount);
    }

    function checkFoodEaten() public view returns (uint) {
        return foodEaten;
    }
}