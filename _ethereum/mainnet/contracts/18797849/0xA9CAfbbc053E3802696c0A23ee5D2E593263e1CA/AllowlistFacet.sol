// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * AllowlistLib authored by Bling Artist Lab
 * Version 0.1.0
 * 
 * This library is designed to work in conjunction with
 * AllowlistFacet - it facilitates diamond storage and shared
 * functionality associated with AllowlistFacet.
/**************************************************************/

import "./MerkleProof.sol";

library AllowlistLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("allowlistlibrary.storage");

    struct state {
        bytes32 merkleRoot;
    }

    /**
    * @dev Return stored state struct.
    */
    function getState() internal pure returns (state storage _state) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            _state.slot := position
        }
    }

    /**
    * @dev Verify that provided merkle proof & leaf node
    *      combination belong to the stored merkle root.
    */
    function validateProof(bytes32[] calldata proof, address leaf) internal view returns (bool) {
        return MerkleProof.verify(
            proof,
            getState().merkleRoot,
            keccak256(abi.encodePacked(leaf))
        );
    }

    /**
    * @dev Require that the caller and the provided merkle proof
    *      belong to the stored merkle root.
    */
    function requireValidProof(bytes32[] calldata proof) internal view {
        require(validateProof(proof, msg.sender), "AllowlistFacet: invalid merkle proof");
    }
}

/**************************************************************\
 * AllowlistFacet authored by Bling Artist Lab
 * Version 0.1.0
/**************************************************************/

import "./GlobalState.sol";

contract AllowlistFacet {
    /**
    * @dev Get stored Merkle root.
    */
    function merkleRoot() external view returns (bytes32) {
        return AllowlistLib.getState().merkleRoot;
    }
    
    /**
    * @dev Set stored Merkle root.
    */
    function setMerkleRoot(bytes32 root) external {
        GlobalState.requireCallerIsAdmin();
        AllowlistLib.getState().merkleRoot = root;
    }
}