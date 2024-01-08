// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./HasCrunchParent.sol";

contract CrunchVesting is HasCrunchParent {
    event TokensReleased(uint256 amount);
    event TokenVestingRevoked();

    /* beneficiary of tokens after they are released. */
    address public beneficiary;

    /** the start time of the token vesting. */
    uint256 public start;
    /** the cliff time of the token vesting. */
    uint256 public cliff;
    /** the duration of the token vesting. */
    uint256 public duration;

    /** the amount of the token released. */
    uint256 public released;

    /** true if the vesting can be revoked. */
    bool public revokable;

    /** true if the vesting has been revoked. */
    bool public revoked;

    constructor(
        CrunchToken crunch,
        address _overrideOwner,
        address _beneficiary,
        uint256 _cliffDuration,
        uint256 _duration,
        bool _revokable
    ) HasCrunchParent(crunch) {
        require(
            _beneficiary != address(0),
            "Vesting: beneficiary is the zero address"
        );
        require(
            _cliffDuration <= _duration,
            "Vesting: cliff is longer than duration"
        );
        require(_duration > 0, "Vesting: duration is 0");

        beneficiary = _beneficiary;
        start = block.timestamp;
        cliff = start + _cliffDuration;
        duration = _duration;
        revokable = _revokable;

        if (_overrideOwner != address(0)) {
            transferOwnership(_overrideOwner);
        }
    }

    /** @notice Transfers vested tokens to beneficiary. */
    function release() public {
        uint256 unreleased = releasableAmount();

        require(unreleased > 0, "Vesting: no tokens are due");

        released += unreleased;

        crunch.transfer(beneficiary, unreleased);

        emit TokensReleased(unreleased);
    }

    /** @notice Allows the owner to revoke the vesting. Tokens already vested remain in the contract, the rest are returned to the owner. */
    function revoke() public onlyOwner {
        require(revokable, "Vesting: token not revokable");
        require(!revoked, "Vesting: token already revoked");

        uint256 balance = crunch.balanceOf(address(this));

        uint256 unreleased = releasableAmount();
        uint256 refund = balance - unreleased;

        revoked = true;

        crunch.transfer(owner(), refund);

        emit TokenVestingRevoked();
    }

    /** @dev Calculates the amount that has already vested but hasn't been released yet. */
    function releasableAmount() public view returns (uint256) {
        return vestedAmount() - released;
    }

    /** @dev Calculates the amount that has already vested. */
    function vestedAmount() public view returns (uint256) {
        uint256 currentBalance = crunch.balanceOf(address(this));
        uint256 totalBalance = currentBalance + released;

        if (block.timestamp < cliff) {
            return 0;
        } else if ((block.timestamp >= start + duration) || revoked) {
            return totalBalance;
        } else {
            return (totalBalance * (block.timestamp - start)) / duration;
        }
    }
}
