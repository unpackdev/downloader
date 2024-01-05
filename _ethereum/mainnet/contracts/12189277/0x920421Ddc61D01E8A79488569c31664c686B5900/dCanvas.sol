// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract DCanvas is ERC721, ReentrancyGuard, Ownable {
    using Strings for uint256;

    // Number of total tokens, equal to (Total Canvas Pixels) / (Pixels in Single Token).
    uint256 public constant TOKEN_SUPPLY = 65536;

    // Base URI for metadata to be accessed at.
    string public constant BASE_URI = "https://dcanvas-metadata.s3-us-west-2.amazonaws.com/meta/";

    // Suffix for file that contains the palette describing which rgb values correspond with each integer.
    string public constant PALETTE_METADATA_SUFFIX = "palette.json";

    // Colors of a given token block.
    mapping(uint256 => bytes32) public colors;

    // Artist proxy. Someone who can set colors on behalf of a given owner.
    mapping(address => address) public proxies;

    // Event emitted showing the address, tokenId, and colors of a color change.
    event ColorsChanged(
        address indexed _from,
        uint256 indexed _tokenId,
        bytes32 _color
    );

    // Event emitted when an artist proxy is set.
    event ProxySet(
        address indexed _owner,
        address indexed _proxy
    );

    constructor() ERC721("dCanvas", "DCVT") {}

    /**
     * @dev Returns colors of a single token
     * @param tokenId The token ID to return colors of
     */
    function getColors(uint256 tokenId) public view returns (bytes32 color) {
        require(tokenId < TOKEN_SUPPLY, "Invalid token id");
        color = colors[tokenId];
        return color;
    }

    /**
     * @dev Returns the currently set proxy address of a given owner
     * @param tokenOwner the address of the tokenowner to retrieve the proxy of
     */
    function getArtistProxy(address tokenOwner) public view returns (address proxy) {
        proxy = proxies[tokenOwner];
        return proxy;
    }

    /**
     * @dev Returns colors of tokens in a paginated fashion
     * @param cursor The token ID to start returning from
     * @param length The number of tokens to return colors for.
     */
    function getPaginatedColors(uint256 cursor, uint256 length)
        public
        view
        returns (bytes32[] memory)
    {
        require(cursor + length < TOKEN_SUPPLY);
        bytes32[] memory pageColors = new bytes32[](length);
        for (uint256 i = 0; i < length; i++) {
            pageColors[i] = colors[i + cursor];
        }

        return pageColors;
    }

    /**
     * @dev Sets the colors of a particular token 
     * @param tokenId the token ID to modify colors for
     * @param color A bytes32 object where the first 16 bytes represent colors of the 16 pixels, taken
     * from a 32 color palette.
     */
    function _setColors(uint256 tokenId, bytes32 color) private {
        require(tokenId < TOKEN_SUPPLY);
        colors[tokenId] = color;
        emit ColorsChanged(msg.sender, tokenId, color);
    }

    /**
     * @dev Sets the colors of a particular token 
     * @param tokenId the token ID to modify colors for
     * @param color A bytes32 object where the first 16 bytes represent colors of the 16 pixels, taken
     * from a 32 color palette.
     */
    function setColors(uint256 tokenId, bytes32 color)
        public
        returns (bytes32)
    {
        require(ownerOf(tokenId) == msg.sender || proxies[ownerOf(tokenId)] == msg.sender, "User does not own token");
        _setColors(tokenId, color);
        return color;
    }

    /**
     * @dev Sets another address that can set colors on behalf of the token owner.
     * @param _artistProxy the proxy address to set.
     */
    function _setArtistProxy(address _artistProxy) private {
        proxies[msg.sender] = _artistProxy;
        emit ProxySet(msg.sender, _artistProxy);
    }

    /**
     * @dev Sets another address that can set colors on behalf of the token owner.
     * @param _artistProxy the proxy address to set.
     */
    function setArtistProxy(address _artistProxy) public returns (address) {
        _setArtistProxy(_artistProxy);
        return _artistProxy;
    }

    /**
     * @dev Returns whether the option ID can be minted. Returns false if token ID is outside
     * the total token supply.
     * @param _tokenId the token ID to verify mintability for.
     */
    function _canMint(uint256 _tokenId) internal view returns (bool) {
        return _tokenId < TOKEN_SUPPLY && !_exists(_tokenId);
    }

    /**
     * @dev Returns whether the option ID can be minted. Returns false if token ID is outside
     * the total token supply.
     * @param _tokenId the token ID to verify mintability for.
     */
    function canMint(uint256 _tokenId) external view returns (bool) {
        return _canMint(_tokenId);
    }

    /**
     * @dev Mints asset(s) in accordance to a specific address with a particular token ID.
     * Callable only by the token owner. 
     * @param _optionId the token id to mint
     * @param _toAddress address of the future owner of the asset(s)
     */
    function mint(uint256 _optionId, address _toAddress)
        external
        nonReentrant()
        onlyOwner
    {
        require(_canMint(_optionId), "Invalid Token ID");
        _safeMint(_toAddress, _optionId);
    }

    /**
     * @dev Will update the base URL of token's URI
     * @param _newURI New base URL of token's URI
     */
    function setBaseURI(string memory _newURI) public onlyOwner {
        _setBaseURI(_newURI);
    }
}
