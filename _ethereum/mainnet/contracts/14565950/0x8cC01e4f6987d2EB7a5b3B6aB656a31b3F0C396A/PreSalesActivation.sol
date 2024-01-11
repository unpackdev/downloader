// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";

contract PreSalesActivation is Ownable {
    uint256 public preSalesStartTime = 0xFFFFFFFFF;
    uint256 public preSalesEndTime = 0xFFFFFFFFF;

    modifier isPreSalesActive() {
        require(
            isPreSalesActivated(),
            "PreSalesActivation: Sale is not activated"
        );
        _;
    }

    constructor() {}

    function isPreSalesActivated() public view returns (bool) {
        return
            preSalesStartTime > 0 &&
            preSalesEndTime > 0 &&
            block.timestamp >= preSalesStartTime &&
            block.timestamp <= preSalesEndTime;
    }

    function setPreSalesTime(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        require(
            _endTime >= _startTime,
            "PreSalesActivation: End time should be later than start time"
        );
        preSalesStartTime = _startTime;
        preSalesEndTime = _endTime;
    }
}
