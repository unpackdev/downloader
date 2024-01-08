// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "./Ownable.sol";

interface IMirrorFeeRegistry {
    function maxFee() external returns (uint256);

    function updateMaxFee(uint256 newFee) external;
}

/**
 * @title MirrorFeeRegistry
 * @author MirrorXYZ
 */
contract MirrorFeeRegistry is IMirrorFeeRegistry, Ownable {
    uint256 public override maxFee = 500;

    constructor(address owner_) Ownable(owner_) {}

    function updateMaxFee(uint256 newFee) external override onlyOwner {
        maxFee = newFee;
    }
}
