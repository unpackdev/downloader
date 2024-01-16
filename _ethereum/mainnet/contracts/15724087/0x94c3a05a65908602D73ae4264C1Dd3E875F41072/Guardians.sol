// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./GuardianTimeMath.sol";
import "./IERC11554K.sol";
import "./IFeesManager.sol";
import "./IERC11554KController.sol";
import "./console.sol";

/**
 * @dev Guardians management contract.
 * Allows to set guardians parameters, fees, info
 * by guardians themselves and the protocol.
 */
contract Guardians is Initializable, OwnableUpgradeable {
    /// @dev Guadian Info struct.
    struct GuardianInfo {
        /// @notice Hashed physical address of a guardian.
        bytes32 addressHash;
        /// @notice Logo of a guardian.
        string logo;
        /// @notice Name of a guardian
        string name;
        /// @notice A guardian's redirect URI for future authentication flows.
        string redirect;
        /// @notice Guardian's policy.
        string policy;
        /// @notice Active status for a guardian
        bool isActive;
        /// @notice Private status for a guardian.
        bool isPrivate;
    }

    /// @dev Guardian class struct.
    struct GuardianClass {
        /// @notice Maximum insurance on-chain coverage.
        uint256 maximumCoverage;
        /// @notice Minting fee.
        uint256 mintingFee;
        /// @notice Redemption fee.
        uint256 redemptionFee;
        /// @notice Guardian fee rate per second.
        uint256 guardianFeeRate;
        /// @notice Guardian fee rate historic minimum.
        uint256 guardianFeeRateMinimum;
        /// @notice Last Guardian fee rate increase update timestamp.
        uint256 lastGuardianFeeRateIncrease;
        /// @notice Is guardian class active.
        bool isActive;
        /// @notice Guardian URI for metadata.
        string uri;
    }

    /// @notice Fee manager contract
    IFeesManager public feesManager;

    /// @notice Controller contract
    IERC11554KController public controller;

    /// @notice Percentage factor with 0.01% precision. For internal float calculations.
    uint256 public constant PERCENTAGE_FACTOR = 10000;

    /// @notice Minimum minting request fee.
    uint256 public minimumRequestFee;
    /// @notice Minimum time window for guardian fee rate increase.
    uint256 public guardianFeeSetWindow;
    /// @notice Maximum guardian fee rate percentage increase during single fee set, 0.01% precision.
    uint256 public maximumGuardianFeeSet;
    /// @notice Minimum storage time an item needs to have for transfers
    uint256 public minStorageTime;

    /// @notice Is an address a 4K whitelisted guardian.
    mapping(address => bool) public isWhitelisted;

    /// @notice Metadata info about a guardian
    mapping(address => GuardianInfo) public guardianInfo;

    /// @notice Guardians whitelisted users for services.
    mapping(address => mapping(address => bool)) public guardianWhitelist;
    /// @notice To whom (if) guardian delegated functions to execute
    mapping(address => address) public delegated;
    /// @notice  Guardian classes of a particular guardian.
    mapping(address => GuardianClass[]) public guardiansClasses;
    /// @notice How much items with id guardian keeps.
    /// guardian -> collection -> id -> amount
    mapping(address => mapping(IERC11554K => mapping(uint256 => uint256)))
        public stored;
    /// @notice At which guardian is each item stored
    /// collection address -> item id -> guardian address
    mapping(IERC11554K => mapping(uint256 => address)) public whereItemStored;

    /// @notice In which guardian class is the item? (within the context of the guardian where the item is stored)
    /// collection address -> item id -> guardian class index
    mapping(IERC11554K => mapping(uint256 => uint256)) public itemGuardianClass;

    /// @notice Mapping from a token holder address to a collection to an item id, to the date until storage has been paid.
    mapping(address => mapping(IERC11554K => mapping(uint256 => uint256)))
        public guardianFeePaidUntil;

    /// @notice Mapping from a collection, to item id, to the date until storage has been paid (globally, collectively for all users)
    /// @dev We need this for the movement of all items from one guardian to another.
    mapping(IERC11554K => mapping(uint256 => uint256))
        public globalItemGuardianFeePaidUntil;

    /// @notice user -> collection -> item id -> num items in repossession
    /// @notice Number of items in a collection that a user has in repossession.
    mapping(address => mapping(IERC11554K => mapping(uint256 => uint256)))
        public inRepossession;

    /// @dev Guardian has been added
    event GuardianAdded(address indexed guardian);
    /// @dev Guardian has been removed
    event GuardianRemoved(address indexed guardian);
    /// @dev Guardian class has been added
    event GuardianClassAdded(address indexed guardian, uint256 classID);
    /// @dev Guardian class has been modified
    event GuardianClassModified(address indexed guardian, uint256 classID);

    /// @dev Storage time has been purchased for an item
    event StorageTimeAdded(
        uint256 indexed id,
        address indexed guardian,
        uint256 timeAmount
    );
    /// @dev Item(s) have been set for repossession
    event SetForRepossession(
        uint256 indexed id,
        IERC11554K indexed collection,
        address indexed guardian,
        uint256 amount
    );
    /// @dev Guardian has been added - with metadata.
    event GuardianRegistered(
        address indexed guardian,
        string name,
        string logo,
        string policy,
        bool privacy,
        string redirect,
        bytes32 addressHash
    );

    /**
     * @dev Only whitelisted guardian modifier.
     */
    modifier onlyWhitelisted(address guardian) {
        require(isWhitelisted[guardian], "Not whitelisted");
        _;
    }

    /**
     * @dev Only controller modifier.
     */
    modifier onlyController() {
        require(_msgSender() == address(controller), "Not controller");
        _;
    }

    /**
     * @dev Only controller modifier.
     */
    modifier ifNotOwnerGuardianIsCaller(address guardian) {
        if (_msgSender() != owner()) {
            require(_msgSender() == guardian, "can only modify own data");
        }
        _;
    }

    /**
     * @notice Initialize Guardians contract.
     * @param minimumRequestFee_ the minimum mint request fee
     * @param guardianFeeSetWindow_ the window of time in seconds within a guardian is allowed to increase a guardian fee rate
     * @param maximumGuardianFeeSet_ the max percentage increase that a guardian can increase a guardian fee rate by. Numerator that generates percentage, over the PERCENTAGE_FACTOR
     * @param feesManager_ fees manager contract address
     * @param controller_ controller contract address
     */
    function initialize(
        uint256 minimumRequestFee_,
        uint256 guardianFeeSetWindow_,
        uint256 maximumGuardianFeeSet_,
        IFeesManager feesManager_,
        IERC11554KController controller_
    ) external initializer {
        __Ownable_init();
        minimumRequestFee = minimumRequestFee_;
        guardianFeeSetWindow = guardianFeeSetWindow_;
        maximumGuardianFeeSet = maximumGuardianFeeSet_;
        minStorageTime = 7776000; // default 90 days
        feesManager = feesManager_;
        controller = controller_;
    }

    /**
     * @notice Set controller.
     *
     * Requirements:
     *
     * 1) The caller must be a contract admin.
     * @param controller_ new address of controller contract
     */
    function setController(IERC11554KController controller_)
        external
        virtual
        onlyOwner
    {
        controller = controller_;
    }

    /**
     * @notice Set fees manager.
     *
     * Requirements:
     *
     * 1) The caller must be a contract admin.
     @param feesManager_ new address of fees manager contract
     */
    function setFeesManager(IFeesManager feesManager_)
        external
        virtual
        onlyOwner
    {
        feesManager = feesManager_;
    }

    /**
     * @notice Sets new min storage time.
     *
     * Requirements:
     *
     * 1) The caller must be a contract admin.
     * @param minStorageTime_ new minimum storage time that items require to have, in seconds.
     */
    function setMinStorageTime(uint256 minStorageTime_)
        external
        virtual
        onlyOwner
    {
        require(minStorageTime_ > 0, "storage time is 0");
        minStorageTime = minStorageTime_;
    }

    /**
     * @notice Sets minimum mining fee.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param minimumRequestFee_ new minumum mint request fee
     */
    function setMinimumRequestFee(uint256 minimumRequestFee_)
        external
        onlyOwner
    {
        minimumRequestFee = minimumRequestFee_;
    }

    /**
     * @notice Sets maximum Guardian fee rate set percentage.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param maximumGuardianFeeSet_ new max percentage increase that a guardian can increase a guardian fee rate by. Numerator that generates percentage, over the PERCENTAGE_FACTOR
     */
    function setMaximumGuardianFeeSet(uint256 maximumGuardianFeeSet_)
        external
        onlyOwner
    {
        maximumGuardianFeeSet = maximumGuardianFeeSet_;
    }

    /**
     * @notice Sets minimum Guardian fee.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param guardianFeeSetWindow_ new window of time in seconds within a guardian is allowed to increase a guardian fee rate
     */
    function setguardianFeeSetWindow(uint256 guardianFeeSetWindow_)
        external
        onlyOwner
    {
        guardianFeeSetWindow = guardianFeeSetWindow_;
    }

    /**
     * @notice Does a batch adding of storage for all the items passed
     * @param collections array of collections that contain the items for which guardian time will be purchased.
     * @param beneficiaries array of addresses that will be receiving the purchased guardian time.
     * @param ids array of item ids for which guardian time will be purchased.
     * @param guardianFeeAmounts array of guardian fee inputs for purchasing guardian time.
     */
    function batchAddStorageTime(
        IERC11554K[] calldata collections,
        address[] calldata beneficiaries,
        uint256[] calldata ids,
        uint256[] calldata guardianFeeAmounts
    ) external virtual {
        for (uint256 i = 0; i < ids.length; i++) {
            addStorageTime(
                collections[i],
                beneficiaries[i],
                ids[i],
                guardianFeeAmounts[i]
            );
        }
    }

    /**
     * @dev Externally called store item function by controller.
     * @param collection address of the collection that the item being stored belongs to.
     * @param mintAddress address of entity receiving the token(s).
     * @param id item id of the item being stored.
     * @param guardian address of guardian the item will be stored in.
     * @param guardianClassIndex index of the guardian class the item will be stored in.
     * @param guardianFeeAmount amount of fee that is being paid to purchase guardian time.
     * @param numItems number of items being stored
     * @param feePayer the address of the entity paying the guardian fee.
     */
    function controllerStoreItem(
        IERC11554K collection,
        address mintAddress,
        uint256 id,
        address guardian,
        uint256 guardianClassIndex,
        uint256 guardianFeeAmount,
        uint256 numItems,
        address feePayer
    ) external virtual onlyController {
        stored[guardian][collection][id] += numItems;
        whereItemStored[collection][id] = guardian;
        itemGuardianClass[collection][id] = guardianClassIndex;

        // Only needs to be done in non-free guardian classes
        if (
            guardiansClasses[guardian][guardianClassIndex].guardianFeeRate > 0
        ) {
            // Initialize paid until timelines on first ever mints
            if (guardianFeePaidUntil[mintAddress][collection][id] == 0) {
                guardianFeePaidUntil[mintAddress][collection][id] = block
                    .timestamp;
            }
            if (globalItemGuardianFeePaidUntil[collection][id] == 0) {
                globalItemGuardianFeePaidUntil[collection][id] = block
                    .timestamp;
            }

            uint256 addedStorageTime = GuardianTimeMath
                .calculateAddedGuardianTime(
                    guardianFeeAmount,
                    guardiansClasses[guardian][guardianClassIndex]
                        .guardianFeeRate,
                    numItems
                );

            guardianFeePaidUntil[mintAddress][collection][
                id
            ] += addedStorageTime;
            globalItemGuardianFeePaidUntil[collection][id] += addedStorageTime;

            feesManager.payGuardianFee(
                guardianFeeAmount,
                guardiansClasses[guardian][guardianClassIndex].guardianFeeRate *
                    numItems,
                guardian,
                guardianFeePaidUntil[mintAddress][collection][id],
                feePayer
            );
        }
    }

    /**
     * @dev Externally called take item out function by controller.
     * @param guardian address of guardian the item is being stored in.
     * @param collection address of the collection that the item being stored belongs to.
     * @param id item id of the item being stored.
     * @param numItems number of items that are being taken out of the guardian.
     * @param from address of the entity requesting the redemption of the item(s)
     */
    function controllerTakeItemOut(
        address guardian,
        IERC11554K collection,
        uint256 id,
        uint256 numItems,
        address from
    ) external virtual onlyController {
        require(
            inRepossession[from][collection][id] < numItems,
            "Too many reposession items"
        );
        uint256 guardianClassFeeRate = getGuardianFeeRate(
            guardian,
            itemGuardianClass[collection][id]
        );

        uint256 previousPaidUntil = guardianFeePaidUntil[from][collection][id];

        uint256 guardianFeeRefundAmount;
        if (guardianClassFeeRate > 0) {
            guardianFeeRefundAmount = _shiftGuardianFeesOnTokenRedeem(
                from,
                collection,
                id,
                numItems,
                guardianClassFeeRate
            );
        }

        stored[guardian][collection][id] -= numItems;
        if (stored[guardian][collection][id] == 0) {
            whereItemStored[collection][id] = address(0);
        }

        if (guardianClassFeeRate > 0) {
            feesManager.refundGuardianFee(
                guardianFeeRefundAmount,
                guardianClassFeeRate * numItems,
                guardian,
                previousPaidUntil,
                from
            );
        }
    }

    /**
     * @notice Moves items from inactive guardian to active guardian. Move ALL items,
     * in the case of semi-fungibles. Must pass a guardian classe for each item for the new guardian.
     *
     * Requirements:
     *
     * 1) the caller must be 4K.
     * 2) old guardian must be inactive
     * 3) new guardian must be active
     * 4) each class passed for each item for the new guardian must be active.
     * 5) must only be used to move ALL items and have movement of guardian fees after moving ALL items.
     * @param collection address of the collection that includes the items being moved
     * @param ids array of item ids being moved.
     * @param oldGuardian address of the guardian items are being moved from.
     * @param newGuardian address of the guardian items are being moved to.
     * @param newGuardianClassIndeces array of the newGuardian's guardian class indices the items will be moved to.
     */
    function moveItems(
        IERC11554K collection,
        uint256[] calldata ids,
        address oldGuardian,
        address newGuardian,
        uint256[] memory newGuardianClassIndeces
    ) external virtual onlyOwner {
        require(!isAvailable(oldGuardian), "Old guardian is available");
        require(isAvailable(newGuardian), "New guardian is not available");
        for (uint256 i = 0; i < ids.length; ++i) {
            require(
                isClassActive(newGuardian, newGuardianClassIndeces[i]),
                "Non active class"
            );
            _moveSingleItem(
                collection,
                ids[i],
                oldGuardian,
                newGuardian,
                newGuardianClassIndeces[i]
            );
        }
    }

    /**
     * @notice Copies all guardian classes from one guardian to another.
     * @dev if new guardian has no guardian classes before this, class indeces will be the same. If not, copies classes will have new indeces.
     *
     * @param oldGuardian address of the guardian whose classes will be moved.
     * @param newGuardian address of the guardian that will be receiving the classes.
     */
    function copyGuardianClasses(address oldGuardian, address newGuardian)
        external
        virtual
        onlyOwner
    {
        for (uint256 i = 0; i < guardiansClasses[oldGuardian].length; i++) {
            _copyGuardianClass(oldGuardian, newGuardian, i);
        }
    }

    /**
     * @notice Function for the guardian to set item(s) to be flagged for repossession.
     * @param collection that contains the item to be repossessed
     * @param itemId id of item(s) being reposessed
     * @param owner current owner of the item(s).
     */
    function setItemsToRepossessed(
        IERC11554K collection,
        uint256 itemId,
        address owner
    ) external {
        require(
            whereItemStored[collection][itemId] == _msgSender(),
            "Not guardian of items"
        );
        require(
            getGuardianFeeRateByCollectionItem(collection, itemId) > 0,
            "Items in a free storage class cannot be repossessed"
        );
        require(
            guardianFeePaidUntil[owner][collection][itemId] != 0 &&
                guardianFeePaidUntil[owner][collection][itemId] <
                block.timestamp,
            "Repossession = timepaiduntil is in the past"
        );

        uint256 currAmount = IERC11554K(collection).balanceOf(owner, itemId);
        require(currAmount > 0, "No items to repossess");

        uint256 prevInReposession = inRepossession[owner][collection][itemId];
        inRepossession[owner][collection][itemId] = currAmount;

        emit SetForRepossession(
            itemId,
            collection,
            _msgSender(),
            currAmount - prevInReposession
        );
    }

    /**
     * @notice Sets activity mode for the guardian. Either active or not.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian address of guardian whose activity mode will be set.
     * @param activity boolean for guardian activity mode.
     */
    function setActivity(address guardian, bool activity)
        external
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardianInfo[guardian].isActive = activity;
    }

    /**
     * @notice Sets privacy mode for the guardian. Either public false or private true.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian address of guardian whose privacy mode will be set.
     * @param privacy boolean for guardian privacy mode
     */
    function setPrivacy(address guardian, bool privacy)
        external
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardianInfo[guardian].isPrivate = privacy;
    }

    /**
     * @notice Sets logo for the guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian address of guardian whose logo will be set.
     * @param logo URI of logo for guardian
     */
    function setLogo(address guardian, string calldata logo)
        external
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardianInfo[guardian].logo = logo;
    }

    /**
     * @notice Sets name for the guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian address of guardian whose name will be set.
     * @param name name of guardian.
     */
    function setName(address guardian, string calldata name)
        external
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardianInfo[guardian].name = name;
    }

    /**
     * @notice Sets physical address hash for the guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian address of guardian whose physical address will be set.
     * @param physicalAddressHash bytes hash of physical address of the guardian
     */
    function setPhysicalAddressHash(
        address guardian,
        bytes32 physicalAddressHash
    ) external onlyWhitelisted(guardian) ifNotOwnerGuardianIsCaller(guardian) {
        guardianInfo[guardian].addressHash = physicalAddressHash;
    }

    /**
     * @notice Sets policy for the guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian address of guardian whose policy will be set.
     * @param policy guardian policy
     */
    function setPolicy(address guardian, string calldata policy)
        external
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardianInfo[guardian].policy = policy;
    }

    /**
     * @notice Sets redirects for the guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner
     * @param guardian address of guardian whose redirect URI will be set.
     * @param redirect redirect URI for guardian
     */
    function setRedirect(address guardian, string calldata redirect)
        external
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardianInfo[guardian].redirect = redirect;
    }

    /**
     * @notice Adds or removes users addresses to guardian whitelist.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner
     * @param guardian address of guardian whose users whitelist status will be modified
     * @param users array of user addresses whose whitelist status will be modified
     * @param whitelistStatus boolean for the whitelisted status of the users
     */
    function changeWhitelistUsersStatus(
        address guardian,
        address[] calldata users,
        bool whitelistStatus
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        for (uint256 i = 0; i < users.length; ++i) {
            guardianWhitelist[guardian][users[i]] = whitelistStatus;
        }
    }

    /**
     * @notice Removes guardian from the whitelist.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param guardian address of guardian who will be removed.
     */
    function removeGuardian(address guardian) external virtual onlyOwner {
        isWhitelisted[guardian] = false;
        emit GuardianRemoved(guardian);
    }

    /**
     * @notice Sets minting fee for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) the caller must be a whitelisted guardian or the owner
     * @param guardian address of the guardian whose guardian class minting fee will be modified.
     * @param classID guardian's guardian class index whose minting fee will be modified.
     * @param mintingFee new minting fee
     */
    function setGuardianClassMintingFee(
        address guardian,
        uint256 classID,
        uint256 mintingFee
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        require(mintingFee >= minimumRequestFee, "Lower than mininum");
        guardiansClasses[guardian][classID].mintingFee = mintingFee;
        emit GuardianClassModified(guardian, classID);
    }

    /**
     * @notice Sets redemption fee for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) the caller must be a whitelisted guardian or the owner
     * @param guardian address of the guardian whose guardian class redemption fee will be modified.
     * @param classID guardian's guardian class index whose redemption fee will be modified.
     * @param redemptionFee new redemption fee
     */
    function setGuardianClassRedemptionFee(
        address guardian,
        uint256 classID,
        uint256 redemptionFee
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardiansClasses[guardian][classID].redemptionFee = redemptionFee;
        emit GuardianClassModified(guardian, classID);
    }

    /**
     * @notice Sets Guardian fee rate for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) the caller must be a whitelisted guardian or the owner
     * @param guardian address of the guardian whose guardian class guardian fee rate will be modified.
     * @param classID guardian's guardian class index whose guardian fee rate  will be modified.
     * @param guardianFeeRate new guardian fee rate
     */
    function setGuardianClassGuardianFeeRate(
        address guardian,
        uint256 classID,
        uint256 guardianFeeRate
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        require(guardianFeeRate > 0, "guardian class guardian fee rate is 0");
        require(
            guardiansClasses[guardian][classID].guardianFeeRate > 0,
            "Cannot increase guardian fee rate on free classes"
        );
        if (
            guardianFeeRate >
            guardiansClasses[guardian][classID].guardianFeeRate
        ) {
            require(
                block.timestamp >=
                    guardiansClasses[guardian][classID]
                        .lastGuardianFeeRateIncrease +
                        guardianFeeSetWindow,
                "Guardian fee window hasn't passed"
            );
            require(
                guardianFeeRate <=
                    (guardiansClasses[guardian][classID].guardianFeeRate *
                        maximumGuardianFeeSet) /
                        PERCENTAGE_FACTOR,
                "Exceeds increase limit"
            );
            guardiansClasses[guardian][classID]
                .lastGuardianFeeRateIncrease = block.timestamp;
        }
        guardiansClasses[guardian][classID].guardianFeeRate = guardianFeeRate;
        if (
            guardianFeeRate <
            guardiansClasses[guardian][classID].guardianFeeRateMinimum
        ) {
            guardiansClasses[guardian][classID]
                .guardianFeeRateMinimum = guardianFeeRate;
        }
    }

    /**
     * @notice Sets URI for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) the caller must be a whitelisted guardian or owner
     * @param guardian address of the guardian whose guardian class URI will be modified.
     * @param classID guardian's guardian class index whose class URI will be modified.
     * @param uri new URI
     */
    function setGuardianClassURI(
        address guardian,
        uint256 classID,
        string calldata uri
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardiansClasses[guardian][classID].uri = uri;
        emit GuardianClassModified(guardian, classID);
    }

    /**
     * @notice Sets guardian class as active or not active by guardian or owner
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or owner
     * @param guardian address of the guardian whose guardian class active status will be modified.
     * @param classID guardian's guardian class index whose guardian class active status will be modified.
     * @param activeStatus new guardian class active status
     */
    function setGuardianClassActiveStatus(
        address guardian,
        uint256 classID,
        bool activeStatus
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardiansClasses[guardian][classID].isActive = activeStatus;
        emit GuardianClassModified(guardian, classID);
    }

    /**
     * @notice Sets maximum insurance coverage for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian.
     * @param guardian address of the guardian whose guardian class maximum coverage will be modified.
     * @param classID guardian's guardian class index whose guardian class maximum coverage will be modified.
     * @param maximumCoverage new guardian class maximum coverage
     */
    function setGuardianClassMaximumCoverage(
        address guardian,
        uint256 classID,
        uint256 maximumCoverage
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardiansClasses[guardian][classID].maximumCoverage = maximumCoverage;
        emit GuardianClassModified(guardian, classID);
    }

    /**
     * @dev Externally called store item function by controller to update Guardian fees on token transfer.
     * @param from address of entity sending token(s)
     * @param to address of entity receiving token(s)
     * @param id token id of token(s) being sent.
     * @param amount amount of tokens being sent.
     */
    function shiftGuardianFeesOnTokenMove(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external virtual {
        require(
            controller.isActiveCollection(_msgSender()) &&
                controller.isLinkedCollection(_msgSender()),
            "Not active 4k collection"
        );
        IERC11554K collection = IERC11554K(_msgSender());

        uint256 guardianClassFeeRate = getGuardianFeeRateByCollectionItem(
            collection,
            id
        );
        require(
            guardianClassFeeRate > 0,
            "guardian class guardian fee rate is 0"
        );

        uint256 guardianFeeShiftAmount = GuardianTimeMath
            .calculateRemainingFeeAmount(
                guardianFeePaidUntil[from][collection][id],
                guardianClassFeeRate,
                amount
            );

        uint256 remainingFeeAmountFrom = GuardianTimeMath
            .calculateRemainingFeeAmount(
                guardianFeePaidUntil[from][collection][id],
                guardianClassFeeRate,
                collection.balanceOf(from, id)
            );

        uint256 remainingFeeAmountTo = GuardianTimeMath
            .calculateRemainingFeeAmount(
                guardianFeePaidUntil[to][collection][id],
                guardianClassFeeRate,
                collection.balanceOf(to, id)
            );

        // Recalculate the remaining time with new params for FROM
        uint256 newAmountFrom = collection.balanceOf(from, id) - amount;
        if (newAmountFrom == 0) {
            guardianFeePaidUntil[from][collection][id] = 0; //default
        } else {
            guardianFeePaidUntil[from][collection][id] =
                block.timestamp +
                GuardianTimeMath.calculateAddedGuardianTime(
                    remainingFeeAmountFrom - guardianFeeShiftAmount,
                    guardianClassFeeRate,
                    newAmountFrom
                );
        }

        // Recalculate the remaining time with new params for TO
        uint256 newAmountTo = collection.balanceOf(to, id) + amount;
        guardianFeePaidUntil[to][collection][id] =
            block.timestamp +
            GuardianTimeMath.calculateAddedGuardianTime(
                remainingFeeAmountTo + guardianFeeShiftAmount,
                guardianClassFeeRate,
                newAmountTo
            );
    }

    /**
     * @notice Delegates whole minting/redemption process to.
     * @param to address to which the calling guardian will delegate to.
     */
    function delegate(address to)
        external
        virtual
        onlyWhitelisted(_msgSender())
    {
        delegated[_msgSender()] = to;
    }

    /**
     * @notice Adds guardian class to guardian by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner
     * @param guardian address of guardian who is adding a new class
     * @param maximumCoverage max coverage of new guardian class
     * @param mintingFee minting fee of new guardian class
     * @param redemptionFee redemption fee of new guardian class
     * @param  guardianFeeRate guardian fee rate of new guardian class
     */
    function addGuardianClass(
        address guardian,
        uint256 maximumCoverage,
        uint256 mintingFee,
        uint256 redemptionFee,
        uint256 guardianFeeRate
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
        returns (uint256 classID)
    {
        classID = _addGuardianClass(
            guardian,
            maximumCoverage,
            mintingFee,
            redemptionFee,
            guardianFeeRate
        );
    }

    /**
     * @notice Returns guardian class maximum coverage.
     * @param guardian address of guardian getting queried
     * @param classID guardian's guardian class index being queried
     * @return maxCoverage max coverage for guardian's guardian class
     */
    function getMaximumCoverage(address guardian, uint256 classID)
        external
        view
        virtual
        returns (uint256)
    {
        return guardiansClasses[guardian][classID].maximumCoverage;
    }

    /**
     * @notice Returns guardian class URI.
     * @param guardian address of guardian getting queried
     * @param classID guardian's guardian class index being queried
     * @return URI URI for guardian's guardian class
     */
    function getURI(address guardian, uint256 classID)
        external
        view
        virtual
        returns (string memory)
    {
        return guardiansClasses[guardian][classID].uri;
    }

    /**
     * @notice queries if the amount of guardian fee provided purchases the minimum guardian time for a particular guardian class.
     * @param guardianFeeAmount the amount of guardian fee being queried.
     * @param numItems number of total items the guardian would be storing.
     * @param guardian address of the guardian that would be doing the storing.
     * @param guardianClassIndex index of guardian class that would be doing the storing.
     */
    function isFeeAboveMinimum(
        uint256 guardianFeeAmount,
        uint256 numItems,
        address guardian,
        uint256 guardianClassIndex
    ) external view virtual returns (bool) {
        uint256 guardianClassFeeRate = getGuardianFeeRate(
            guardian,
            guardianClassIndex
        );
        require(
            guardianClassFeeRate > 0,
            "guardian class guardian fee rate is 0"
        );
        return
            minStorageTime <=
            GuardianTimeMath.calculateAddedGuardianTime(
                guardianFeeAmount,
                guardianClassFeeRate,
                numItems
            );
    }

    /**
     * @notice Returns guardian class redemption fee.
     * @param guardian address of guardian whose guardian class is being queried.
     * @param classID guardian's guardian class index being queried
     * @return guardian class's redemption fee
     */
    function getRedemptionFee(address guardian, uint256 classID)
        external
        view
        virtual
        returns (uint256)
    {
        return guardiansClasses[guardian][classID].redemptionFee;
    }

    /**
     * @notice Returns guardian class minting fee.
     * @param guardian address of guardian whose guardian class is being queried.
     * @param classID guardian's guardian class index being queried
     * @return mintingFee guardian class's minting fee
     */
    function getMintingFee(address guardian, uint256 classID)
        external
        view
        virtual
        returns (uint256)
    {
        return guardiansClasses[guardian][classID].mintingFee;
    }

    /**
     * @notice Returns guardian class last Guardian fee rate update timestamp.
     * @param guardian address of guardian whose guardian class is being queried.
     * @param classID guardian's guardian class index being queried
     * @return lastGuardianFeeRateIncrease timestamp of the last time the guardian class' fee rate was increased.
     */
    function getLastGuardianFeeRateIncrease(address guardian, uint256 classID)
        external
        view
        virtual
        returns (uint256)
    {
        return guardiansClasses[guardian][classID].lastGuardianFeeRateIncrease;
    }

    /**
     * @notice Returns guardian classes number.
     * @param guardian address of guardian whose guardian classes are being queried.
     * @return count how many guardian classes the guardian has
     */
    function guardianClassesCount(address guardian)
        external
        view
        virtual
        returns (uint256)
    {
        return guardiansClasses[guardian].length;
    }

    /**
     * @notice Registers guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param guardian address of the new guardian
     * @param name name of new guardian.
     * @param logo URI of new guardian logo
     * @param policy policy of new guardian
     * @param redirect redirect URI of new guardian
     * @param physicalAddressHash physical address hash of new guardian.
     @ @param privacy boolean - is the new guardian private or not
     */
    function registerGuardian(
        address guardian,
        string memory name,
        string memory logo,
        string memory policy,
        string memory redirect,
        bytes32 physicalAddressHash,
        bool privacy
    ) public virtual onlyOwner {
        guardianInfo[guardian].isActive = true;
        guardianInfo[guardian].name = name;
        guardianInfo[guardian].logo = logo;
        guardianInfo[guardian].policy = policy;
        guardianInfo[guardian].isPrivate = privacy;
        guardianInfo[guardian].redirect = redirect;
        guardianInfo[guardian].addressHash = physicalAddressHash;
        addGuardian(guardian);
        emit GuardianRegistered(
            guardian,
            name,
            logo,
            policy,
            privacy,
            redirect,
            physicalAddressHash
        );
    }

    /**
     * @notice Adds guardian to the whitelist.
     *
     * Requirements:
     *
     * 1) the caller must be a contract owner.
     * @param guardian address of the new guardian
     */
    function addGuardian(address guardian) public virtual onlyOwner {
        isWhitelisted[guardian] = true;
        emit GuardianAdded(guardian);
    }

    /**
     * @notice Anyone can add Guardian fees to a guardian holding an item
     * @param collection address of the collection the item belongs to.
     * @param beneficiary the address of the holder of the item.
     * @param itemId id of the item
     * @param guardianFeeAmount the amount of guardian fee being paid.
     */
    function addStorageTime(
        IERC11554K collection,
        address beneficiary,
        uint256 itemId,
        uint256 guardianFeeAmount
    ) public virtual {
        uint256 currAmount = collection.balanceOf(beneficiary, itemId);

        address guardian = whereItemStored[collection][itemId];
        uint256 guardianClassIndex = itemGuardianClass[collection][itemId];

        uint256 guardianClassFeeRate = getGuardianFeeRate(
            guardian,
            guardianClassIndex
        );

        if (guardianClassFeeRate == 0) {
            revert("guardian class guardian fee rate is 0");
        }

        require(guardianFeeAmount > 0, "Guardian fee is 0");
        require(currAmount > 0, "Does not hold item");
        require(guardian != address(0), "Guardian not storing item");

        uint256 addedStorageTime = GuardianTimeMath.calculateAddedGuardianTime(
            guardianFeeAmount,
            guardianClassFeeRate,
            currAmount
        );

        guardianFeePaidUntil[beneficiary][collection][
            itemId
        ] += addedStorageTime;
        globalItemGuardianFeePaidUntil[collection][itemId] += addedStorageTime;

        feesManager.payGuardianFee(
            guardianFeeAmount,
            guardianClassFeeRate * currAmount,
            guardian,
            guardianFeePaidUntil[beneficiary][collection][itemId],
            _msgSender()
        );
        emit StorageTimeAdded(itemId, guardian, addedStorageTime);
    }

    /**
     * @notice Returns guardian class guardian fee rate of the stored item in collection with  itemId.
     * @param collection address of the collection where the item being queried belongs to
     * @param itemId item id of item whose guardian fee rate is being queried.
     * @return guardian fee rate of the item being queried (of guardian class it's in)
     */
    function getGuardianFeeRateByCollectionItem(
        IERC11554K collection,
        uint256 itemId
    ) public view virtual returns (uint256) {
        require(collection.totalSupply(itemId) > 0, "Item not yet minted");
        return
            guardiansClasses[whereItemStored[collection][itemId]][
                itemGuardianClass[collection][itemId]
            ].guardianFeeRate;
    }

    /**
     * @notice Returns true if the guardian is active and whitelisted.
     * @param guardian address of guardian whose guardian class is being queried
     * @return boolean - is the guardian active and whitelisted.
     */
    function isAvailable(address guardian) public view returns (bool) {
        return isWhitelisted[guardian] && guardianInfo[guardian].isActive;
    }

    /**
     * @notice Returns guardian class classID guardian fee rate.
     * @param guardian address of guardian whose guardian class is being queried
     * @param classID guardian's class index for class being queried.
     * @return feeRate the guardian class guardian fee rate
     */
    function getGuardianFeeRate(address guardian, uint256 classID)
        public
        view
        virtual
        returns (uint256)
    {
        return guardiansClasses[guardian][classID].guardianFeeRate;
    }

    /**
     * @notice Returns guardian class classID guardian fee rate historic minimum.
     * @param guardian address of guardian whose guardian class is being queried
     * @param classID guardian's class index for class being queried.
     * @return feeRateMinumum the guardian class guardian fee rate historical minimum
     */
    function getGuardianFeeRateMinimum(address guardian, uint256 classID)
        public
        view
        virtual
        returns (uint256)
    {
        return guardiansClasses[guardian][classID].guardianFeeRateMinimum;
    }

    /**
     * @notice Returns guardian class classID activity true/false.
     * @param guardian address of guardian whose guardian class is being queried
     * @param classID guardian's class index for class being queried.
     * @return activeStatus boolean - is the class active or not.
     */
    function isClassActive(address guardian, uint256 classID)
        public
        view
        virtual
        returns (bool)
    {
        return guardiansClasses[guardian][classID].isActive;
    }

    /**
     * @dev Internal call, adds guardian class.
     */
    function _addGuardianClass(
        address guardian,
        uint256 maximumCoverage,
        uint256 mintingFee,
        uint256 redemptionFee,
        uint256 guardianFeeRate
    ) internal virtual returns (uint256 classID) {
        classID = guardiansClasses[guardian].length;
        guardiansClasses[guardian].push(
            GuardianClass(
                maximumCoverage,
                mintingFee,
                redemptionFee,
                guardianFeeRate,
                guardianFeeRate,
                block.timestamp,
                true,
                ""
            )
        );
        emit GuardianClassAdded(guardian, classID);
    }

    /**
     * @dev Internal call, copies an ENTIRE guardian class from one guardian to another. Note: same data but DIFFERENT index.
     */
    function _copyGuardianClass(
        address oldGuardian,
        address newGuardian,
        uint256 oldGuardianClassIndex
    ) internal returns (uint256 classID) {
        classID = guardiansClasses[newGuardian].length;
        guardiansClasses[newGuardian].push(
            GuardianClass(
                guardiansClasses[oldGuardian][oldGuardianClassIndex]
                    .maximumCoverage,
                guardiansClasses[oldGuardian][oldGuardianClassIndex].mintingFee,
                guardiansClasses[oldGuardian][oldGuardianClassIndex]
                    .redemptionFee,
                guardiansClasses[oldGuardian][oldGuardianClassIndex]
                    .guardianFeeRate,
                guardiansClasses[oldGuardian][oldGuardianClassIndex]
                    .guardianFeeRateMinimum,
                guardiansClasses[oldGuardian][oldGuardianClassIndex]
                    .lastGuardianFeeRateIncrease,
                guardiansClasses[oldGuardian][oldGuardianClassIndex].isActive,
                guardiansClasses[oldGuardian][oldGuardianClassIndex].uri
            )
        );
        emit GuardianClassAdded(newGuardian, classID);
    }

    /**
     * @dev Internal call, that is done on each item token redeem to
     * relaculate paid storage time, guardian fees.
     */
    function _shiftGuardianFeesOnTokenRedeem(
        address from,
        IERC11554K collection,
        uint256 id,
        uint256 redeemAmount,
        uint256 guardianClassFeeRate
    ) internal virtual returns (uint256) {
        uint256 originalTimeRemaining = guardianFeePaidUntil[from][collection][
            id
        ];

        // Total fee that remains
        uint256 remainingFeeAmount = GuardianTimeMath
            .calculateRemainingFeeAmount(
                guardianFeePaidUntil[from][collection][id],
                guardianClassFeeRate,
                IERC11554K(collection).balanceOf(from, id)
            );

        // Portion of fee we're giving back, for refund.
        uint256 guardianFeeRefundAmount = GuardianTimeMath
            .calculateRemainingFeeAmount(
                guardianFeePaidUntil[from][collection][id],
                guardianClassFeeRate,
                redeemAmount
            );

        // Recalculate the remaining time with new params
        if (IERC11554K(collection).balanceOf(from, id) - redeemAmount == 0) {
            guardianFeePaidUntil[from][collection][id] = 0; //back to default,0
        } else {
            uint256 recalculatedTime = GuardianTimeMath
                .calculateAddedGuardianTime(
                    remainingFeeAmount - guardianFeeRefundAmount,
                    guardianClassFeeRate,
                    IERC11554K(collection).balanceOf(from, id) - redeemAmount
                );
            guardianFeePaidUntil[from][collection][id] =
                block.timestamp +
                recalculatedTime;
        }

        if (IERC11554K(collection).totalSupply(id) - redeemAmount == 0) {
            globalItemGuardianFeePaidUntil[collection][id] = 0;
        } else {
            uint256 timeDelta;
            if (
                originalTimeRemaining >
                guardianFeePaidUntil[from][collection][id]
            ) {
                timeDelta = (originalTimeRemaining -
                    guardianFeePaidUntil[from][collection][id]);
            } else {
                timeDelta = (guardianFeePaidUntil[from][collection][id] -
                    originalTimeRemaining);
            }
            globalItemGuardianFeePaidUntil[collection][id] -= timeDelta;
        }

        return guardianFeeRefundAmount;
    }

    function _moveSingleItem(
        IERC11554K collection,
        uint256 itemId,
        address oldGuardian,
        address newGuardian,
        uint256 newGuardianClassIndex
    ) internal virtual {
        uint256 amount = stored[oldGuardian][collection][itemId];
        stored[oldGuardian][collection][itemId] = 0;
        stored[newGuardian][collection][itemId] = amount;
        whereItemStored[collection][itemId] = newGuardian;
        itemGuardianClass[collection][itemId] = newGuardianClassIndex;
    }
}
