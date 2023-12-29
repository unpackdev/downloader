// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC721.sol";

/// @title A contract for minting unique art tokens with decentralized storage for metadata
/// @dev Extends ERC721 Non-Fungible Token Standard basic implementation with ReentrancyGuard and AccessControl
contract ComputerReacts is ERC721, ReentrancyGuard, AccessControl, Ownable {
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private _name = "Computer Reacts";
    string private _symbol = "COMP";
    mapping(uint256 => string) private _tokenURIs;

    /// @notice Contract constructor that sets the name, symbol, and minter role
    constructor() {
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Mints a new token to the specified address with the provided token ID and metadata URI
    /// @dev Requires the sender to have the minter role
    /// @param account The address of the future owner of the minted token
    /// @param newTokenId The token ID for the minted token
    /// @param newTokenURI The metadata URI for the minted token
    function mint(address account, uint256 newTokenId, string memory newTokenURI) public nonReentrant onlyRole(MINTER_ROLE) {
        _tokenURIs[newTokenId] = newTokenURI;
        _safeMint(account, newTokenId);
    }

    /// @notice Sets the metadata URI for the specified token ID
    /// @dev The caller must be the contract owner
    /// @param tokenId The token ID whose metadata URI is being set
    /// @param newTokenURI The new metadata URI for the token
    function setTokenURI(uint256 tokenId, string memory newTokenURI) external onlyOwner {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = newTokenURI;
    }

    /// @notice Withdraws the contract's entire Ether balance to an address
    /// @dev The caller must be the contract owner
    /// @param to The address to withdraw to
    function withdraw(address payable to) external onlyOwner {
        require(address(this).balance > 0, "No Ether left to withdraw");
        (bool sent, ) = to.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    /// @notice Gets the name of the token
    /// @return The name of the token
    function name() public view override returns (string memory) {
        return _name;
    }

    /// @notice Gets the symbol of the token
    /// @return The symbol of the token
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /// @notice Gets the metadata URI for a token ID
    /// @dev Throws if the token ID does not exist
    /// @param tokenId The token ID to query
    /// @return The metadata URI for the token ID
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    /// @dev See {IERC165-supportsInterface}.
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return True if the contract implements `interfaceId`, false otherwise
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}