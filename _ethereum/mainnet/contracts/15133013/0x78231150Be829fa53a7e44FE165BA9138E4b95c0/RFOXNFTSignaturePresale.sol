// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./MerkleProof.sol";
import "./RFOXNFTSignatureSale.sol";
import "./BaseRFOXNFTPresale.sol";

contract RFOXNFTSignaturePresale is RFOXNFTSignatureSale, BaseRFOXNFTPresale
{
    /**
     * @dev Overwrite the authorizePublicSale modifier from the base RFOX NFT contract.
     * In the standard sale contract, the saleStartTime is the starting time of the public sale.
     * In the presale contract, the saleStartTime will be considered as the starting time of the presale.
     * and the publicSaleStartTime will be the starting time of the public sale.
     */
    modifier authorizePublicSale() override {
        require(
            block.timestamp >= publicSaleStartTime,
            "Sale has not been started"
        );
        _;
    }

    /**
     * @dev Each whitelisted address has quota to mint for the presale.
     * There is limit amount of token that can be minted during the presale.
     * This function has additional feature to prevent the spam minting by bot.
     *
     * @param tokensNumber How many NFTs for buying this round.
     * @param proof The bytes32 array from the offchain whitelist address.
     * @param salt The random number (unique per address) to be used for the signature verification.
     * @param signature The signature of the authorized signer address.
     */
    function buyNFTsPresale(uint256 tokensNumber, bytes32[] calldata proof, uint256 salt, bytes calldata signature)
        external
        payable
        whenNotPaused
        callerIsUser
        authorizePresale(proof)
        checkUsedSignature(signature)
    {
        require(_isValidSignature(keccak256(abi.encodePacked(msg.sender,address(this),salt)), signature), "Invalid signature");

        usedSignature[signature] = true;

        _buyNFTsPresale(tokensNumber);
    }
}
