//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Errors.sol";

contract ZetaFallback {
    address private _deployer;

    constructor() {
        _deployer = msg.sender;
    }

    /**
     * Fallback function
     * It is called when a non-existent function is called on the contract.
     * It is required to be marked external.
     * It has no arguments
     * It can not return any thing.
     * It can be defined one per contract.
     * If not marked payable, it will throw exception if contract receives plain ether without data.
     *
     */
    fallback() external payable {
        // TODO Log event that someone was trying to call a non-existing function
    }

    receive() external payable {
        if (msg.value != 0) {
            payable(_deployer).transfer(msg.value);
        }
    }

    function withdraw() external {
        if (msg.sender != _deployer) {
            revert NotADeployer();
        }
        payable(_deployer).transfer(address(this).balance);
    }
}
