// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./IERC20.sol";
import "./ERC2981Upgradeable.sol";
import "./StringsUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./OperatorFilterer.sol";
import "./ERC721BUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./LockRegistry.sol";
import "./IDelegationRegistry.sol";
import "./IValeria.sol";

/**
 * @title ValeriaUpgradeableV2
 * @custom:website https://valeriagames.com
 * @author @ValeriaStudios
 */
contract ValeriaUpgradeableV2 is
    Initializable,
    AccessControlUpgradeable,
    ERC2981Upgradeable,
    ERC721BUpgradeable,
    OperatorFilterer,
    LockRegistry,
    IValeria
{
    using StringsUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;

    // Roles
    bytes32 constant EXTERNAL_STAKE_ROLE = keccak256("EXTERNAL_STAKE_ROLE");
    bytes32 constant OWNER_ROLE = keccak256("OWNER_ROLE");

    /// @notice Base uri
    string public baseURI;

    /// @notice Maximum supply for the collection
    uint256 public constant MAX_SUPPLY = 10001;

    /// @notice Total supply
    uint256 private _totalMinted;

    /// @notice Operator filter toggle switch
    bool private operatorFilteringEnabled;

    /// @notice Delegation registry
    address public delegationRegistryAddress;

    modifier isDelegate(address vault) {
        bool isDelegateValid = IDelegationRegistry(delegationRegistryAddress)
            .checkDelegateForContract(_msgSender(), vault, address(this));
        require(isDelegateValid, "Invalid delegate-vault pairing");
        _;
    }

    /// @notice Additional token metadata
    struct Metadata {
        bool upgraded;
    }

    /// @notice A map from token id to custom metadata
    mapping(uint256 => Metadata) internal metadata;

    /// @notice A map from address to upgrades
    mapping(address => uint256) internal ownerLandUpgrades;

    /// @notice Total lands upgraded count
    uint256 public upgradedCount;

    /// @notice Determines if upgrading is live or not
    bool public isUpgradingLive;

    /// @notice Determines if restricted upgrading is in effect
    bool public isUpgradeRestricted;

    event LandsUpgraded(address indexed upgradedBy, uint256[] tokenIds);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _delegationRegistryAddress
    ) public virtual initializer {
        __ERC721B_init("Land of Valeria", "VOL");
        LockRegistry.__LockRegistry_init();
        __AccessControl_init();
        __ERC2981_init();
        // Setup access control
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
        _setupRole(EXTERNAL_STAKE_ROLE, _msgSender());
        // Setup filter registry
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        // Setup royalties to 6.5% (default denominator is 10000)
        _setDefaultRoyalty(_msgSender(), 650);
        // Setup contracts
        delegationRegistryAddress = _delegationRegistryAddress;
        // Set metadata
        baseURI = "ipfs://Qmc8QDbpwQ2QjbHEDJahS1kWN7Km8AhxjGReNLJ4gbxRMH/";
    }

    /**
     * @notice Migrate NFTs from a snapshot
     * @param tokenIds - The token ids
     * @param owners - The token owners
     */
    function migrateTokens(
        uint256[] calldata tokenIds,
        address[] calldata owners
    ) external onlyOwner {
        uint256 inputSize = tokenIds.length;
        uint256 newTotalMinted = _totalMinted + inputSize;
        require(owners.length == inputSize);
        require(newTotalMinted <= MAX_SUPPLY);
        uint256 tokenId;
        address owner;
        for (uint256 i; i < inputSize; ) {
            tokenId = tokenIds[i];
            owner = owners[i];
            // Mint new token token id to previous owner
            _mint(owner, tokenId);
            unchecked {
                i++;
            }
        }
        _totalMinted = newTotalMinted;
    }

    /**
     * @notice Total supply of the collection
     * @return uint256 The total supply
     */
    function totalSupply() external view returns (uint256) {
        return _totalMinted;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(
            ERC721BUpgradeable,
            ERC2981Upgradeable,
            AccessControlUpgradeable,
            IERC165Upgradeable
        )
        returns (bool)
    {
        return
            ERC721BUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(ERC721BUpgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        override(ERC721BUpgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        require(isUnlocked(tokenId), "!unlocked");
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721BUpgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        require(isUnlocked(tokenId), "!unlocked");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721BUpgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        require(isUnlocked(tokenId), "!unlocked");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        override(ERC721BUpgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        require(isUnlocked(tokenId), "!unlocked");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function lockId(uint256 _id) external onlyRole(EXTERNAL_STAKE_ROLE) {
        require(_exists(_id), "!exists");
        _lockId(_id);
    }

    function unlockId(uint256 _id) external onlyRole(EXTERNAL_STAKE_ROLE) {
        require(_exists(_id), "!exists");
        _unlockId(_id);
    }

    function freeId(
        uint256 _id,
        address _contract
    ) external onlyRole(EXTERNAL_STAKE_ROLE) {
        require(_exists(_id), "!exists");
        _freeId(_id, _contract);
    }

    /**
     * @notice Sets the delegation registry address
     * @param _delegationRegistryAddress The delegation registry address
     */
    function setDelegationRegistry(
        address _delegationRegistryAddress
    ) external onlyOwner {
        delegationRegistryAddress = _delegationRegistryAddress;
    }

    /**
     * @notice Token uri
     * @param tokenId The token id
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "!exists");
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    /**
     * @notice Sets the base uri for the token metadata
     * @param _baseURI The base uri
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice Set default royalty
     * @param receiver The royalty receiver address
     * @param feeNumerator A number for 10k basis
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @notice Sets whether the operator filter is enabled or disabled
     * @param operatorFilteringEnabled_ A boolean value for the operator filter
     */
    function setOperatorFilteringEnabled(
        bool operatorFilteringEnabled_
    ) public onlyOwner {
        operatorFilteringEnabled = operatorFilteringEnabled_;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    /**
     * @notice Return token ids owned by user
     * @param account Account to query
     * @return tokenIds
     */
    function tokensOfOwner(
        address account
    ) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsLength = balanceOf(account);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i; tokenIdsIdx != tokenIdsLength; ++i) {
                if (!_exists(i)) {
                    continue;
                }
                if (ownerOf(i) == account) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    /**
     * @dev Checks upgrade restrictions
     * @param owner The owner of the lands
     * @param upgradeAmount The amount of upgrades
     *
     * Upgrade restriction(s):
     *    1-5 Lands = 1 Upgrades
     *    6-10 Lands = 5 Upgrades
     *    11-24 Lands = 12 Upgrades
     *    25-49 Lands = 25 Upgrades
     *    50-99 Lands = 70 Upgrades
     *    100+ = 150 Upgrades
     *
     */
    function _checkUpgradeRestriction(
        address owner,
        uint256 upgradeAmount
    ) internal {
        uint256 ownedLands = balanceOf(owner);
        uint256 ownerUpgrades = ownerLandUpgrades[owner] + upgradeAmount;
        require(
            (ownedLands < 6 && ownerUpgrades < 2) ||
                (ownedLands < 11 && ownerUpgrades < 6) ||
                (ownedLands < 25 && ownerUpgrades < 13) ||
                (ownedLands < 50 && ownerUpgrades < 26) ||
                (ownedLands < 100 && ownerUpgrades < 71) ||
                (ownerUpgrades < 151),
            "!eligible"
        );
    }

    /**
     * @notice Upgrade land for a particular token id
     * @dev Handles metadata choice of land and element off-chain for dynamic image render
     * @param tokenIds The token ids of the lands
     * @param payment The VAL amount in wei
     * @param owner The owner of the land token ids
     */
    function _upgradeLands(
        uint256[] calldata tokenIds,
        uint256 payment,
        address owner
    ) internal {
        require(isUpgradingLive, "!live");

        // 2000 VAL fee, dropped into sink wallet for burn*, 2000 max upgradeable lands
        uint256 upgradeFee = 2000 ether;
        address tokenContract = 0x011E128Ec62840186F4A07E85E3ACe28858c5606;
        address sinkWallet = 0x1e818F09233942044a18b8D78EBcc36456b5d280;
        uint256 upgradeAmount = tokenIds.length;
        uint256 requiredPayment = upgradeAmount * upgradeFee;

        require(requiredPayment == payment, "!enough");
        require(upgradedCount + upgradeAmount < 2001, "!supply");

        // Check land balance restrictions
        if (isUpgradeRestricted) {
            _checkUpgradeRestriction(owner, upgradeAmount);
        }

        // Transfer tokens to sink wallet
        IERC20(tokenContract).transferFrom(
            _msgSender(),
            sinkWallet,
            requiredPayment
        );

        uint256 tokenId;
        uint256 i;

        // Store on-chain upgrade for stake lookup
        for (; i < upgradeAmount; ) {
            tokenId = tokenIds[i];
            require(
                ownerOf(tokenId) == owner && !metadata[tokenId].upgraded,
                "!owner || upgraded"
            );
            // Update the upgraded state for particular token id
            metadata[tokenId].upgraded = true;
        }

        // Update total upgraded count
        upgradedCount += upgradeAmount;

        emit LandsUpgraded(owner, tokenIds);
    }

    /// @notice Upgrade lands w/ VAL payment
    function upgradeLands(
        uint256[] calldata tokenIds,
        uint256 payment
    ) external payable {
        _upgradeLands(tokenIds, payment, _msgSender());
    }

    /// @notice Same as `upgradeLands` but for delegates
    function delegateUpgradeLands(
        uint256[] calldata tokenIds,
        uint256 payment,
        address vault
    ) external payable isDelegate(vault) {
        _upgradeLands(tokenIds, payment, vault);
    }

    /**
     * @notice Returns additional metadata for a given token id
     * @param tokenId The token Id of the land
     */
    function getMetadata(uint256 tokenId) external returns (Metadata memory) {
        return metadata[tokenId];
    }

    /**
     * @notice Returns batch of metadata
     * @param tokenIds The token ids to get metadata for
     */
    function getMetadataBatch(
        uint256[] calldata tokenIds
    ) external returns (Metadata[] memory) {
        Metadata[] memory batch = new Metadata[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            batch[i] = metadata[tokenIds[i]];
        }
        return batch;
    }

    /**
     * @notice Sets the live upgrade status
     * @param _isUpgradingLive The status of the upgrade
     * @param _isUpgradeRestricted The status of the restricted upgrade
     */
    function setUpgradingState(
        bool _isUpgradingLive,
        bool _isUpgradeRestricted
    ) external onlyOwner {
        isUpgradingLive = _isUpgradingLive;
        isUpgradeRestricted = _isUpgradeRestricted;
    }
}
