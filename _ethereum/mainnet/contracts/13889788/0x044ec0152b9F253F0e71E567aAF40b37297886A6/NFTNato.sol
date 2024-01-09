// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ECDSA.sol";

contract NFTNato is ERC1155Supply, Ownable, Pausable {
    using ECDSA for bytes32;

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    uint256 public constant TOKEN_ID_CENTURION = 1;
    uint256 public constant TOKEN_PRICE_CENTURION = 0.45 ether;
    uint256 public constant TOKEN_ID_PLATINUM = 2;
    uint256 public constant TOKEN_PRICE_PLATINUM = 0.15 ether;
    uint256 public constant MAX_TOKENS_CENTURION = 500;
    uint256 public constant MAX_TOKENS_PLATINUM = 2000;
    uint256 public constant NUMBER_RESERVED_TOKENS = 100;

    uint public freeTokensMinted = 0;

    bool public saleIsActivePlatinum = true;
    bool public saleIsActivePlatinumFree = true;
    bool public saleIsActiveCenturion = true;

    // Used to validate authorized mint addresses
    address private freeSignerAddress = 0x1E2646181a24e2EeEF56Ad7fa29aAA260d35544C;

    // Used to ensure each new token id can only be minted once by the owner
    mapping (uint256 => bool) public collectionMinted;
    mapping (uint256 => string) public tokenURI;
    mapping (address => bool) public hasAddressMintedPlatinumFree;

    constructor(
        string memory uriBase,
        string memory uriPlatinum,
        string memory uriCenturion,
        string memory _name,
        string memory _symbol
    ) ERC1155(uriBase) {
        name = _name;
        symbol = _symbol;
        tokenURI[TOKEN_ID_PLATINUM] = uriPlatinum;
        tokenURI[TOKEN_ID_CENTURION] = uriCenturion;
    }

    /**
     * Returns the custom URI for each token id. Overrides the default ERC-1155 single URI.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        // If no URI exists for the specific id requested, fallback to the default ERC-1155 URI.
        if (bytes(tokenURI[tokenId]).length == 0) {
            return super.uri(tokenId);
        }
        return tokenURI[tokenId];
    }

    /**
     * Sets a URI for a specific token id.
     */
    function setURI(string memory newTokenURI, uint256 tokenId) public onlyOwner {
        tokenURI[tokenId] = newTokenURI;
    }

    /**
     * Set the global default ERC-1155 base URI to be used for any tokens without unique URIs
     */
    function setGlobalURI(string memory newTokenURI) public onlyOwner {
        _setURI(newTokenURI);
    }

    function setPlatinumSaleState(bool newState) public onlyOwner {
        require(saleIsActivePlatinum != newState, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        saleIsActivePlatinum = newState;
    }

    function setPlatinumFreeSaleState(bool newState) public onlyOwner {
        require(saleIsActivePlatinumFree != newState, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        saleIsActivePlatinumFree = newState;
    }

    function setCenturionSaleState(bool newState) public onlyOwner {
        require(saleIsActiveCenturion != newState, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        saleIsActiveCenturion = newState;
    }

    function setFreeSignerAddress(address _freeSignerAddress) external onlyOwner {
        require(_freeSignerAddress != address(0));
        freeSignerAddress = _freeSignerAddress;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function verifyAddressSigner(bytes32 messageHash, bytes memory signature) private view returns (bool) {
        return freeSignerAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    function hashMessage(address sender) private pure returns (bytes32) {
        return keccak256(abi.encode(sender));
    }

    /**
     * @notice Allow minting of any future tokens as desired as part of the same collection,
     * which can then be transferred to another contract for distribution purposes
     */
    function adminMint(address account, uint256 id, uint256 amount) public onlyOwner
    {
        require(!collectionMinted[id], "CANNOT_MINT_EXISTING_TOKEN_ID");
        require(id != TOKEN_ID_CENTURION && id != TOKEN_ID_PLATINUM, "CANNOT_MINT_EXISTING_TOKEN_ID");
        collectionMinted[id] = true;
        _mint(account, id, amount, "");
    }

    /**
     * @notice Allow minting of Platinum tokens by anyone while the sale is active max 3 per transaction
     */
    function mintPlatinum(uint256 numberOfTokens) external payable {
        require(saleIsActivePlatinum, "SALE_NOT_ACTIVE");
        require(!collectionMinted[TOKEN_ID_PLATINUM], "PLATINUM_TOKEN_LOCKED");
        require(TOKEN_PRICE_PLATINUM * numberOfTokens == msg.value, "PRICE_WAS_INCORRECT");
        require(totalSupply(TOKEN_ID_PLATINUM) + numberOfTokens <= MAX_TOKENS_PLATINUM - (NUMBER_RESERVED_TOKENS - freeTokensMinted), "WOULD_EXCEED_MAX_TOKEN_SUPPLY");
        require(numberOfTokens > 0, "MUST_MINT_AT_LEAST_ONE_TOKEN");
        require(numberOfTokens < 4, "CANT_MINT_MORE_THAN_THREE_TOKENS");
        
        _mint(msg.sender, TOKEN_ID_PLATINUM, numberOfTokens, "");

        if (totalSupply(TOKEN_ID_PLATINUM) >= MAX_TOKENS_PLATINUM) {
            saleIsActivePlatinum = false;
            saleIsActivePlatinumFree = false;
        }
    }

    /**
     * @notice Allow minting of Centurion tokens by anyone while the sale is active max 3 per transaction
     */
    function mintCenturion(uint256 numberOfTokens) external payable {
        require(saleIsActiveCenturion, "SALE_NOT_ACTIVE");
        require(!collectionMinted[TOKEN_ID_CENTURION], "CENTURION_TOKEN_LOCKED");
        require(TOKEN_PRICE_CENTURION * numberOfTokens == msg.value, "PRICE_WAS_INCORRECT");
        require(totalSupply(TOKEN_ID_CENTURION) + numberOfTokens <= MAX_TOKENS_CENTURION, "WOULD_EXCEED_MAX_TOKEN_SUPPLY");
        require(numberOfTokens > 0, "MUST_MINT_AT_LEAST_ONE_TOKEN");
        require(numberOfTokens < 4, "CANT_MINT_MORE_THAN_THREE_TOKENS");

        _mint(msg.sender, TOKEN_ID_CENTURION, numberOfTokens, "");

        if (totalSupply(TOKEN_ID_CENTURION) >= MAX_TOKENS_CENTURION) {
            saleIsActiveCenturion = false;
        }
    }

    /**
     * @notice Allow minting of a single Platinum token for free by whitelisted addresses only
     */
    function mintPlatinumFree(bytes32 messageHash, bytes calldata signature) external payable {
        require(saleIsActivePlatinumFree, "SALE_NOT_ACTIVE");
        require(!collectionMinted[TOKEN_ID_PLATINUM], "PLATINUM_TOKEN_LOCKED");
        require(freeTokensMinted + 1 <= NUMBER_RESERVED_TOKENS, "WOULD_EXCEED_MAX_TOKEN_SUPPLY");
        require(hasAddressMintedPlatinumFree[msg.sender] == false, "ADDRESS_HAS_ALREADY_MINTED_PLATINUM_FREE");
        require(hashMessage(msg.sender) == messageHash, "MESSAGE_INVALID");
        require(verifyAddressSigner(messageHash, signature), "SIGNATURE_VALIDATION_FAILED");
        
        hasAddressMintedPlatinumFree[msg.sender] = true;

        _mint(msg.sender, TOKEN_ID_PLATINUM, 1, "");

        freeTokensMinted = freeTokensMinted + 1;

        if (totalSupply(TOKEN_ID_PLATINUM) >= MAX_TOKENS_PLATINUM) {
            saleIsActivePlatinum = false;
            saleIsActivePlatinumFree = false;
        }
    }

    /**
     * @notice Allow owner to send `mintNumber` Platinum tokens without cost to multiple addresses
     */
    function giftPlatinum(address[] calldata receivers, uint256 numberOfTokens) external onlyOwner {
        require(!collectionMinted[TOKEN_ID_PLATINUM], "PLATINUM_TOKEN_LOCKED");
        require((totalSupply(TOKEN_ID_PLATINUM) + (receivers.length * numberOfTokens)) <= MAX_TOKENS_PLATINUM, "MINT_TOO_LARGE");
        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], TOKEN_ID_PLATINUM, numberOfTokens, "");
        }
        freeTokensMinted = freeTokensMinted + (receivers.length * numberOfTokens);
    }

    /**
     * @notice Allow owner to send `mintNumber` Centurion tokens without cost to multiple addresses
     */
    function giftCenturion(address[] calldata receivers, uint256 numberOfTokens) external onlyOwner {
        require(!collectionMinted[TOKEN_ID_CENTURION], "CENTURION_TOKEN_LOCKED");
        require((totalSupply(TOKEN_ID_CENTURION) + (receivers.length * numberOfTokens)) <= MAX_TOKENS_CENTURION, "MINT_TOO_LARGE");

        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], TOKEN_ID_CENTURION, numberOfTokens, "");
        }
    }

    /**
     * @notice Override ERC1155 such that zero amount token transfers are disallowed to prevent arbitrary creation of new tokens in the collection.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(amount > 0, "AMOUNT_CANNOT_BE_ZERO");
        return super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @notice When the contract is paused, all token transfers are prevented in case of emergency.
     */
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "BALANCE_IS_ZERO");
        payable(msg.sender).transfer(address(this).balance);
    }
}