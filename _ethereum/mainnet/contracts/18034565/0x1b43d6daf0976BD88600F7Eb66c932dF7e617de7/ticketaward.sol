// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";

contract TicketAward is Ownable {
    
    address private _sbt;
    uint256 public _multiplierAlpha = 100;

    constructor() {}

    modifier onlySbt() {
        require(msg.sender == _sbt, "Only callable by the SBT contract");
        _;
    }

    // MARK: - Only Owner
    function setMultiplierAlpha(uint256 alpha) external onlyOwner {
        _multiplierAlpha = alpha;
    }

    function setSbt(address sbt) external onlyOwner {
        _sbt = sbt;
    }

    // MARK: - Only SBT
    function calculateAward(uint256 amount, uint8 level) external view onlySbt returns (uint256) {
        return level + (_multiplierAlpha * amount * level / 100) - (_multiplierAlpha * level / 100);
    }


}