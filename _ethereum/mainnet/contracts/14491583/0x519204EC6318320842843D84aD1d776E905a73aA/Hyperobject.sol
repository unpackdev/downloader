/// Luxury rap, the Hermés of verses
/// Sophisticated ignorance, write my curses in cursive
/// I get it custom, you a customer
/// You ain't accustomed to going through customs, you ain't been nowhere, huh?

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "./Exchange.sol";
import "./ERC721.sol";

/// @title Cryptomedia
/// @author neuroswish
/// @notice NFT with an autonomous exchange

contract Hyperobject is ERC721 {

    // ======== Storage ========

    address public exchange; // Exchange token pair address
    address public immutable factory; // Pair factory address
    string public baseURI; // NFT base URI
    uint256 currentTokenId; // Counter keeping track of last minted token id

    // ======== Errors ========

	/// @notice Thrown when function caller is unauthorized
	error Unauthorized();

	/// @notice Thrown when transfer recipient is invalid
	error InvalidRecipient();

    /// @notice Thrown when token id is invalid
	error InvalidTokenId();

    // ======== Constructor ========

    /// @notice Set factory address
    /// @param _factory Factory address
    constructor(address _factory) ERC721("Verse", "VERSE") {
        factory = _factory;
     }

    // ======== Initializer ========

    /// @notice Initialize a new exchange
    /// @param _name Hyperobject name
    /// @param _symbol Hyperobject symbol
    /// @param _baseURI Token base URI
    /// @param _exchange Exchange address
    /// @dev Called by factory at time of deployment
    function initialize(
        string calldata _name,
        string calldata _symbol,
        string calldata _baseURI,
        address _exchange
    ) external {
        if (msg.sender != factory) revert Unauthorized();
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
        exchange = _exchange;
        currentTokenId++;
    }

    // ======== Functions ========

    /// @notice Mint NFT
    /// @param _recipient NFT recipient
    /// @dev Increments currentTokenId
    function mint(address _recipient) external {
        if (msg.sender != exchange) revert Unauthorized();
        if (_recipient == address(0)) revert InvalidRecipient();
        _mint(_recipient, currentTokenId++);
    }

    /// @notice Retrieve token URI for specified NFT
    /// @param _tokenId Token id
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (ownerOf[_tokenId] == address(0)) revert InvalidTokenId();
        return bytes(baseURI).length > 0 ? baseURI : "";
    }

}

