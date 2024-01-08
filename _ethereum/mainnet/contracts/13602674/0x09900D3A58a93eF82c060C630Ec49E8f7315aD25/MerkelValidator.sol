pragma solidity >=0.6.0 <0.7.0;

import "./IERC20.sol";
import "./MerkleProof.sol";
import "./IMerkleValidator.sol";

contract MerkelValidator is IMerkleValidator {
    bytes32 public override level2UpgradeMerkelRoot;
    bytes32 public override level3UpgradeMerkelRoot;
    bytes32 public override level4UpgradeMerkelRoot;
    bytes32 public override level5UpgradeMerkelRoot;

    /// @notice Responsible for validating user merkle proof
    /// @param id monkey id
    /// @param merkleProof Merkle proof of the user
    function verify(
        bytes32 merkleRoot,
        uint256 id,
        bytes32[] memory merkleProof
    ) public view override {
        // Verify the merkle proof.
        // using the uniswap merkel distributor technique
        // can be updated
        bytes32 node = keccak256(abi.encodePacked(id, true));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "MerkelValidator: Invalid proof");
    }
}
