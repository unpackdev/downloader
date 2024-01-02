// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./OwnableUpgradeable.sol";

abstract contract Whitelist is OwnableUpgradeable {
    mapping(address => bool) public whitelist;

    event UpdateWhitelist(address indexed addr, bool status);

    /**
     * @dev Throws if called by any account that's not whitelisted.
     */
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "not whitelisted");
        _;
    }

    function updateWhitelist(address[] calldata addrs, bool[] calldata status) external onlyOwner {
        require(addrs.length == status.length, "invalid whitelist data");
        unchecked {
            for (uint256 i; i < addrs.length; ++i) {
                whitelist[addrs[i]] = status[i];
                emit UpdateWhitelist(addrs[i], status[i]);
            }
        }
    }
}
