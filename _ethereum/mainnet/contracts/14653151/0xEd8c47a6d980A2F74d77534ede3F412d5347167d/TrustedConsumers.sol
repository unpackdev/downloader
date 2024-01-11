// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract TrustedConsumers {
    // Enable future consumption of the contract (without approvals)
    mapping(address => bool) public _trustedConsumers;

    function _setTrustedConsumer(address trustedConsumer, bool active) internal virtual {
        require(trustedConsumer != address(0x0), "trustedConsumer Need a valid address");
        _trustedConsumers[trustedConsumer] = active;
    }

    function isTrusted(address addr) public view returns (bool) {
        // returns false is not set
        return _trustedConsumers[addr];
    }
}
