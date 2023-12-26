// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./OperatorFilterV1.sol";

abstract contract OperatorFilterConsumerV1 {
    error OperatorNotAllowed();

    // =============================================================
    // Main Implementation
    // =============================================================

    modifier onlyApprovableOperator(address _operator) virtual {
        if (OperatorFilterV1(getOperatorFilterAddress()).isDenied(_operator)) {
            revert OperatorNotAllowed();
        }

        _;
    }

    modifier onlyAllowedOperator(address _from) virtual {
        // Token owners will always be allowed to transfer
        if (msg.sender != _from && OperatorFilterV1(getOperatorFilterAddress()).isDenied(msg.sender)) {
            revert OperatorNotAllowed();
        }

        _;
    }

    // =============================================================
    // Required Child Implementation
    // =============================================================

    function getOperatorFilterAddress() public view virtual returns (address);
}
