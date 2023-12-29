// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./Ownable.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";
import "./ERC2981.sol";

/**
 * @title AdidasMoncler
 * @notice This contract governs the issue of 3,000 NFTs of The Explorer by Moncler and adidas Originals
 * @dev Batch mints ERC721 to provided addresses
 */
contract AdidasMoncler is ERC721ABurnable, ERC721AQueryable, ERC2981, Ownable {
    /// @dev Metadata base URI
    string public baseUri;
    /// @dev Max supply of token
    uint256 public constant MAX_SUPPLY = 3000;
    /// @dev Token name
    string private _name;
    /// @dev Token symbol
    string private _symbol;
    /// @dev contractURI
    string private _contractURI;

    constructor(
        string memory __name,
        string memory __symbol,
        string memory _baseUri,
        string memory _uri,
        address _royaltyReceiver,
        uint96 _royaltyValue
    ) ERC721A(__name, __symbol) {
        _name = __name;
        _symbol = __symbol;
        baseUri = _baseUri;
        _contractURI = _uri;
        _setDefaultRoyalty(_royaltyReceiver, _royaltyValue);
    }

    /**
     * @notice Returns the name of the ERC721 token.
     * @return The name of the token.
     */
    function name() public view virtual override(ERC721A, IERC721A) returns (string memory) {
        return _name;
    }

    /**
     * @notice Returns the symbol of the ERC721 token.
     * @return The symbol of the token.
     */
    function symbol() public view virtual override(ERC721A, IERC721A) returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Allows the owner to change the name and symbol of the ERC721 token.
     * @dev Only callable by the owner.
     * @param newName The new name for the token.
     * @param newSymbol The new symbol for the token.
     */
    function setNameAndSymbol(string calldata newName, string calldata newSymbol) public onlyOwner {
        _name = newName;
        _symbol = newSymbol;
    }

    /**
     * @notice Returns the base URI for the token's metadata.
     * @return The current base URI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    /**
     * @notice Changes the base URI for the token metadata.
     * @dev Only callable by the owner.
     * @param _baseUri The new base URI.
     */
    function setBaseUri(string calldata _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    /**
     * @notice Returns the contract's metadata URI.
     * @return The URI of the contract.
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @notice Changes the contract's URI.
     * @dev Only callable by the owner.
     * @param newContractURI The new contract URI.
     */
    function setContractUri(string calldata newContractURI) public onlyOwner {
        _contractURI = newContractURI;
    }

    /**
     * @notice Sets royalties for tarding.
     * @dev Only callable by the owner.
     * @param receiver The new royalty receiver.
     * @param value The new royalty amount.
     */
    function setRoyalties(address receiver, uint96 value) public onlyOwner {
        _setDefaultRoyalty(receiver, value);
    }

    /**
     * @notice Mints multiple ERC721 tokens.
     * @dev Only callable by the owner.
     * @param to An array of addresses to which to mint one token each.
     */
    function batchMint(address[] calldata to) external onlyOwner {
        uint256 count = to.length;
        require(totalSupply() + count <= MAX_SUPPLY, "Mint would exceed max supply");
        unchecked {
            for (uint256 i = 0; i < count; i++) {
                _mint(to[i], 1);
            }
        }
    }

    /**
     * @notice Checks if the contract supports a given interface.
     * @dev Overrides supportsInterface from multiple inherited contracts.
     * @param interfaceId The id of the interface to check.
     * @return bool True if the interface is supported, false otherwise.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}
