// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./INFTPotion.sol";
import "./INFTPotionValidator.sol";

contract NFTPotionValidator is INFTPotionValidator, Ownable {
    //------------
    // Storage
    //------------
    bytes32 public merkleRoot;
    INFTPotion public NFTContract;
    mapping(uint256 => bool) public isTokenValidated;

    //---------------
    // Constructor
    //---------------
    constructor(address _NFTContract, bytes32 _merkleRoot) {
        merkleRoot = _merkleRoot;
        NFTContract = INFTPotion(_NFTContract);
    }

    //---------------------
    // Validate functions
    //---------------------

    /**
        @notice Validates the decrypted secret against the merkle root and stores it in the finalMessage
                if validation is successful.

        @param tokenId The token id of the NFT that is being validated
        @param decryptedSecret The decrypted secret associated with the NFT
        @param proof The merkle proof for the decrypted secret

        @dev secretStartPost can be used as a key to understand if a piece of secret has been already
        validated or not
      */
    function validate(
        uint256 tokenId,
        bytes calldata decryptedSecret,
        bytes32[] calldata proof
    ) public {
        require(NFTContract.ownerOf(tokenId) == _msgSender(), "ITO"); // Invalid Token Owner

        (uint256 secretStartPos, , bool found) = NFTContract.getSecretPositionLength(tokenId);
        require(found, "Token ID could not be found in rarity config");

        _verify(tokenId, decryptedSecret, proof);

        isTokenValidated[tokenId] = true;

        emit NFTValidated(_msgSender(), tokenId, secretStartPos, decryptedSecret);
    }

    /**
        @notice Batch validation of multiple NFTs

        @param tokenIds List of token Ids to be validated
        @param decryptedSecrets List of decrypted secrets associated with the token Ids
        @param proofs List of merkle proofs for the decrypted secrets

        @dev See validate() for more details
      */
    function validateList(
        uint256[] calldata tokenIds,
        bytes[] calldata decryptedSecrets,
        bytes32[][] calldata proofs
    ) external {
        require(tokenIds.length == decryptedSecrets.length, "ALM"); // Array Length Mismatch
        require(tokenIds.length == proofs.length, "ALM"); // Array Length Mismatch

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            validate(tokenIds[i], decryptedSecrets[i], proofs[i]);
        }
    }

    //--------------------
    // View functions
    //--------------------

    /**
        Returns the validation status for a list of token Ids

        @param tokenIds List of token Ids to get the status for

        @return status List of validation statuses for the token Ids
     */
    function getValidationStatus(uint256[] calldata tokenIds) external view returns (bool[] memory status) {
        status = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            status[i] = isTokenValidated[tokenIds[i]];
        }
    }

    //--------------------
    // Internal functions
    //--------------------

    /**
        Verifies the merkle proof for the given decrypted secret

        @param tokenId The token id of the NFT that is being validated
        @param decryptedSecret The decrypted secret associated with the NFT
        @param proof The merkle proof for the decrypted secret

    */
    function _verify(
        uint256 tokenId,
        bytes calldata decryptedSecret,
        bytes32[] calldata proof
    ) internal view {
        bytes memory data = abi.encodePacked(tokenId, decryptedSecret);
        bytes32 leaf = keccak256(data);

        require(MerkleProof.verify(proof, merkleRoot, leaf), "FV"); // Failed Validation
    }
}
