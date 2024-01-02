// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import "./GenericErrors.sol";

function addressZeroCheck(address _candidate) pure {
    if (_candidate == address(0)) revert AddressZero();
}
