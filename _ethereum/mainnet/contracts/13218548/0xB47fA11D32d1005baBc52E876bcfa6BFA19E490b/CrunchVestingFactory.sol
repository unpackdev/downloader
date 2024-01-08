// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./CrunchVesting.sol";

contract CrunchVestingFactory is HasCrunchParent {
    event Created(
        CrunchVesting indexed vesting,
        CrunchToken crunch,
        address owner,
        address beneficiary,
        uint256 cliffDuration,
        uint256 duration,
        bool revokable
    );

    uint256 public constant oneYear = 365.25 days;

    constructor(CrunchToken crunch) HasCrunchParent(crunch) {}

    function create(
        address beneficiary,
        uint256 cliffDuration,
        uint256 duration,
        bool revokable
    ) public onlyOwner returns (CrunchVesting vesting) {
        vesting = new CrunchVesting(
            crunch,
            owner(),
            beneficiary,
            cliffDuration,
            duration,
            revokable
        );

        emit Created(
            vesting,
            crunch,
            owner(),
            beneficiary,
            cliffDuration,
            duration,
            revokable
        );
    }

    function createSimple(address beneficiary, bool revokable)
        public
        onlyOwner
        returns (CrunchVesting)
    {
        return create(beneficiary, oneYear, oneYear * 4, revokable);
    }

    function transferToOwner() public onlyOwner returns (uint256 balance) {
        balance = crunch.balanceOf(address(this));

        if (balance == 0) {
            revert("Vesting Factory: no token are in the factory");
        }

        crunch.transfer(owner(), balance);
    }
}
