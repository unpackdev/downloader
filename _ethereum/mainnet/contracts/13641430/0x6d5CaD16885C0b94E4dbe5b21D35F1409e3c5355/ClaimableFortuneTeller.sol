// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "./ERC1155Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Counters.sol";

// Libraries
import "./SafeCast.sol";
import "./EnumerableSet.sol";

/*****************************************************************************************************/
/**                                             WARNING                                             **/
/**                                  THIS CONTRACT IS UPGRADEABLE!                                  **/
/**  ---------------------------------------------------------------------------------------------  **/
/**  Do NOT change the order of or PREPEND any storage variables to this or new versions of this    **/
/**  contract as this will cause the the storage slots to be overwritten on the proxy contract!!    **/
/**                                                                                                 **/
/**  Visit https://docs.openzeppelin.com/upgrades/2.6/proxies#upgrading-via-the-proxy-pattern for   **/
/**  more information.                                                                              **/
/*****************************************************************************************************/
/**
 * @notice This is the logic for the Bonus Teller NFT.
 *
 * @author develop@teller.finance
 */
contract ClaimableFortuneTeller is ERC1155Upgradeable, AccessControlUpgradeable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    /* Constants */
    string public constant name = "Claimable Fortune Teller NFT";
    string public constant symbol = "CFTNFT";

    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant MINTER = keccak256("MINTER");

    /* State Variables */
    
    // It holds the URI hash for a claimable nft version //
    mapping(uint256 => string) private _idToUriHash;

    // It holds a set of tokenIds for an owner address
    mapping(address => EnumerableSet.UintSet) internal _ownedTokenIds;

    // It holds the total number of uris created
    Counters.Counter internal _idCounter;

    // Hash to the contract metadata
    string private _contractURIHash;

    /* Public Functions */

    /**
     * @notice checks if an interface is supported by ITellerNFT or AccessControlUpgradeable
     * @param interfaceId the identifier of the interface
     * @return bool stating whether or not our interface is supported
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(super.uri(tokenId), _idToUriHash[tokenId]));
    }

    /**
     * @notice The contract metadata URI.
     * @return the contract URI hash
     */
    function contractURI() external view returns (string memory) {
        // URI returned from parent just returns base URI
        return string(abi.encodePacked(super.uri(0), _contractURIHash));
    }

    /* External Functions */

    /**
     * @notice It returns an array of token IDs owned by an address.
     * @dev It uses a EnumerableSet to store values and loops over each element to add to the array.
     * @dev Can be costly if calling within a contract for address with many tokens.
     * @return owned_ the array of tokenIDs owned by the address
     */
    function getOwnedTokens(address owner)
        external
        view
        returns (uint256[] memory owned_)
    {
        EnumerableSet.UintSet storage set = _ownedTokenIds[owner];
        owned_ = new uint256[](set.length());
        for (uint256 i; i < owned_.length; i++) {
            owned_[i] = set.at(i);
        }
    }

    /**
     * @dev See {_setURI}.
     *
     * Requirements:
     *
     * - `newURI` must be prepended with a forward slash (/)
     */
    function create(string calldata uriHash) external onlyRole(ADMIN) {
        _idToUriHash[_idCounter.current()] = uriHash;
        _idCounter.increment();
    }

    /**
     * @notice It mints a new token for a Tier index.
     *
     * Requirements:
     *  - Caller must be an authorized minter
     */
    function mint(address account, uint256 tokenId, uint256 amount)
        external
        onlyRole(MINTER)
    {
        require(_exists(tokenId), "Token ID does not exist");

        _mint(account, tokenId, amount, "");
    }

    /**
     * @dev See {_setURI}.
     *
     * Requirements:
     *
     * - `newURI` must be prepended with a forward slash (/)
     */
    function setURI(string memory newURI) external onlyRole(ADMIN) {
        _setURI(newURI);
    }

    /**
     * @notice Sets the contract level metadata URI hash.
     * @param contractURIHash The hash to the initial contract level metadata.
     */
    function setContractURIHash(string memory contractURIHash)
        public
        onlyRole(ADMIN)
    {
        _contractURIHash = contractURIHash;
    }

    /**
     * @notice Initializes the Claimable Fortune Teller NFT.
     */
    function initialize(address _minter, string calldata contractURIHash) public virtual initializer {
        // Set the initial URI
        __ERC1155_init("https://gateway.pinata.cloud/ipfs/");
        __AccessControl_init();

        // Set admin role for admins
        _setRoleAdmin(ADMIN, ADMIN);
        // Set the initial admin
        _setupRole(ADMIN, _msgSender());
        _setupRole(MINTER, _minter);

        setContractURIHash(contractURIHash);
    }


    /* Internal Functions */

        /**
     * @dev Runs super function and then increases total supply.
     *
     * See {ERC1155Upgradeable._mint}.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {
        super._mint(account, id, amount, data);

        // add the id to the owned token ids of the user
        _addOwnedToken(account, id);
    }

    /**
     * @dev Runs super function and then increases total supply.
     *
     * See {ERC1155Upgradeable._mintBatch}.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._mintBatch(to, ids, amounts, data);

        for (uint256 i; i < amounts.length; i++) {
            _addOwnedToken(to, ids[i]);
        }
    }

    /**
     * @dev Runs super function and then decreases total supply.
     *
     * See {ERC1155Upgradeable._burn}.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal override {
        super._burn(account, id, amount);
        _removeOwnedTokenCheck(account, id);
    }

    /**
     * @dev Runs super function and then decreases total supply.
     *
     * See {ERC1155Upgradeable._burnBatch}.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal override {
        super._burnBatch(account, ids, amounts);

        for (uint256 i; i < amounts.length; i++) {
            _removeOwnedTokenCheck(account, ids[i]);
        }
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * See {ERC1155Upgradeable._safeTransferFrom}.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {
        super._safeTransferFrom(from, to, id, amount, data);
        _removeOwnedTokenCheck(from, id);
        _addOwnedToken(to, id);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *  See {ERC1155Upgradeable._safeBatchTransferFrom}
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._safeBatchTransferFrom(from, to, ids, amounts, data);
        for (uint256 i; i < ids.length; i++) {
            _removeOwnedTokenCheck(from, ids[i]);
            _addOwnedToken(to, ids[i]);
        }
    }

    /**
     * @dev Checks if a token ID exists. To exists the ID must have a URI hash associated.
     * @param tokenId ID of the token to check.
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return bytes(_idToUriHash[tokenId]).length > 0;
    }

    /**
     * @notice it removes a token ID from the ownedTokenIds mapping if the balance of
     * the user's tokenId is 0
     * @param account the address to add the token id to
     * @param id the token ID
     */
    function _removeOwnedTokenCheck(address account, uint256 id) private {
        if (balanceOf(account, id) == 0) {
            _ownedTokenIds[account].remove(id);
        }
    }

    /**
     * @notice it adds a token id to the ownedTokenIds mapping
     * @param account the address to the add the token ID to
     * @param id the token ID
     */
    function _addOwnedToken(address account, uint256 id) private {
        _ownedTokenIds[account].add(id);
    }

}
