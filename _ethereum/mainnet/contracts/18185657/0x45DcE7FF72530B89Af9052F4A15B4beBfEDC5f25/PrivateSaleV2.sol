// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "./PrivateSale.sol";

contract PrivateSaleV2 is PrivateSale {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bool public paused;

    error Paused();
    error NotPauser();

    function deposit() public payable override {
        if (paused) {
            revert Paused();
        }

        super.deposit();
    }

    function pause() public {
        if (!hasRole(PAUSER_ROLE, msg.sender)) {
            revert NotPauser();
        }

        paused = true;
    }

    function unpause() public {
        if (!hasRole(PAUSER_ROLE, msg.sender)) {
            revert NotPauser();
        }

        paused = false;
    }
}
