// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./MerkleProof.sol";

contract FoodlesSerumToken is ERC1155, Ownable {

    bytes32 public merkleRoot = "";
    mapping(address => bool) public serumClaimed;

    string public baseURI;
    string public placeholderURI;

    address public mutatedFoodlesAddress;

    constructor() ERC1155("ipfs://QmVosUSn9auYYDGB1M85Dtg9vFXoxoW6suKyG5w3gzY8kQ") {}

    //
    // Admin
    //

    function setMutatedFoodlesAddress(address mutatedFoodlesAddress_) external onlyOwner {
        mutatedFoodlesAddress = mutatedFoodlesAddress_;
    }

    //
    // Minting
    //

    /**
     * Mint serum.
     * @notice This function is only available to those whitelisted.
     * @param numTokens The number of tokens to mint.
     * @param proof The Merkle proof used to validate the leaf is in the root.
     */
    function mintSerum(
        uint256 numTokens,
        bytes32[] memory proof //FIXME calldata?
    ) external {
        require(!serumClaimed[msg.sender], "FoodlesSerumToken: Serums already claimed");
        bytes32 leaf = keccak256(abi.encode(msg.sender, numTokens));
        require(verify(merkleRoot, leaf, proof), "FoodlesSerumToken: Not a valid proof");

        serumClaimed[msg.sender] = true;

        _mint(msg.sender, 0, numTokens, "");
    }

    /**
     * Burn serum
     * @notice This can only be called by the Mutated Foodles contract.
     */
    function burnSerum(address from, uint256 numTokens) external {
        require(msg.sender == mutatedFoodlesAddress, "FoodleSerumToken: Only the Mutated Foodles contract can burn");
        _burn(from, 0, numTokens);
    }

    //
    // Merkle
    //

    /**
     * Set the Merkle root.
     * @dev The Merkle root is calculated from [address, availableAmt] pairs.
     */
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    /**
     * Verify the Merkle proof is valid.
     * @param root The Merkle root. Use the value stored in the contract.
     * @param leaf The leaf. A [address, availableAmt] pair.
     * @param proof The Merkle proof used to validate the leaf is in the root.
     */
    function verify(
        bytes32 root,
        bytes32 leaf,
        bytes32[] memory proof
    ) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

}
