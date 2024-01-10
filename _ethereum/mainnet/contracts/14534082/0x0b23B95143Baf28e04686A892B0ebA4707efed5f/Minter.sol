// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "./MerkleProof.sol";
import "./ElfNFT.sol";

contract Minter is Authorizable {
    // The ERC721 contract to mint
    ElfNFT public immutable elfNFT;

    // The merkle root with deposits encoded into it as hash [address, tokenId]
    // Assumed to be a node sorted tree
    bytes32 public merkleRoot;

    constructor(address _token, bytes32 _merkleRoot) {
        elfNFT = ElfNFT(_token);
        merkleRoot = _merkleRoot;
    }

    /// @notice mints an NFT for an approved account in the merkle tree
    /// @param tokenId the unique id for the token
    /// @param merkleProof the merkle proof associated with the sender's address
    /// and tokenId that validates minting
    function mint(uint256 tokenId, bytes32[] memory merkleProof) public {
        // Hash the user plus the token id
        bytes32 leafHash = keccak256(abi.encodePacked(msg.sender, tokenId));

        // Verify the proof for this leaf
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leafHash),
            "Invalid Proof"
        );

        // mint the token, assuming it hasn't already been minted
        elfNFT.mint(msg.sender, tokenId);
    }

    function setRewardsRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // because we may change conditions for minting down the road, allow
    // transferring ownership of the NFT contract to a new minter.
    function transferNFTOwnership(address newOwner) public onlyOwner {
        elfNFT.setOwner(newOwner);
    }
}
