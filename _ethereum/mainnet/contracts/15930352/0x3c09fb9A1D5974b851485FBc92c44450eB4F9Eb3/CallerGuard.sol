// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import "./ManagerRole.sol";


abstract contract CallerGuard is ManagerRole {

    error ContractCallerError();

    bool public contractCallerAllowed;

    event SetContractCallerAllowed(bool indexed value);

    modifier checkCaller {
        if (msg.sender != tx.origin && !contractCallerAllowed) {
            revert ContractCallerError();
        }

        _;
    }

    function setContractCallerAllowed(bool _value) external onlyManager {
        contractCallerAllowed = _value;

        emit SetContractCallerAllowed(_value);
    }
}
