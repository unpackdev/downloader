// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";

// pre sales config
contract PreSalesActivation is Ownable {
    uint256 public preSalesStartTime;
    uint256 public preSalesEndTime;

    // is pre sales active
    modifier isPreSalesActive() {
        require(
            isPreSalesActivated(),
            "Pre sales: Sale is not activated"
        );
        _;
    }

    constructor() {}

    // is pre sales activated
    function isPreSalesActivated() public view returns (bool) {
        return
            preSalesStartTime > 0 &&
            preSalesEndTime > 0 &&
            block.timestamp >= preSalesStartTime &&
            block.timestamp <= preSalesEndTime;
    }

    // set pre sales time
    function setPreSalesTime(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        require(
            _endTime >= _startTime,
            "Pre sales: End time should be later than start time"
        );
        preSalesStartTime = _startTime;
        preSalesEndTime = _endTime;
    }
}