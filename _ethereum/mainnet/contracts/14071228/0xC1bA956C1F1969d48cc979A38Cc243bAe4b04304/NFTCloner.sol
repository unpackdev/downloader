// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

// @title NFTCloner ERC721 contract
// @version 1.0
// @author luax.eth
// @url https://nftcloner.xyz/

import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./Strings.sol";

contract NFTCloner is IERC721Metadata {
    using Strings for uint256;

    // Contract owner, set as immutalble after initialisation
    address private immutable owner;

    // Token name
    string public name;

    // Token symbole
    string public symbol;

    // Token URI
    string private uri;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private owners;

    // Mapping owner address to token ID
    mapping(address => uint256) private ownedToken;

    // Total supply
    uint256 public totalSupply;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        uri = _uri;
    }

    /**
     * @notice Get the metadata URI for the token.
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        require(owners[_tokenId] != address(0));
        return string(abi.encodePacked(uri, "nft/", _tokenId.toString(), ".json"));
    }

    /**
     * @notice Get the metata URI for the contract.
     */
    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked(uri, "metadata.json"));
    }

    /**
     * @notice Mint a new token
     * @dev Store token ID to owner map and owner to token ID map,
     * and emit Transfer event.
     * Only one token per owner is allowed.
     */
    function mint() external {
        require(ownedToken[msg.sender] == 0);
        totalSupply++;
        uint256 tokenId = totalSupply;
        owners[tokenId] = msg.sender;
        ownedToken[msg.sender] = tokenId;
        emit Transfer(address(0), msg.sender, tokenId);
    }

    /**
     * @notice Burn an existing token
     * @dev Remove token ID to owner map and owner to token ID map,
     * and emit Transfer event.
     */
    function burn() external {
        uint256 tokenId = ownedToken[msg.sender];
        address tokenOwner = owners[tokenId];
        require(msg.sender == tokenOwner);
        ownedToken[msg.sender] = 0;
        owners[tokenId] = address(0);
        emit Transfer(tokenOwner, address(0), tokenId);
    }

    /**
     * @notice Update name, symbole and URI.
     * @dev Only the contract owner can update the contract metadata.
     */
    function updateInfo(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) external {
        require(msg.sender == owner);
        name = _name;
        symbol = _symbol;
        uri = _uri;
    }

    /**
     * @dev Returns true if this contract implements the interface defined by `_interfaceId`.
     */
    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        return _interfaceId == type(IERC721).interfaceId || _interfaceId == type(IERC721Metadata).interfaceId;
    }

    /**
     * @dev Returns the balance of `_owner` account.
     */
    function balanceOf(address _owner) external view returns (uint256) {
        require(ownedToken[_owner] > 0);
        return 1;
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     */
    function ownerOf(uint256 _tokenId) external view returns (address) {
        require(owners[_tokenId] != address(0));
        return owners[_tokenId];
    }

    /**
     * @dev Returns the token ID of `_owner` account.
     */
    function tokenByOwner(address _owner) external view returns (uint256) {
        require(ownedToken[_owner] != 0);
        return ownedToken[_owner];
    }

    // The following methods are just here to be ERC721 compliant,
    // but they are not used in this implementation,
    // this mean that it's not possible to transfer tokens.

    function approve(address, uint256) external pure {}

    function getApproved(uint256) external pure returns (address) {
        return address(0);
    }

    function isApprovedForAll(address, address) external pure returns (bool) {
        return false;
    }

    function setApprovalForAll(address, bool) external pure {}

    function safeTransferFrom(
        address,
        address,
        uint256
    ) external pure {}

    function transferFrom(
        address,
        address,
        uint256
    ) external pure {}

    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure {}
}
