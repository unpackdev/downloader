// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 *
 * @title CryptoligaWL
 * @author Peter Smith
 *
 * @dev CryptoligaWL enables whitelist verification using a MerkleTree
 * 
 **/

import "./MerkleProof.sol";

abstract contract CryptoligaWL {
    
    bytes32 private root;

    mapping(address => uint[]) private userMints;

    string[] private coins;

    // error NotWhitelisted();
    // error IncorrectProof(bytes32[] _proof, bytes32 _root, bytes32 _leaf);

    event RootChanged();

    function _setRoot(bytes32 _root) internal {
        root = _root;
        emit RootChanged();
    }

    function _checkValidity(bytes32[] calldata _merkleProof)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        return MerkleProof.verify(_merkleProof, root, leaf);
        
    }
}