// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title HidingVault's state management library
 * @author KeeperDAO
 * @dev Library that manages the state of the HidingVault
 */
library LibHidingVault {
    //  HIDING_VAULT_STORAGE_POSITION = keccak256("hiding-vault.keeperdao.storage")
    bytes32 constant HIDING_VAULT_STORAGE_POSITION = 0x9b85f6ce841a6faee042a2e67df9613579f746ca80e5eb1163b287041381d23c;
    
    struct State {
        NFTLike nft;
        mapping(address => bool) recoverableTokensBlacklist;
    }

    function state() internal pure returns (State storage s) {
        bytes32 position = HIDING_VAULT_STORAGE_POSITION;
        assembly {
            s.slot := position
        } 
    }
}

interface NFTLike {
    function ownerOf(uint256 _tokenID) view external returns (address);
    function implementations(bytes4 _sig) view external returns (address);
}