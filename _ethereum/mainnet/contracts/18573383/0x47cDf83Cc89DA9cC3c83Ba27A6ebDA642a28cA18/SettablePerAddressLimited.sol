// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import "./CallbackerWithAccessControl.sol";
import "./PerAddressLimited.sol";

/**
 * @notice Seller with a steerer-settable per-address purchase limit.
 */
abstract contract SettablePerAddressLimited is PerAddressLimited, CallbackerWithAccessControl {
    /**
     * @notice Sets the per-address purchase limit.
     */
    function setMaxPerAddress(uint64 maxPerAddress_) external onlyRole(DEFAULT_STEERING_ROLE) {
        _setMaxPerAddress(maxPerAddress_);
    }
}
