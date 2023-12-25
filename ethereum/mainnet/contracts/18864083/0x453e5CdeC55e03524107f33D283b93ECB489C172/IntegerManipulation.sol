// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract IntegerManipulation {
    int public integerValue;

    event ValueChanged(int oldValue, int newValue);

    function increaseValue(int _amount) public {
        int oldValue = integerValue;
        integerValue += _amount;
        emit ValueChanged(oldValue, integerValue);
    }

    function decreaseValue(int _amount) public {
        int oldValue = integerValue;
        integerValue -= _amount;
        emit ValueChanged(oldValue, integerValue);
    }

    function getIntegerValue() public view returns (int) {
        return integerValue;
    }
}
