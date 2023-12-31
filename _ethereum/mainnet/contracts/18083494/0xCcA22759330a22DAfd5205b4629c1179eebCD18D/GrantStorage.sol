// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library GrantStorage {
    struct Layout {
        mapping(bytes32 daoId => address vestingWallet) vestingWallets;
        mapping(address token => bool isTokenAllowed) tokensAllowed;
        address[] allowedTokenList;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.GrantStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
