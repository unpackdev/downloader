
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";

contract SalesActivation is Ownable {
    // og start time
    uint256 public ogSalesStartTime;
    // og end time
    uint256 public ogSalesEndTime;
    // Public sales start time
    uint256 public publicSalesStartTime;
    // presales start time
    uint256 public preSalesStartTime;
    // presales end time
    uint256 public preSalesEndTime;

    modifier isPublicSalesActive() {
        require(
            isPublicSalesActivated(),
            "Public sales not started"
        );
        _;
    }

    modifier isPreSalesActive() {
        require(
            isPreSalesActivated(),
            "Presales not started"
        );
        _;
    }

    modifier isOGSalesActive() {
        require(
            isOGSalesActivated(),
            "OG sales not started"
        );
        _;
    }

    constructor(uint256 _ogSalesStartTime, uint256 _ogSalesEndTime, uint256 _publicSalesStartTime, uint256 _preSalesStartTime, uint256 _preSalesEndTime) {
        ogSalesStartTime = _ogSalesStartTime;
        ogSalesEndTime = _ogSalesEndTime;
        publicSalesStartTime = _publicSalesStartTime;
        preSalesStartTime = _preSalesStartTime;
        preSalesEndTime = _preSalesEndTime;
    }

    function isPublicSalesActivated() public view returns (bool) {
        return
            publicSalesStartTime > 0 && block.timestamp >= publicSalesStartTime;
    }

    function setPublicSalesTime(uint256 _startTime) external onlyOwner {
        publicSalesStartTime = _startTime;
    }

    function isOGSalesActivated() public view returns (bool) {
        return
            ogSalesStartTime > 0 &&
            ogSalesEndTime > 0 &&
            block.timestamp >= ogSalesStartTime &&
            block.timestamp <= ogSalesEndTime;
    }

    function setOGSalesTime(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        require(
            _endTime >= _startTime,
            "OGActivation: End time should be later than start time"
        );
        ogSalesStartTime = _startTime;
        ogSalesEndTime = _endTime;
    }

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