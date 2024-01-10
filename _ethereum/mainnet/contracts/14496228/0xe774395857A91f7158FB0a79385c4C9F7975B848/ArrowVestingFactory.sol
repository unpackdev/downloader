pragma solidity ^0.8.11;

// SPDX-License-Identifier: MIT

import "./Clones.sol";
import "./ArrowVestingBase.sol";

/**
    Factory contract for creating vesting wallets from their base implementations.
 */
contract ArrowVestingFactory {
    address public vestingImplementation;

    event NewVestingAgreement(
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds,
        address vestingWalletAddress
    );

    constructor() {
        vestingImplementation = address(new ArrowVestingBase());
    }

    /**
        Creates a new cloned vesting wallet from its base implementation.

        The wallet will initially be empty and should have appropriate ERC20 tokens and ETH transferred to it after creation.
     */
    function createVestingSchedule(
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds
    ) external returns (address clone) {
        clone = Clones.clone(vestingImplementation);
        ArrowVestingBase(payable(clone)).initialize(beneficiaryAddress, startTimestamp, durationSeconds);
        emit NewVestingAgreement(beneficiaryAddress, startTimestamp, durationSeconds, payable(clone));
    }
}
