// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./LibDiamond.sol";
import "./LibAppStorage.sol";
import "./MerkleProof.sol";

library AllowList {
    event AllowListUpdate();

    function checkValidity(bytes32[] calldata _merkleProof)
        internal
        view
        returns (bool)
    {
        LibDiamond.enforceIsContractOwner();
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, s.allowListRoot, leaf),
            "Incorrect proof"
        );
        return true;
    }
}
