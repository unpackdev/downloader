// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";

error FunctionLocked();
error NotAHistoricalToken();
error SenderNotTokenOwner();
error TokenNotRecoverable();
error TokenNotWrapped();

/**
 * @title Star Cards (Historical)
 * @author Eggy Bagelface (bagelface.eth)
 * @notice Wrapper contract for Star Cards https://etherscan.io/address/0xcddcc63883683a3e6d5537d0b47074c3accc790e
 *         Released in July 2018. The original metadata has been lost to time. This contract is designed to be
 *         a wrapper specifically for the historical tokens minted between July 19, 2018 and January 11, 2019.
 */
contract StarCardsHistorical is ERC721, Ownable {
    using Strings for uint256;

    IERC721 public immutable STAR_CARDS;

    uint256 public totalSupply;
    string public ipfsBaseURI;
    string public arweaveBaseURI;
    mapping(uint256 => bool) public useArweave;
    mapping(uint256 => bool) public isHistorical;
    mapping(bytes4 => bool) public functionLocked;

    constructor(
        IERC721 starCards,
        string memory _ipfsBaseURI,
        string memory _arweaveBaseURI
    )
        ERC721("Star Cards (Historical)", "STAR")
    {
        STAR_CARDS = starCards;
        ipfsBaseURI = _ipfsBaseURI;
        arweaveBaseURI = _arweaveBaseURI;
    }

    /**
     * @notice Allows function to be locked when it's not longer needed
     */
    modifier lockable() {
        if (functionLocked[msg.sig]) revert FunctionLocked();
        _;
    }

    /**
     * @notice Ensures functions can only be called for historical tokens
     */
    modifier onlyHistorical(uint256 tokenId) {
        if (!isHistorical[tokenId]) revert NotAHistoricalToken();
        _;
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * @dev Users can toggle between two metadata hosts using `toggleMetadataHost`
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        onlyHistorical(tokenId)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert TokenNotWrapped();

        return string(abi.encodePacked(
            useArweave[tokenId] ? arweaveBaseURI : ipfsBaseURI,
            tokenId.toString()
        ));
    }

    /**
     * @notice Toggle between Arweave and IPFS metadata hosting for a specified token
     * @param tokenId Token to toggle metadata hosts for
     */
    function toggleMetadataHost(uint256 tokenId) external {
        if (ownerOf(tokenId) != _msgSender()) revert SenderNotTokenOwner();

        useArweave[tokenId] = !useArweave[tokenId];
    }

    /**
     * @notice Set Arweave base URI for retrieving token metadata
     * @param _arweaveBaseURI Base Arweave URI to be prepended to token ID
     */
    function setArweaveBaseURI(string calldata _arweaveBaseURI) external lockable onlyOwner {
        arweaveBaseURI = _arweaveBaseURI;
    }

    /**
     * @notice Set IPFS base URI for retrieving token metadata
     * @param _ipfsBaseURI Base IPFS URI to be prepended to token ID
     */
    function setIPFSBaseURI(string calldata _ipfsBaseURI) external lockable onlyOwner {
        ipfsBaseURI = _ipfsBaseURI;
    }

    /**
     * @notice Wrap multiple tokens
     * @param tokenIds Tokens to wrap
     */
    function wrap(uint256[] calldata tokenIds) public {
        for (uint256 i; i < tokenIds.length;) {
            wrap(tokenIds[i]);
            unchecked { ++i; }
        }
    }

    /**
     * @notice Wrap a single token
     * @param tokenId Token to wrap
     */
    function wrap(uint256 tokenId) public onlyHistorical(tokenId) {
        STAR_CARDS.transferFrom(_msgSender(), address(this), tokenId);
        _mint(_msgSender(), tokenId);
    }

    /**
     * @notice Unwrap multiple tokens
     * @param tokenIds Tokens to unwrap
     */
    function unwrap(uint256[] calldata tokenIds) public {
        for (uint256 i; i < tokenIds.length;) {
            unwrap(tokenIds[i]);
            unchecked { ++i; }
        }
    }

    /**
     * @notice Unwrap a single token
     * @param tokenId Token to unwrap
     */
    function unwrap(uint256 tokenId) public onlyHistorical(tokenId) {
        if (ownerOf(tokenId) != _msgSender()) revert SenderNotTokenOwner();

        STAR_CARDS.transferFrom(address(this), _msgSender(), tokenId);
        _burn(tokenId);
    }

    /**
     * @notice Set tokens as historical tokens
     * @param tokenIds Tokens to set as historical
     */
    function setHistorical(uint256[] calldata tokenIds) external lockable onlyOwner {
        for (uint256 i; i < tokenIds.length;) {
            isHistorical[tokenIds[i]] = true;
            unchecked { ++i; }
        }
    }

    /**
     * @notice Lock a specific function when it's no longer needed
     * @param id First four bytes of the calldata (i.e. function identifier)
     */
    function lockFunction(bytes4 id) external onlyOwner {
        functionLocked[id] = true;
    }

    /**
     * @notice Recover any tokens transferred directly to the contract
     * @dev If a token isn't transferred to the contract using the wrapped function a
     * @dev corresponding token will not exist. Without this function, it would be stuck forever.
     * @param to Address to transfer recovered token to
     * @param tokenId Token to recover
     */
    function recover(address to, uint256 tokenId) external lockable onlyOwner {
        if (_exists(tokenId)) revert TokenNotRecoverable();

        STAR_CARDS.transferFrom(address(this), to, tokenId);
    }
}
