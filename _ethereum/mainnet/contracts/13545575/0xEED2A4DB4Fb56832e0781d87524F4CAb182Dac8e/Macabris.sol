// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Governed.sol";
import "./Bank.sol";

contract Macabris is ERC721, Governed {

    // Release contract address, used to whitelist calls to `onRelease` method
    address public releaseAddress;

    // Market contract address, used to whitelist calls to `onMarketSale` method
    address public marketAddress;

    // Bank contract
    Bank public bank;

    // Base URI of the token's metadata
    string public baseUri;

    // Personas sha256 hash (all UTF-8 names with a "\n" char after each name, sorted by token ID)
    bytes32 public immutable hash;

    /**
     * @param _hash Personas sha256 hash (all UTF-8 names with a "\n" char after each name, sorted by token ID)
     * @param governanceAddress Address of the Governance contract
     *
     * Requirements:
     * - Governance contract must be deployed at the given address
     */
    constructor(
        bytes32 _hash,
        address governanceAddress
    ) ERC721('Macabris', 'MCBR') Governed(governanceAddress) {
        hash = _hash;
    }

    /**
     * @dev Sets the release contract address
     * @param _releaseAddress Address of the Release contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     */
    function setReleaseAddress(address _releaseAddress) external canBootstrap(msg.sender) {
        releaseAddress = _releaseAddress;
    }

    /**
     * @dev Sets the market contract address
     * @param _marketAddress Address of the Market contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     */
    function setMarketAddress(address _marketAddress) external canBootstrap(msg.sender) {
        marketAddress = _marketAddress;
    }

    /**
     * @dev Sets Bank contract address
     * @param bankAddress Address of the Bank contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     * - Bank contract must be deployed at the given address
     */
    function setBankAddress(address bankAddress) external canBootstrap(msg.sender) {
        bank = Bank(bankAddress);
    }

    /**
     * @dev Sets metadata base URI
     * @param _baseUri Base URI, token's ID will be appended at the end
     */
    function setBaseUri(string memory _baseUri) external canConfigure(msg.sender) {
        baseUri = _baseUri;
    }

    /**
     * @dev Checks if the token exists
     * @param tokenId Token ID
     * @return True if token with given ID has been minted already, false otherwise
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev Overwrites to return base URI set by the contract owner
     */
    function _baseURI() override internal view returns (string memory) {
        return baseUri;
    }

    function _transfer(address from, address to, uint256 tokenId) override internal {
        super._transfer(from, to, tokenId);
        bank.onTokenTransfer(tokenId, from, to);
    }

    function _mint(address to, uint256 tokenId) override internal {
        super._mint(to, tokenId);
        bank.onTokenTransfer(tokenId, address(0), to);
    }

    /**
     * @dev Registers new token after it's sold and revealed in the Release contract
     * @param tokenId Token ID
     * @param buyer Buyer address
     *
     * Requirements:
     * - The caller must be the Release contract
     * - `tokenId` must not exist
     * - Buyer cannot be the zero address
     *
     * Emits a {Transfer} event.
     */
    function onRelease(uint256 tokenId, address buyer) external {
        require(msg.sender == releaseAddress, "Caller must be the Release contract");

        // Also checks that the token does not exist and that the buyer is not 0 address.
        // Using unsafe mint to prevent a situation where a sale could not be revealed in the
        // realease contract, because the buyer address does not implement IERC721Receiver.
        _mint(buyer, tokenId);
    }

    /**
     * @dev Transfers token ownership after a sale on the Market contract
     * @param tokenId Token ID
     * @param seller Seller address
     * @param buyer Buyer address
     *
     * Requirements:
     * - The caller must be the Market contract
     * - `tokenId` must exist
     * - `seller` must be the owner of the token
     * - `buyer` cannot be the zero address
     *
     * Emits a {Transfer} event.
     */
    function onMarketSale(uint256 tokenId, address seller, address buyer) external {
        require(msg.sender == marketAddress, "Caller must be the Market contract");

        // Also checks if the token exists, if the seller is the current owner and that the buyer is
        // not 0 address.
        // Using unsafe transfer to prevent a situation where the token owner can't accept the
        // highest bid, because the bidder address does not implement IERC721Receiver.
        _transfer(seller, buyer, tokenId);
    }
}
