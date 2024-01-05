// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Strings.sol";

contract DCanvas is ERC721 {
    using Strings for uint256;

    // Base URI for metadata to be accessed at.
    string private BASE_URI = "https://dcanvas-metadata.s3-us-west-2.amazonaws.com/meta/";

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

    constructor() ERC721("dCanvas", "DCVT") {
        // Contract owner owns all tokens at the beginning.
        _balances[msg.sender] = TOKEN_SUPPLY;
    }

    /**
     * @dev Will update the base URL of token's URI
     * @param _newURI New base URL of token's URI
     */
    function setBaseURI(string memory _newURI) public onlyOwner {
        BASE_URI = _newURI;
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

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
        require(_exists(tokenId), "Token out of bounds");
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
     * If you want to remove your proxy, set the zero address.
     * @param _artistProxy the proxy address to set.
     */
    function setArtistProxy(address _artistProxy) public returns (address) {
        _setArtistProxy(_artistProxy);
        return _artistProxy;
    }

    /**
     * @dev In dCanvas all tokens are pre-minted to the contract owner.
     * However, OpenSea listens for Transfer events from address(0) to populate their UI.
     * We emit a transfer event so that OpenSea picks up on this and lists it on their platform.
     * Ideally we would check to make sure it's not only listed, however we skip this and trust
     * the contract owner in order to save gas.
     * It does check to make sure the contract owner is the owner of the token, so this cannot
     * be used to take or fake ownership of other people's tokens.
     * @param tokenId Token ID to list.
     */
    function _list(uint256 tokenId) internal {
        require(ownerOf(tokenId) == msg.sender, "Token not owned by lister");
        emit Transfer(address(0), msg.sender, tokenId);
    }

    /**
     * @dev In dCanvas all tokens are pre-minted to the contract owner.
     * However, OpenSea listens for Transfer events from address(0) to populate their UI.
     * We emit a transfer event so that OpenSea picks up on this and lists it on their platform.
     * @param startAt Token ID to start at.
     * @param endOn Token ID to end on (inclusive).
     */
    function _batchList(uint256 startAt, uint256 endOn) internal {
        require(startAt < endOn, "Invalid inputs: start point greater than end point");
        require((endOn - startAt) < 128, "Too many calls, may exceed gas limit");
        for (uint256 i = startAt; i < (endOn + 1); i++) {
            _list(i);
        }
    }

    /**
     * @dev In dCanvas all tokens are pre-minted to the contract owner.
     * However, OpenSea listens for Transfer events from address(0) to populate their UI.
     * We emit a transfer event so that OpenSea picks up on this and lists it on their platform.
     * Callable only by contract owner.
     * @param tokenId Token ID to list.
     */
    function list(uint256 tokenId) public onlyOwner {
        _list(tokenId);
    }

        /**
     * @dev In dCanvas all tokens are pre-minted to the contract owner.
     * However, OpenSea listens for Transfer events from address(0) to populate their UI.
     * We emit a transfer event so that OpenSea picks up on this and lists it on their platform.]
     * This allows us to batch into one transaction for convenience.
     * Callable only by contract owner.
     * @param startAt Token ID to start at.
     * @param endOn Token ID to end on (inclusive).
     */
    function batchList(uint256 startAt, uint256 endOn) public onlyOwner {
        _batchList(startAt, endOn);
    }

    /**
     * @dev Convenience method to batch transfer tokens.
     * Used for presales and initial allocations. Callable only by contract owner.
     * @param startAt Token ID to start at.
     * @param endOn Token ID to end on (inclusive).
     */
    function _batchTransfer(address to, uint256 startAt, uint256 endOn) internal {
        require(startAt < endOn, "Invalid inputs: start point greater than end point");
        require((endOn - startAt) < 128, "Too many calls, may exceed gas limit");
        for (uint256 i = startAt; i < (endOn + 1); i++) {
            safeTransferFrom(msg.sender, to, i);
        }
    }

    /**
     * @dev Convenience method to batch transfer tokens.
     * Used for presales and initial allocations. Callable only by contract owner.
     * @param startAt Token ID to start at.
     * @param endOn Token ID to end on (inclusive).
     */
    function batchTransfer(address to, uint256 startAt, uint256 endOn) public onlyOwner {
        _batchTransfer(to, startAt, endOn);
    }
}
