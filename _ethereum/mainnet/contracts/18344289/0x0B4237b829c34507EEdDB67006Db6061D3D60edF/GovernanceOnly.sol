// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "Errors.sol";

contract GovernanceOnly {
    address public immutable governance;

    modifier governanceOnly() {
        if (msg.sender != governance)
            revert Errors.NotAuthorized(msg.sender, governance);
        _;
    }

    constructor(address _governance) {
        governance = _governance;
    }
}
