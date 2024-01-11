// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./VestingWalletUpgradeable.sol";

import "./VestingFactory.sol";

contract Vesting is VestingWalletUpgradeable, OwnableUpgradeable {
    address public immutable factory = msg.sender;
    uint64 internal _start;
    uint64 internal _duration;

    function initialize(
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds
    ) external initializer() {
        // don't initialize on purpose (we don't want to use the standard slots)
        _transferOwnership(beneficiaryAddress);
        _start    = startTimestamp;
        _duration = durationSeconds;
    }

    function beneficiary() public view virtual override returns (address) {
        return owner();
    }

    function start() public view virtual override returns (uint256) {
        return _start;
    }

    function duration() public view virtual override returns (uint256) {
        return _duration;
    }

    function _transferOwnership(address newOwner) internal virtual override {
        address oldOwner = owner();
        super._transferOwnership(newOwner);

        VestingFactory(factory).ownershipUpdate(oldOwner, newOwner);
    }
}