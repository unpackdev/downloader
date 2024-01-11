// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "./ERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./Counters.sol";
import "./AccessControl.sol";
import "./Strings.sol";

import "./EmissionBooster.sol";
import "./ErrorCodes.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title MinterestNFT
 * @dev Contract module which provides functionality to mint new ERC1155 tokens
 *      Each token connected with image and metadata. The image and metadata saved
 *      on IPFS and this contract stores the CID of the folder where lying metadata.
 *      Also each token belongs one of the Minterest tiers, and give some emission
 *      boost for Minterest distribution system.
 */
contract MinterestNFT is ERC1155, AccessControl {
    using Counters for Counters.Counter;
    using Strings for string;

    /// @dev ERC1155 id, Indicates a specific token or token type
    Counters.Counter private idCounter;

    /// Name for Minterst NFT Token
    string public constant name = "Minterest NFT";
    /// Symbol for Minterst NFT Token
    string public constant symbol = "MNFT";
    /// Address of opensea proxy registry, for opensea integration
    address public proxyRegistryAddress;

    /// @notice The right part is the keccak-256 hash of variable name
    bytes32 public constant GATEKEEPER = bytes32(0x20162831d2f54c3e11eebafebfeda495d4c52c67b1708251179ec91fb76dd3b2);

    EmissionBooster public emissionBooster;

    /// @notice Emitted when new EmissionBooster was installed
    event EmissionBoosterChanged(EmissionBooster emissionBooster);

    /// @notice Emitted when new base URI was installed
    event NewBaseUri(string newBaseUri);

    /**
     * @notice Initialize contract
     * @param _baseURI Base of URI where stores images
     * @param _admin The address of the Admin
     */
    constructor(
        string memory _baseURI,
        address _proxyRegistryAddress,
        address _admin
    ) ERC1155(_baseURI) {
        require(_proxyRegistryAddress != address(0), ErrorCodes.TARGET_ADDRESS_CANNOT_BE_ZERO);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(GATEKEEPER, _admin);
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /*** External user-defined functions ***/

    function supportsInterface(bytes4 interfaceId) public pure override(AccessControl, ERC1155) returns (bool) {
        return interfaceId == type(IERC1155).interfaceId;
    }

    /**
     * @notice Mint new 1155 standard token
     * @param account_ The address of the owner of minterestNFT
     * @param amount_ Instance count for minterestNFT
     * @param data_ The _data argument MAY be re-purposed for the new context.
     * @param tier_ tier
     */
    function mint(
        address account_,
        uint256 amount_,
        bytes memory data_,
        uint256 tier_
    ) external onlyRole(GATEKEEPER) {
        idCounter.increment();
        uint256 id = idCounter.current();

        _mint(account_, id, amount_, data_);

        if (tier_ > 0) {
            emissionBooster.onMintToken(
                account_,
                _asSingletonArray2(id),
                _asSingletonArray2(amount_),
                _asSingletonArray2(tier_)
            );
        }
    }

    /**
     * @notice Mint new ERC1155 standard tokens in one transaction
     * @param account_ The address of the owner of tokens
     * @param amounts_ Array of instance counts for tokens
     * @param data_ The _data argument MAY be re-purposed for the new context.
     * @param tiers_ Array of tiers
     */
    function mintBatch(
        address account_,
        uint256[] memory amounts_,
        bytes memory data_,
        uint256[] memory tiers_
    ) external onlyRole(GATEKEEPER) {
        require(tiers_.length == amounts_.length, ErrorCodes.INPUT_ARRAY_LENGTHS_ARE_NOT_EQUAL);

        uint256[] memory ids = new uint256[](amounts_.length);
        for (uint256 i = 0; i < amounts_.length; i++) {
            idCounter.increment();
            uint256 id = idCounter.current();

            ids[i] = id;
        }

        _mintBatch(account_, ids, amounts_, data_);

        emissionBooster.onMintToken(account_, ids, amounts_, tiers_);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     */
    // slither-disable-next-line reentrancy-benign
    function _beforeTokenTransfer(
        address,
        address from_,
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_,
        bytes memory
    ) internal virtual override {
        // Ignore mint transfers
        if (from_ != address(0)) emissionBooster.onTransferToken(from_, to_, ids_, amounts_);
    }

    /**
     * @notice Transfer token to another account
     * @param to_ The address of the token receiver
     * @param id_ token id
     * @param amount_ Count of tokens
     * @param data_ The _data argument MAY be re-purposed for the new context.
     */
    function safeTransfer(
        address to_,
        uint256 id_,
        uint256 amount_,
        bytes memory data_
    ) external {
        safeTransferFrom(msg.sender, to_, id_, amount_, data_);
    }

    /**
     * @notice Transfer tokens to another account
     * @param to_ The address of the tokens receiver
     * @param ids_ Array of token ids
     * @param amounts_ Array of tokens count
     * @param data_ The _data argument MAY be re-purposed for the new context.
     */
    function safeBatchTransfer(
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_,
        bytes memory data_
    ) external {
        safeBatchTransferFrom(msg.sender, to_, ids_, amounts_, data_);
    }

    /*** Admin Functions ***/

    /**
     * @notice Sets a new emissionBooster for the NFT.
     * @dev Admin function to set a new emissionBooster.
     */
    function setEmissionBooster(EmissionBooster emissionBooster_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(emissionBooster_) != address(0), ErrorCodes.ZERO_ADDRESS);
        emissionBooster = emissionBooster_;
        emit EmissionBoosterChanged(emissionBooster_);
    }

    /**
     * @notice Set new base URI
     * @param newBaseUri Base URI
     */
    function setURI(string memory newBaseUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newBaseUri);
        emit NewBaseUri(newBaseUri);
    }

    /*** Helper special functions ***/

    function _asSingletonArray2(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }

    /**
     * @notice Override function to return image URL, opensea requirement
     * @param tokenId_ Id of token to get URL
     * @return IPFS URI for token id, opensea requirement
     */
    function uri(uint256 tokenId_) public view override returns (string memory) {
        return
            _exists(tokenId_)
                ? string(abi.encodePacked(super.uri(tokenId_), Strings.toString(tokenId_), ".json"))
                : super.uri(tokenId_);
    }

    /**
     * @param _owner Owner of tokens
     * @param _operator Address to check if the `operator` is the operator for `owner` tokens
     * @return isOperator return true if `operator` is the operator for `owner` tokens otherwise true
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     */
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    /**
     * @dev Returns whether the specified token exists
     * @param _id uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 _id) internal view returns (bool) {
        return _id > 0 && _id <= idCounter.current();
    }
}
