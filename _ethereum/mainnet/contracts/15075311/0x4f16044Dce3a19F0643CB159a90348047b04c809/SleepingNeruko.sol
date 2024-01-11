// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./ERC721.sol";
import "./SignedAllowance.sol";

/// @title SleepingNeruko - https://etherealstates.art
/// @author Artist: GenuineHumanArt (https://twitter.com/GenuineHumanArt)
/// @author Developer: dievardump (https://twitter.com/dievardump, dievardump@gmail.com)
contract SleepingNeruko is Ownable, ERC721, SignedAllowance {
    error UnknownToken();

    string public baseURI;
    string public contractURI;

    address public metadataManager;

    constructor(
        string memory contractURI_,
        string memory baseURI_,
        address allowancesSigner_
    ) ERC721('Sleeping Neruko', 'SNKO') {
        contractURI = contractURI_;
        baseURI = baseURI_;
        _setAllowancesSigner(allowancesSigner_);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory uri)
    {
        if (!_exists(tokenId)) revert UnknownToken();

        address meta = metadataManager;
        if (meta != address(0)) {
            uri = ERC721(metadataManager).tokenURI(tokenId);
        } else {
            uri = baseURI;
        }
    }

    /////////////////////////////////////////////////////////
    // Royalties                                           //
    /////////////////////////////////////////////////////////

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == this.royaltyInfo.selector ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Royalties - ERC2981
    /// @param tokenId the tokenId
    /// @param amount the amount it's sold for
    /// @return the recipient and amount to send to it
    function royaltyInfo(uint256 tokenId, uint256 amount)
        external
        view
        returns (address, uint256)
    {
        return (owner(), (amount * 5) / 100);
    }

    /////////////////////////////////////////////////////////
    // Mint                                                //
    /////////////////////////////////////////////////////////

    /// @notice mint (with signature)
    /// @param tokenId the token id to mint
    /// @param signature allowing the mint
    function mint(uint256 tokenId, bytes calldata signature) public {
        // we just validate the signature, without "using" it.
        // this saves 20k gas and since the tokenId is the nonce, it's not possible to remint
        // the same token, so retrying to use would revert
        validateSignature(msg.sender, tokenId, signature);

        // this fails if tokenId already minted
        _mint(msg.sender, tokenId);
    }

    /////////////////////////////////////////////////////////
    // Gated Owner                                         //
    /////////////////////////////////////////////////////////

    /// @notice Allows owner to set the metadata manager (in case Neruko stops sleeping one day)
    /// @param newMetadataManager the new metadata manager
    function setMetadataManager(address newMetadataManager) external onlyOwner {
        metadataManager = newMetadataManager;
    }

    /// @notice Allows owner to set the current signer for the allowlist
    /// @param newSigner the address of the new signer
    function setAllowancesSigner(address newSigner) external onlyOwner {
        _setAllowancesSigner(newSigner);
    }

    /// @notice allows owner to update the base URI for metadata
    /// @param newBaseURI the new base URI
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /// @notice allows owner to update the contractURI
    /// @param newContractURI the new contract URI
    function setContractURI(string calldata newContractURI) external onlyOwner {
        contractURI = newContractURI;
    }
}
