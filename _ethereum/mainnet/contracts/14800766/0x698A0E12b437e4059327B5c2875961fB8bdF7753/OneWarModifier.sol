// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IOneWarDescriptor.sol";
import "./IOneWarModifier.sol";

contract OneWarModifier is IOneWarModifier, Ownable {
    address payable public override treasury;
    bool public isDescriptorLocked;
    IOneWarDescriptor public override descriptor;

    modifier onlyTreasury() {
        require(msg.sender == treasury, "sender is not OneWar Treasury");
        _;
    }

    modifier whenDescriptorNotLocked() {
        require(!isDescriptorLocked, "descriptor is locked");
        _;
    }

    constructor(address payable _treasury) {
        treasury = _treasury;
    }

    function setTreasury(address payable _treasury) external override onlyTreasury {
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function setDescriptor(IOneWarDescriptor _descriptor) external override onlyTreasury whenDescriptorNotLocked {
        descriptor = _descriptor;
        emit DescriptorUpdated(_descriptor);
    }

    function lockDescriptor() external override onlyTreasury whenDescriptorNotLocked {
        isDescriptorLocked = true;
        emit DescriptorLocked();
    }
}
