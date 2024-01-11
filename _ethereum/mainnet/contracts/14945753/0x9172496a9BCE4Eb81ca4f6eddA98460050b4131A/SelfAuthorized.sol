// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;

/**
 * @title SelfAuthorized - authorizes current contract to perform actions.
 */
contract SelfAuthorized {
    error SelfAuthorized__notWallet();

    modifier authorized() {
        if (msg.sender != address(this)) revert SelfAuthorized__notWallet();

        _;
    }
}
