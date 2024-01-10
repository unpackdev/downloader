// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";

contract PublicSalesActivation is Ownable {
    uint256 public publicSalesStartTime;

    modifier isPublicSalesActive() {
        require(
            isPublicSalesActivated(),
            "PublicSalesActivation: Sale is not activated"
        );
        _;
    }

    constructor() {}

    function isPublicSalesActivated() public view returns (bool) {
        return
            publicSalesStartTime > 0 && block.timestamp >= publicSalesStartTime;
    }

    // 1648742400 : start time at 31 Mar 2022 (4pm GMT) in seconds
    function setPublicSalesTime(uint256 _startTime) external onlyOwner {
        publicSalesStartTime = _startTime;
    }
}