//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./MerkleProofUpgradeable.sol";

/**
 * @title Abstract contract to have a whitelist sale
 */
abstract contract WhiteListSale {
    bytes32 public whiteListMerkleTreeRoot;
    mapping(address => uint256) public addressToMintCount;

    /**
     * @notice Sets the whitelist merkle tree root
     * @param _whiteListMerkleTreeRoot whitelist MerkleTree root
     */
    function _setWhiteListMerkleTreeRoot(bytes32 _whiteListMerkleTreeRoot)
        internal
    {
        whiteListMerkleTreeRoot = _whiteListMerkleTreeRoot;
    }

    /**
     * @notice Generate a leaf of the Merkle tree with a nonce and the address of the sender
     * @param maxMintCount Maximum numer of tokens the user can mint
     * @param mintPrice Mint price
     * @param addr Address of the minter
     * @return leaf generated
     */
    function generateLeaf(
        uint256 maxMintCount,
        uint256 mintPrice,
        address addr
    ) private pure returns (bytes32 leaf) {
        return keccak256(abi.encodePacked(maxMintCount, mintPrice, addr));
    }

    /**
     * @notice Verifies the proof of the sender to confirm they are in given list
     * @param maxMintCount Maximum numer of tokens the user can mint
     * @param mintPrice Mint price
     * @param root Merkle tree root
     * @param proof Proof of the minter
     * @param addr Address of the minter
     * @return valid TRUE if the proof is valid, FALSE otherwise
     */
    function verifyProof(
        uint256 maxMintCount,
        uint256 mintPrice,
        bytes32 root,
        bytes32[] memory proof,
        address addr
    ) internal pure returns (bool valid) {
        return
            MerkleProofUpgradeable.verify(
                proof,
                root,
                generateLeaf(maxMintCount, mintPrice, addr)
            );
    }

    /**
     * @dev This function should be called after mint as it increments the user's mint count
     * @param mintCount Number of tokens that will be minted
     */
    function afterMint(uint256 mintCount) internal virtual {
        addressToMintCount[msg.sender] += mintCount;
    }

    /**
     * @notice modifier to check if a user can mint in WL
     * @param maxMintCount Maximum token the user can mint
     * @param mintPrice Mint price
     * @param proof Proof to verify that the caller is allowed to mint
     * @param mintCount Number of tokens to mint
     */
    modifier canMintWhiteList(
        uint256 maxMintCount,
        uint256 mintPrice,
        bytes32[] calldata proof,
        uint256 mintCount
    ) {
        require(
            verifyProof(
                maxMintCount,
                mintPrice,
                whiteListMerkleTreeRoot,
                proof,
                msg.sender
            ),
            "Address is not in the whitelist"
        );
        require(
            msg.value == mintPrice * mintCount,
            "Not the right amount of ETH"
        );
        require(
            addressToMintCount[msg.sender] + mintCount < maxMintCount + 1,
            "Requested mint count exceeds maximum mints allowed"
        );
        _;
    }
}
