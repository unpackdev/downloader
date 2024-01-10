// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";

/**
 * @author The Midnite Team
 * @title Handles Midnite Wolf minting
 */
contract MidniteWolfPack is ERC721, Pausable, AccessControl, ERC721Burnable {
    using Counters for Counters.Counter;

    // Set up our user roles to be required against logic
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Keep a track of our token count
    Counters.Counter private _tokenIdCounter;

    // Set up events to be fired
    event WolfMinted(address to, uint tokenId);

    // Set our base mint price to 0.025eth in wei
    uint mintPrice = 25000000000000000;

    // Set our token supply limit
    uint TOTAL_SUPPLY = 5000;

    // Set our limit for per-tx tokens in public sale
    uint MAX_TOKENS_PER_TX = 10;

    // Set our base URI for metadata referencing
    string baseURI;

    /**
     * @dev Initialises our MidniteWolfPack contract.
     */
    constructor() ERC721("MidniteWolfPack", "WOLF") {
        // Set up our user roles against our message sender
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    /**
     * @dev Used in calculation of our token metadata URI
     * 
     * @return string Base URI of our token metadata
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Allows our PAUSER role to prevent minting process
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Allows our PAUSER role to reactivate minting process
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Allows an address to mint a token.
     * 
     * @param to Address of minter. Will be recipient of token.
     * @param amount Number of tokens requested to be minted.
     * 
     * Emits a {WolfMinted} event.
     */
    function safeMint(address to, uint amount) public payable {
        uint tokenId = _tokenIdCounter.current();

        // We only want 5000 tokens to be minted in total
        require(tokenId < TOTAL_SUPPLY, "Mint has ended.");

        // Validate the supply available for request
        require(amount <= MAX_TOKENS_PER_TX, "Too many tokens requested.");
        require((tokenId + amount) <= TOTAL_SUPPLY, "Too many tokens requested.");

        // Validate that our minting price is correct
        require(msg.value >= (mintPrice * amount), "Incorrect amount sent.");

        // Iterate through our requested amount to mint tokens
        for (uint i; i < amount;) {
            // Increment our counter to preserve tokenId
            _tokenIdCounter.increment();

            // Get our current token position and mint
            uint mintTokenId = _tokenIdCounter.current() - 1;
            _mint(to, mintTokenId);
            emit WolfMinted(to, mintTokenId);

            unchecked { ++i; }
        }
    }

    /**
     * @dev Allow admin to mint tokens to be held internally by the team.
     * 
     * @param to Address of minter. Will be recipient of token.
     * @param amount Number of tokens requested to be minted.
     * 
     * Emits a {WolfMinted} event.
     */
    function internalMint(address to, uint amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // Iterate through our requested amount to mint tokens
        for (uint i; i < amount;) {
            // Increment our counter to preserve tokenId
            _tokenIdCounter.increment();

            // Get our current token position and mint
            uint mintTokenId = _tokenIdCounter.current() - 1;
            _mint(to, mintTokenId);
            emit WolfMinted(to, mintTokenId);

            unchecked { ++i; }
        }
    }

    /**
     * @dev Allow admin to update the base URI allowing for reveal.
     * 
     * @param _newBaseURI New base URI to be updated to.
     */
    function setBaseURI(string memory _newBaseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _newBaseURI;
    }

    /**
     * @dev Allow admin to update the mint price.
     * 
     * @param _newMintPrice New mint price to be updated to.
     */
    function setMintPrice(uint _newMintPrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPrice = _newMintPrice;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning.
     * 
     * @param from Address token is being transferred from.
     * @param to Address token is being transferred to.
     * @param tokenId Unique ID of the token being transferred.
     */
    function _beforeTokenTransfer(address from, address to, uint tokenId)
        internal
        whenNotPaused
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Allows that the beneficiary can receive deposited ETH.
     *
     * @param _withdrawal WEI amount to be withdrawn.
     * 
     * @return bool Returns true if withdrawal was successful.
     */
    function withdraw(uint _withdrawal) external returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        (bool success, ) = msg.sender.call{value: _withdrawal}("");
        require(success, "Unable to process withdrawal.");
        return true;
    }

    /**
     * @dev Fallback function executed on a call if no other functions matches.
     */
    fallback() external payable {
        revert();
    }

    /**
     * @dev Fallback function executed on a payable call if no other functions matches.
     */
    receive() external payable {
        revert();
    }

    /**
     * @dev Calculates the number of tokens minted on contract.
     * 
     * @return uint The current number of tokens minted.
     */
    function totalMinted() public view returns (uint) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Exposes the total number of tokens available for supply.
     * 
     * @return uint The total token supply.
     */
    function totalSupply() public view returns (uint) {
        return TOTAL_SUPPLY;
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
