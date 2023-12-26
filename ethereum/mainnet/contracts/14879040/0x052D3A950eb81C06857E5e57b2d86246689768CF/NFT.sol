// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/*
 * ██████╗ ██████╗ ███████╗██╗    ██╗██╗███████╗███████╗
 * ██╔══██╗██╔══██╗██╔════╝██║    ██║██║██╔════╝██╔════╝
 * ██████╔╝██████╔╝█████╗  ██║ █╗ ██║██║█████╗  ███████╗
 * ██╔══██╗██╔══██╗██╔══╝  ██║███╗██║██║██╔══╝  ╚════██║
 * ██████╔╝██║  ██║███████╗╚███╔███╔╝██║███████╗███████║
 * ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝╚══════╝╚══════╝
 */

// Imports
import "./Reveal.sol";
import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./Ownable.sol";

/**
 * @title The Brewies NFT smart contract.
 */
contract NFT is ERC721A, ERC721AQueryable, Ownable, Reveal {
    /// @notice The amount of available NFT tokens (including the reserved tokens).
    uint256 public maxSupply;
    /// @notice The amount of reserved NFT tokens.
    uint256 public numReservedTokens;
    /// @notice Indicates if the reserves have been minted.
    bool public areReservesMinted = false;
    /// @notice The mapping of addresses allowed to mint directly using the NFT contract.
    mapping (address => bool) public isMinter;

    /**
     * @param tokenName The name of the token.
     * @param tokenSymbol The symbol of the token.
     * @param unrevealedUri The URL of a media that is shown for unrevealed NFTs.
     * @param maxSupply_ The total amount of available NFT tokens (including the reserved tokens).
     * @param numReservedTokens_ The amount of reserved NFT tokens.
     * @dev The contract constructor
     */
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        string memory unrevealedUri,
        uint256 maxSupply_,
        uint256 numReservedTokens_
    ) ERC721A(tokenName, tokenSymbol) Reveal(unrevealedUri) {
        // Set the variables.
        maxSupply = maxSupply_;
        numReservedTokens = numReservedTokens_;
        isMinter[msg.sender] = true;
    }

    /**
      * @notice Grants the specified address the minter role.
      * @param minter The address to grant the minter role.
      */
    function setMinterRole(address minter, bool flag) external onlyOwner {
        isMinter[minter] = flag;
    }

    /**
      * @notice Mints the NFT tokens.
      * @param recipient The NFT tokens recipient.
      * @param quantity The number of NFT tokens to mint.
      */
    function mint(address recipient, uint256 quantity) external {
        require(isMinter[msg.sender], "NOT_AUTHORIZED");
        // Reserves should be minted before minting standard tokens.
        require(
            areReservesMinted == true,
            "RESERVED_TOKENS_NOT_MINTED"
        );
        // Check that the number of tokens to mint does not exceed the total amount.
        require(
            totalSupply() + quantity <= maxSupply,
            "MAX_SUPPLY_EXCEEDED"
        );
        // Mint the tokens.
        _safeMint(recipient, quantity);
    }

    /**
      * @notice Mints the reserved NFT tokens.
      * @param recipient The NFT tokens recipient.
      * @param quantity The number of NFT tokens to mint.
      */
    function mintReserves(address recipient, uint256 quantity) external onlyOwner{
        // Check if there are any reserved tokens available to mint.
        require(
            areReservesMinted == false,
            "RESERVED_TOKENS_ALREADY_MINTED"
        );
        // Check if the desired quantity of the reserved tokens to mint doesn't exceed the reserve.
        require(
            totalSupply() + quantity <= numReservedTokens,
            "RESERVED_SUPPLY_EXCEEDED"
        );
        uint256 numTokensToMint = quantity;
        if (quantity == 0) {
            // Set the number of tokens to mint to all available reserved tokens.
            numTokensToMint = numReservedTokens - totalSupply();
        }
        // Mint the tokens.
        _safeMint(recipient, numTokensToMint);
        // Set the flag only if we have minted the whole reserve.
        areReservesMinted = totalSupply() == numReservedTokens;
    }

    /**
      * @notice Returns a URI of an NFT.
      * @param tokenId The ID of the NFT.
      */
    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721Metadata) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return _getTokenUri(tokenId);
    }

    /**
     * @notice Returns the base URI.
     */
    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return getBaseUri();
    }

    /**
     * @notice Sets the start ID for tokens.
     * @return The start token ID.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}
