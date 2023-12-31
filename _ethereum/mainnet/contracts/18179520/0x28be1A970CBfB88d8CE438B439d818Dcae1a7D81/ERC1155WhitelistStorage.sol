// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

struct ProxySpender {
    bytes32 name;
    mapping(uint256 => bool) blacklisted;
}

library ERC1155WhitelistStorage {
    struct Layout {
        mapping(uint256 => bool) blacklistForCompliance;
        mapping(address => ProxySpender) proxySpenders;
        string baseURI;
        string contractURI;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("irrigation.contracts.storage.ERC1155Whitelist");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
