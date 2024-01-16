// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./AdminControlUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./StringsUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";

/**
 * @title Staking
 * @author Julien Bessaguet
 * @notice Streetlab Genesis staking contract
 */
contract Staking is
    Initializable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable,
    IERC721ReceiverUpgradeable,
    ERC165Upgradeable,
    ReentrancyGuardUpgradeable,
    AdminControlUpgradeable
{
    using StringsUpgradeable for uint256;

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of staking with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint32 extraData;
    }

    string public constant override name = "Streetlab Staking";
    string public constant override symbol = "SLS";

    /// @dev Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    /// @dev The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 64;

    /// @dev The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    /// @dev The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    /// @dev The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 224;

    /// @notice mapping from token ID to ownership details
    /// @dev Bits Layout:
    /// - [0..159]   `addr`
    /// - [160..223] `startTimestamp`
    /// - [224..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    /// @notice mapping owner address to address data
    /// @dev Bits Layout:
    /// - [0..63]    `balance`
    /// - [64..255]  `aux`
    mapping(address => uint256) private _packedAddressData;

    /// @notice base URI for metadata
    string public baseURI;

    /// @notice Genesis contract address
    address private immutable STREETLAB_GENESIS_ADDRESS;

    bool public isStakingOpened;

    // =============================================================
    //                         INITIALIZATION
    // =============================================================

    /**
     * @notice Configures immutable attribute.
     * @param streetlabGenesis Streetlab.io Genesis NFT contract address
     */
    constructor(address streetlabGenesis) {
        require(streetlabGenesis != address(0), "streetlab genesis required");
        STREETLAB_GENESIS_ADDRESS = streetlabGenesis;
    }

    function initialize() external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    // =============================================================
    //                            STAKING
    // =============================================================

    /// @dev See {IERC721Upgradeable-onERC721Received}.
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override nonReentrant returns (bytes4) {
        require(
            msg.sender == STREETLAB_GENESIS_ADDRESS,
            "can only stake streetlab genesis"
        );
        require(isStakingOpened, "staking closed");

        _packedOwnerships[tokenId] = _packOwnershipData(from, 0);
        _packedAddressData[from] += 1;

        emit Transfer(address(0), from, tokenId);

        return this.onERC721Received.selector;
    }

    /**
     * @notice start staking multiple tokens in one transaction.
     * this requires this contract to be an approved operator.
     * @param tokenIds genesis tokenIds to stake
     */
    function stake(uint256[] calldata tokenIds) external {
        require(isStakingOpened, "staking closed");
        address from = msg.sender;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            IERC721Upgradeable(STREETLAB_GENESIS_ADDRESS).transferFrom(
                from,
                address(this),
                tokenId
            );
            _packedOwnerships[tokenId] = _packOwnershipData(from, 0);
            emit Transfer(address(0), from, tokenId);
        }
        _packedAddressData[from] += tokenIds.length;
    }

    /**
     * @notice stop staking multiple tokens in one transaction.
     * @param tokenIds genesis tokenIds to unstake
     */
    function unstake(uint256[] calldata tokenIds) external nonReentrant {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 id = tokenIds[i];
            require(
                msg.sender == address(uint160(_packedOwnerships[id])),
                "Address is not owner"
            );

            _packedOwnerships[id] = 0;

            emit Transfer(msg.sender, address(0), id);

            // Return original chimp
            IERC721Upgradeable(STREETLAB_GENESIS_ADDRESS).transferFrom(
                address(this),
                msg.sender,
                id
            );
        }
        _packedAddressData[msg.sender] -= length;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /// @dev See {IERC721Upgradeable-balanceOf}.
    function balanceOf(address owner) external view override returns (uint256) {
        require(
            owner != address(0),
            "ERC721: address zero is not a valid owner"
        );
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /// @dev See {IERC165Upgradeable-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControlUpgradeable, ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /// @dev See {IERC721MetadataUpgradeable-tokenURI}.
    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        require(
            address(uint160(_packedOwnerships[tokenId])) != address(0),
            "ERC721: invalid token ID"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @notice Allow the owner to change the baseURI
     * @param newBaseURI the new uri
     */
    function setBaseURI(string calldata newBaseURI) external adminRequired {
        baseURI = newBaseURI;
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /// @dev See {IERC721Upgradeable-ownerOf}.
    function ownerOf(uint256 tokenId) external view override returns (address) {
        address owner = address(uint160(_packedOwnerships[tokenId]));
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct for a tokenId
     */
    function explicitOwnershipOf(uint256 tokenId) public view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[tokenId]);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     */
    function explicitOwnershipsOf(uint256[] calldata tokenIds)
        external
        view
        virtual
        returns (TokenOwnership[] memory)
    {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags)
        private
        view
        returns (uint256 result)
    {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(
                owner,
                or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags)
            )
        }
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed)
        private
        pure
        returns (TokenOwnership memory ownership)
    {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.extraData = uint32(packed >> _BITPOS_EXTRA_DATA);
    }

    /// @notice Allow toggling staking
    function toggleStakingOpened() external adminRequired {
        isStakingOpened = !isStakingOpened;
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /// @dev See {IERC721Upgradeable-approve}.
    function approve(address, uint256) external pure override {
        _transferRevert();
    }

    /**
     * @dev See {IERC721Upgradeable-getApproved}.
     */
    function getApproved(uint256) external pure override returns (address) {
        return address(0);
    }

    /// @dev See {IERC721Upgradeable-setApprovalForAll}.
    function setApprovalForAll(address, bool) external pure override {
        _transferRevert();
    }

    /// @dev See {IERC721Upgradeable-isApprovedForAll}.
    function isApprovedForAll(address, address)
        external
        pure
        override
        returns (bool)
    {
        return false;
    }

    /// @dev See {IERC721Upgradeable-transferFrom}.
    function transferFrom(
        address,
        address,
        uint256
    ) external pure override {
        _transferRevert();
    }

    /// @dev See {IERC721Upgradeable-safeTransferFrom}.
    function safeTransferFrom(
        address,
        address,
        uint256
    ) external pure override {
        _transferRevert();
    }

    /// @dev See {IERC721Upgradeable-safeTransferFrom}.
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override {
        _transferRevert();
    }

    function _transferRevert() private pure {
        revert("cannot transfer a non-transferable token");
    }

    // =============================================================
    //                     EMERGENCY OPERATIONS
    // =============================================================

    /**
     * @notice returns a lost ERC721 received through transferFrom
     * @dev admin required
     * @param to NFT recipient
     * @param tokenAddress NFT contract address
     * @param tokenId lost NFT token id
     */
    function withdrawERC721(
        address to,
        address tokenAddress,
        uint256 tokenId
    ) external adminRequired {
        if (tokenAddress == STREETLAB_GENESIS_ADDRESS) {
            require(
                address(uint160(_packedOwnerships[tokenId])) == address(0),
                "cannot withdraw staked genesis"
            );
            IERC721Upgradeable(STREETLAB_GENESIS_ADDRESS).transferFrom(
                address(this),
                to,
                tokenId
            );
        } else {
            IERC721Upgradeable(tokenAddress).transferFrom(
                address(this),
                to,
                tokenId
            );
        }
    }

    /**
     * @notice withdraw contract ERC20 balance and send it to owner
     * @dev admin required
     * @param to ERC20 recipient
     * @param token ERC20 contract address
     */
    function withdrawERC20(IERC20Upgradeable token, address to)
        external
        adminRequired
    {
        token.transfer(to, token.balanceOf(address(this)));
    }

    /**
     * @notice This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}
