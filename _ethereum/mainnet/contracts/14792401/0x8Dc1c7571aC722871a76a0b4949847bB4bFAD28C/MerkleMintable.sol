// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MerkleProof.sol";

// @author erosemberg from almostfancy.com
contract MerkleMintable {
    bytes32 public merkleRoot;

    mapping(address => uint256) private amountMinted;

    // @dev checks whether an address can mint more
    // while remaining within the permitted limits
    modifier canMint(
        address who,
        uint256 toMint,
        uint256 maxMint
    ) {
        require(
            amountMinted[who] + toMint <= maxMint,
            "MerkleMintable: You can't mint any more tokens!"
        );
        _;
    }

    // @dev returns whether an address is on the merkle list
    modifier isAbleToMint(address who, bytes32[] memory proof) {
        require(
            isMerkleVerified(who, proof),
            "MerkleMintable: You are not on the merkle list"
        );
        _;
    }

    function _setMerkleRoot(bytes32 _root) internal virtual {
        merkleRoot = _root;
    }

    function _merkleMint(address to, uint256 n) internal virtual {
        amountMinted[to] += n;
    }

    function isMerkleVerified(address claimer, bytes32[] memory proof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(claimer));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
}
