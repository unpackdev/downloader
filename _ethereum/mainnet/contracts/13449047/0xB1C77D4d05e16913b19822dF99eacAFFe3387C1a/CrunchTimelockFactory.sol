// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./CrunchTimelock.sol";
import "./HasCrunchParent.sol";

contract CrunchTimelockFactory is HasCrunchParent {
    event Created(
        CrunchTimelock indexed timelock,
        CrunchToken crunch,
        address beneficiary,
        uint256 releaseDuration
    );

    uint256 public constant oneYear = 365.25 days;

    constructor(CrunchToken crunch) HasCrunchParent(crunch) {}

    function create(address beneficiary, uint256 releaseDuration)
        public
        onlyOwner
        returns (CrunchTimelock timelock)
    {
        timelock = new CrunchTimelock(crunch, beneficiary, releaseDuration);

        emit Created(timelock, crunch, beneficiary, releaseDuration);
    }

    function createSimple(address beneficiary)
        public
        onlyOwner
        returns (CrunchTimelock)
    {
        return create(beneficiary, oneYear);
    }

    function transferToOwner() public onlyOwner returns (uint256 balance) {
        balance = crunch.balanceOf(address(this));

        if (balance == 0) {
            revert("Timelock Factory: no token are in the factory");
        }

        crunch.transfer(owner(), balance);
    }
}
