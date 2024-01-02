// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Author: Khashkhuu 'Xass1on' Gankhuyag
// Organization: Digital Exchange Mongolia LLC;
// Contact Info: support@trade.mn
import "./ERC1155URIStorage.sol";
import "./ERC1155Pausable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./Counters.sol";

/**
 * @title Trade.mn ERC1155 Pausable Token
 * @dev ERC1155 Token that can be paused (pause transaction).
 * Does not allow for minting additional tokens that already exists
 */
contract Trade1155 is ERC1155Pausable, ERC1155URIStorage, Ownable {
    using Strings for string;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    /**
     * @dev Token transaction pause state mapping
     * Pauses token transaction by token id or owner address
     */
    mapping(uint256 => bool) private _tokenTransferPaused;
    mapping(address => bool) private _addressTransferPaused;
    string private _name;
    string private _symbol;
    uint256 private _totalSupply = 0;

    /**
     * @dev total supply of tokens by token id
     */
    mapping(uint256 => uint256) private _totalSupplyById;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI
    ) ERC1155(baseURI) {
        _name = name_;
        _symbol = symbol_;
        _setBaseURI(baseURI);
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
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Pausable, ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                !_tokenTransferPaused[ids[i]],
                "token transfer is not permitted"
            );
        }
        require(
            !_addressTransferPaused[from],
            "transfer from address is not permitted"
        );
    }

    // ===============================================
    // Mint
    // ===============================================
    /**
     * @dev Modifier that checks if token exists by token id.
     * If exists do not mint.
     */
    modifier preMintCheck(uint256 id) {
        require(_totalSupplyById[id] <= 0, "token exists");
        _;
    }

    /**
     * @dev Modifier that checks if token exists by token id.
     * If exists do not mint.
     */
    modifier preBatchMintCheck(uint256[] memory ids) {
        for (uint256 i = 0; i < ids.length; i++) {
            require(_totalSupplyById[ids[i]] <= 0, "token exists");
        }
        _;
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        string memory tokenuri,
        bytes memory data
    ) public virtual onlyOwner preMintCheck(id) {
        _mint(to, id, amount, data);
        _setURI(id, tokenuri);
        _totalSupplyById[id] += amount;
        _totalSupply += amount;
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        string[] memory uris,
        bytes memory data
    ) public virtual onlyOwner preBatchMintCheck(ids) {
        _mintBatch(to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            _setURI(ids[i], uris[i]);
            _totalSupplyById[ids[i]] += amounts[i];
            _totalSupply += amounts[i];
        }
    }

    // ===============================================
    // Token INFO
    // ===============================================
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return uri(tokenId);
    }

    function uri(
        uint256 tokenId
    ) public view override(ERC1155, ERC1155URIStorage) returns (string memory) {
        return super.uri(tokenId);
    }

    function getTotalSupply(uint256 tokenId) public view returns (uint256) {
        return _totalSupplyById[tokenId];
    }

    function getTotalSupplies(
        uint256[] memory ids
    ) public view returns (uint256[] memory) {
        uint256[] memory totalSupplies = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            totalSupplies[i] = _totalSupplyById[ids[i]];
        }
        return totalSupplies;
    }
}
