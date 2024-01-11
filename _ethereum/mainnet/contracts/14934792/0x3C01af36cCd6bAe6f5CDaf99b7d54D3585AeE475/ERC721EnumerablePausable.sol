// SPDX-License-Identifier: MIT
// Cipher Mountain Contracts (last updated v0.0.1) (/Mintable.sol)

pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Pausable.sol";
import "./ERC2981.sol";
import "./IERC721Enumerable.sol";
import "./ERC165.sol";
import "./ERC721.sol";
import "./NativeMetaTransaction.sol";
import "./MinterPauserRole.sol";
import "./IStakeable.sol";

contract ERC721EnumerablePausable is ERC721, ERC2981, IStakeable, MinterPauserRole, Pausable, NativeMetaTransaction, IERC721Enumerable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Token staking is to prevent transfers of any single token in the case of staking
    mapping(uint256 => bool) private _stakedTokens;

    /**
     * @dev increments the counter on creation to start count at 1
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _tokenIds.increment();
        _setupOwnerRoles(_msgSender());
        _setBaseURI(baseTokenURI);
        _initializeEIP712(name);
    }

    /**
     * @dev Modifier to make a function callable only when the token is not staked.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotStaked(uint256 tokenId) {
        require(!isStaked(tokenId), "Stakeable: token must not be staked");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the token is staked.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenStaked(uint256 tokenId) {
        require(isStaked(tokenId), "Stakeable: token must be staked");
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721, ERC2981, MinterPauserRole) returns (bool) {
        return
            interfaceId == type(IERC721Enumerable).interfaceId || 
          super.supportsInterface(interfaceId);
    }

    function mint(address to, uint256 quantity) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "RoleControl: must have minter role to mint");
        require(!paused(), "Pausable: token transfer while paused");
      require(quantity > 0 && quantity < 21, "Mintable: quantity must be 1 - 20");

      uint256[20] memory _ids;
        for (uint256 i = 0; i < quantity; i++) {
            _ids[i] = _tokenIds.current();
          _tokenIds.increment();
        }

      _safeMint(to, _ids);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Mintable: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function isStaked(uint256 tokenId) public view virtual returns (bool) {
        return _stakedTokens[tokenId];
    }

    function stake(uint256 tokenId) public virtual whenNotStaked(tokenId) {
        require(hasRole(MINTER_ROLE, _msgSender()), "Mintable: must have minter role to stake");
      _stakedTokens[tokenId] = true;
        emit Stake(tokenId, false);
    }

    function unstake(uint256 tokenId) public virtual whenStaked(tokenId) {
        require(hasRole(MINTER_ROLE, _msgSender()), "Mintable: must have minter role to stake");
      _stakedTokens[tokenId] = false;
        emit Stake(tokenId, true);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Mintable: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Mintable: must have pauser role to unpause");
        _unpause();
    }

    /**
     * @dev Sets the base uri for all assets. This is here to reduce data
     * storage by assigning a variable to repetative data.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function setBaseURI(string memory newBaseURI) external onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Mintable: must have minter role to stake");
      _setBaseURI(newBaseURI);
    }

    /**
     * @dev Sets the token uri for all assets.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyAdmin() {
        require(hasRole(MINTER_ROLE, _msgSender()), "Mintable: must have minter role to stake");
      _setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyAdmin() {
      _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "Mintable: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override whenNotStaked(tokenId) {
        require(!paused(), "Pausable: token transfer while paused");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
        return _tokenOfOwnerByIndex(owner, index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
    return _supply();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < _supply(), "ERC721Enumerable: global index out of bounds");
        return index+1;
    }

    function _supply() internal view returns (uint256) {
    return _tokenIds.current()-1;
    }
}

