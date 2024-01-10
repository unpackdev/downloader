// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;
import "./Owned.sol";

contract TeamTranche is Owned {
    uint256 public releaseTime;
    uint256 public amount;

    bool private released = false; 

    constructor(uint256 _releaseTime, uint256 _amount) {
        releaseTime = _releaseTime;
        amount = _amount;
    }

    /**
        Checks if the tranche can be released
    */
    function isReleasable() public view returns (bool) {
        if (released == true) return false;
        return block.timestamp > releaseTime;
    }

    /**
        Updated the tranches released value to true
    */
    function setReleased() ownerRestricted public {
        released = true;
    }
}