// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";

contract PublicSalesActivation is Ownable {
    uint256 public publicSalesStartTime = 0xFFFFFFFFF;

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

    function setPublicSalesTime(uint256 _startTime) external onlyOwner {
        publicSalesStartTime = _startTime;
    }
}
