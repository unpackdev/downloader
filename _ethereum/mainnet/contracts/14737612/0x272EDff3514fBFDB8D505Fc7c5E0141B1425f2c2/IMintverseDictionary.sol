// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMintverseDictionary {
    // Return true if the minter is eligible to mint the given amount word token with the signature.
    function verifyMint(uint256 maxQuantity, bytes calldata SIGNATURE) external view returns(bool);
    // Return true if the minter is eligible to claim the given amount word token with the signature.
    function verifyClaim(uint256 maxQuantity, bytes calldata SIGNATURE) external view returns(bool);
    // Airdrop dictionary tokens to previously purchase minters.
    function airdropDictionary(address to) external;
    // Mint giveaway tokens to an address by owner.
    function mintGiveawayDictionary(address to, uint256 quantity) external;
    // Whitelisted addresses mint specific amount of tokens with signature & maximum mintable amount to verify.
    function mintWhitelistDictionary(uint256 quantity, uint256 maxClaimNum, bytes calldata SIGNATURE) external payable;
    // Whitelisted addresses claim specific amount of tokens with signature & maximum mintable amount to verify.
    function claimWhitelistDictionary(uint256 quantity, uint256 maxClaimNum, bytes calldata SIGNATURE) external payable;
    // Public addresses mint specific amount of tokens.
    function mintPublicDictionary(uint256 quantity) external payable;
    // Public addresses claim specific amount of tokens.
    function claimPublicDictionary(uint256 quantity) external payable;

    // View function to get all the token Id that a address owns.
    function tokensOfOwner(address owner) external view returns(uint256[] memory);

    // Set the variables to enable the whitelist mint phase by owner.
    function setWLMintPhase(bool hasWLMintStarted, uint256 wlMintTimestamp) external;
    // Set the variables to enable the public mint phase by owner.
    function setPublicMintPhase(bool hasPublicMintStarted, uint256 publicMintTimestamp) external;
        // Set the variables to enable the whitelist claim phase by owner.
    function setWLClaimPhase(bool hasWLClaimStarted, uint256 wlClaimTimestamp) external;
    // Set the variables to enable the public claim phase by owner.
    function setPublicClaimPhase(bool hasPublicClaimStarted, uint256 publicClaimTimestamp) external;

    // Set the price for minter to tokens.
    function setDictPrice(uint256 price) external;
    // Set the maximum supply of the dictionary by owner.
    function setMaxDictAmt(uint256 amount) external;
    // Set the address of word token to check previous dictionary addon supply.
    function setMintverseWordTokenAddress(address newTokenAddress) external;
    // Set the URI for the novel document.
    function setNovelDocumentURI(string calldata newNovelDocumentURI) external;
    // Set the URI for the legal document.
    function setLegalDocumentURI(string calldata newLegalDocumentURI) external;
    // Set the URI for the animation code document.
    function setAnimationCodeDocumentURI(string calldata newAnimationCodeDocumentURI) external;
    // Set the URI for the visual rebuild method document.
    function setVisualRebuildDocumentURI(string calldata newVisualRebuildDocumentURI) external;
    // Set the URI for the erc721 technical document.
    function setERC721ATechinalDocumentURI(string calldata newERC721ATechinalDocumentURI) external;
    // Set the URI for the metadata mapping document.
    function setMetadataMappingDocumentURI(string calldata newMetadataMappingDocumentURI) external;

    // Set the address to transfer the contract fund to.
    function setTreasury(address treasury) external;
    // Withdraw all the fund inside the contract to the treasury address.
    function withdrawAll() external payable;

    // This event is triggered whenever a call to #mintGiveawayWord, #mintWhitelistWord, and #mintPublicWord succeeds.
    event mintDictionaryEvent(address owner, uint256 quantity, uint256 totalSupply);
}