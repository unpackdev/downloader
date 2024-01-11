// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./draft-EIP712Upgradeable.sol";
import "./MinimalForwarderUpgradeable.sol";

/**
 * @title RecometForwarderBase
 * RecometForwarderBase - The RecometForwarder central contract.
 * @dev Simple minimal forwarder to be used together with an ERC2771 compatible contract. See {ERC2771Context}.
 */
contract RecometForwarderBase is
    EIP712Upgradeable,
    MinimalForwarderUpgradeable
{
    function __RecometForwarderBase_init(
        string memory name,
        string memory version
    ) public initializer {
        __EIP712_init_unchained(name, version);
    }

    uint256[50] private __gap;
}
