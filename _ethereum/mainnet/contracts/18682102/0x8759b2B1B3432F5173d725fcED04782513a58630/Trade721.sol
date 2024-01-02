// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// Author: Khashkhuu 'Xass1on' Gankhuyag
// Organization: Digital Exchange Mongolia LLC;
// Contact Info: support@trade.mn
import "./ERC721URIStorage.sol";
import "./ERC721Pausable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";

/**
 * @title Trade.mn ERC721 Pausable Token
 * @dev ERC721 Token that can paused (pause transaction).
 */

contract Trade721 is ERC721Pausable, ERC721URIStorage, Ownable {
    using Strings for string;
    using SafeMath for uint256;

    // Optional base URI
    string private _baseUri = "";

    /**
     * @dev Token transaction pause state mapping
     * Pauses token transaction by token id or owner address
     */
    mapping(uint256 => bool) private _tokenTransferPaused;
    mapping(address => bool) private _addressTransferPaused;
    uint256 private _totalSupply = 0;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) ERC721(name, symbol) {
        _baseUri = baseURI;
    }

    // ===============================================
    // Pause and Unpause token transfer
    // ===============================================
    /**
     * @dev Pause token transfer by token id
     */
    function pauseTokenTransfer(uint256 tokenId) external onlyOwner {
        _tokenTransferPaused[tokenId] = true;
    }

    /**
     * @dev Unpause token transfer by token id
     */
    function unpauseTokenTransfer(uint256 tokenId) external onlyOwner {
        _tokenTransferPaused[tokenId] = false;
    }

    /**
     * @dev Pause token transfer by from address
     */
    function pauseAddressTransfer(address from) external onlyOwner {
        _addressTransferPaused[from] = true;
    }

    /**
     * @dev Unpause token transfer by from address
     */
    function unpauseAddressTransfer(address from) external onlyOwner {
        _addressTransferPaused[from] = false;
    }

    /**
     * @dev Check if token id is paused
     */
    function getTokenTransferPauseState(
        uint256 tokenId
    ) external view returns (bool) {
        return _tokenTransferPaused[tokenId];
    }

    /**
     * @dev Check if address is paused
     */
    function getAddressTransferPauseState(
        address from
    ) external view returns (bool) {
        return _addressTransferPaused[from];
    }

    /**
     * @dev Pause all transaction
     */
    function pause() external onlyOwner {
        super._pause();
    }

    /**
     * @dev Unpause transaction
     */
    function unpause() external onlyOwner {
        super._unpause();
    }

    /**
     * @dev Check transaction pause state
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        require(
            !_tokenTransferPaused[tokenId],
            "token transfer is not permitted"
        );
        require(
            !_addressTransferPaused[from],
            "transfer from address is not permitted"
        );
    }

    // ===============================================
    // Mint
    // ===============================================
    function mint(
        address to,
        uint256 _tokenId,
        string memory _tokenURI
    ) external onlyOwner returns (uint256) {
        _safeMint(to, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
        unchecked {
            _totalSupply += 1;
        }
        return _tokenId;
    }

    // ===============================================
    // Token INFO
    // ===============================================
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    // ===============================================
    // Override
    // ===============================================
    function _burn(
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}
