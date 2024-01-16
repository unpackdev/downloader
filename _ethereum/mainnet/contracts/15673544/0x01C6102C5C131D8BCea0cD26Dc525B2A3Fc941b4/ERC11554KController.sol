// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC11554K.sol";
import "./IGuardians.sol";

/**
 * @dev ERC11554K controller contract that manages all
 * ERC1155 4K collection flows: minting requests, minting, minting rejecting, users <-> guardians, items, storage fees.
 */
contract ERC11554KController is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev Minting request status.
    enum RequestStatus {
        Rejected,
        Pending,
        Minted
    }

    /// @dev Minting request struct.
    /// For each item ID only one request can be in pending state.
    /// Used for initial minting when lastRequestedID is incremented
    /// and for supply expnasion for items with a particular ID.
    struct Request {
        /// @dev Timestamp of the request.
        uint256 timestamp;
        /// @dev Amount to mint.
        uint256 amount;
        /// @dev Service fee to pay for request execution.
        uint256 serviceFee;
        /// @dev Requester.
        address requester;
        /// @dev Address to which the tokens will be minted.
        address mintAddress;
        /// @dev Guardian, who is requested to mint and store items.
        address guardian;
        /// @dev Minting/expansion request status.
        RequestStatus status;
        /// @dev Guardian class index that item will be stored in
        uint256 guardianClassIndex;
        /// @dev Guardian fee for the item at mint time
        uint256 guardianFeeAmount;
    }

    /// @dev Batch minting request data structure.
    struct BatchRequestMintData {
        /// @dev Collection address.
        address collection;
        /// @dev Item id.
        uint256 id;
        /// @dev Guardian address.
        address guardianAddress;
        /// @dev Amount to mint
        uint256 amount;
        /// @dev Service fee to guardian.
        uint256 serviceFee;
        /// @dev Is item supply expandable.
        bool isExpandable;
        /// @dev Recipient address.
        address mintAddress;
        /// @dev Guardian class index.
        uint256 guardianClassIndex;
        /// @dev Guardian fee amount to pay.
        uint256 guardianFeeAmount;
    }

    /// @notice Max mint period
    uint256 public maxMintPeriod;
    /// @notice Collection creation fee.
    uint256 public collectionFee;
    /// @notice Beneficiary fees address.
    address public beneficiary;

    /// @notice Payment token for some fees.
    IERC20Upgradeable public paymentToken;
    /// @notice Collection list of 4K items.
    address[] public collections;
    /// @notice Is active collection.
    mapping(address => bool) public isActiveCollection;
    /// @notice Is linked collection.
    mapping(address => bool) public isLinkedCollection;
    /// @notice Is minting private.
    mapping(address => bool) public isMintingPrivate;
    /// @notice Last requested id for minting.
    mapping(address => uint256) public lastRequestedID;
    /// @notice Is expandable. Can an item supply be expanded.
    mapping(address => mapping(uint256 => bool)) public isExpandable;
    /// @notice requests mapping for minting. Can only be 1 pending request per item id.
    mapping(address => mapping(uint256 => Request)) public requests;
    /// @notice Originators, irst owners of items.
    mapping(address => mapping(uint256 => address)) public originators;
    /// @notice Original mint timestamp.
    mapping(address => mapping(uint256 => uint256))
        public originalMintTimestamp;
    /// @notice Guardians contract
    IGuardians public guardians;

    /// @dev An ERC11554k contract has been linked to the controller - new 4K collection.
    event CollectionLinked(address indexed owner, address collection);
    /// @dev The active status of a collection has changed.
    event CollectionActiveStatusChanged(
        address indexed collection,
        bool newActiveStatus
    );
    /// @dev A new mint request has been generated.
    event MintRequested(
        address indexed collection,
        address indexed requester,
        address guardian,
        uint256 indexed id,
        uint256 amount,
        uint256 serviceFee,
        address mintAddress
    );
    /// @dev A mint request has been accepted by a guardian - new token(s) minted.
    event Minted(
        address indexed collection,
        address indexed guardian,
        address indexed requester,
        uint256 id,
        uint256 amount,
        address mintAddress
    );
    /// @dev Tokens have been redeemed and items have been taken out of guardian storage.
    event Redeemed(
        address indexed guardian,
        address indexed tokenOwner,
        uint256 id,
        uint256 amount
    );
    /// @dev A mint request has been rejected by a guardian.
    event MintRejected(
        address indexed collection,
        address guardian,
        uint256 id
    );

    /**
     * @notice Initialize ERC11554KController, sets controller params.
     * @param collectionFee_, collection creation fee.
     * @param beneficiary_, fees beneficiary address.
     * @param guardians_, Guardians contract address.
     * @param paymentToken_, payment token for fees.
     */
    function initialize(
        uint256 collectionFee_,
        address beneficiary_,
        IGuardians guardians_,
        IERC20Upgradeable paymentToken_
    ) external virtual initializer {
        __Ownable_init();
        beneficiary = beneficiary_;
        collectionFee = collectionFee_;
        // Sets max mint period to month (30 days) number of seconds.
        maxMintPeriod = 2592000;
        guardians = guardians_;
        paymentToken = paymentToken_;
    }

    /**
     * @notice Sets maxMintPeriod to maxMintPeriod_.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param maxMintPeriod_ New max mint period.
     */
    function setMaxMintPeriod(uint256 maxMintPeriod_) external onlyOwner {
        maxMintPeriod = maxMintPeriod_;
    }

    /**
     * @notice Sets collectionFee to collectionFee_.
     *
     * Requirements:
     *
     * 1) the caller must be a contract owner.
     * @param collectionFee_, new collection creation fee.
     */
    function setCollectionFee(uint256 collectionFee_) external onlyOwner {
        collectionFee = collectionFee_;
    }

    /**
     * @notice Sets beneficiary to beneficiary_.
     *
     * Requirements:
     *
     * 1) the caller must be a contract owner.
     * @param beneficiary_ New fees beneficiary address.
     */
    function setBeneficiary(address beneficiary_) external onlyOwner {
        beneficiary = beneficiary_;
    }

    /**
     * @notice Sets guardians contract to guardians_.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param guardians_, new Guardians contract address.
     */
    function setGuardians(IGuardians guardians_) external onlyOwner {
        guardians = guardians_;
    }

    /**
     * @notice Sets paymentToken to paymentToken_.
     *
     * Requirements:
     *
     * The caller must be a contract owner.
     * @param paymentToken_ New payment token for fees.
     */
    function setPaymentToken(IERC20Upgradeable paymentToken_)
        external
        onlyOwner
    {
        paymentToken = paymentToken_;
    }

    /**
     * @notice Links a 1155 collection to 4k's list of collections. Also activates it.
     * Doing it this way instead of creating the collection onchain because we cannot currently deploy 
     * upgradable ontracts onchain.
     * @param collection, collection address for controller linking.
     * @param _isMintingPrivate, collection minting privacy param.
     *
     * Requirements:
     *
     * 1) The caller must be the ultimate owner of the collection:
         the user who requested its creation and who is paying the collection fee.
     */
    function linkCollection(address collection, bool _isMintingPrivate)
        external
        virtual
    {
        require(
            _msgSender() == IERC11554K(collection).owner(),
            "only collection's owner"
        );
        require(!isLinkedCollection[collection], "collection already linked");
        paymentToken.safeTransferFrom(_msgSender(), beneficiary, collectionFee);
        collections.push(collection);

        isLinkedCollection[collection] = true;
        isActiveCollection[collection] = true;

        isMintingPrivate[collection] = _isMintingPrivate;

        emit CollectionLinked(_msgSender(), collection);
    }

    /**
     * @notice sets a linked collection status to active or unactive.
     *
     * Requirements:
     * 1) Callable only by collection's owner
     * 2) Collection needs to be a linked collection
     * @param collection Collection address.
     * @param activeStatus Set activity status flag.
     */
    function setCollectionActiveStatus(address collection, bool activeStatus)
        external
        virtual
    {
        require(
            _msgSender() == IERC11554K(collection).owner(),
            "only collection's owner"
        );
        require(isLinkedCollection[collection], "not a linked collection");
        isActiveCollection[collection] = activeStatus;
        emit CollectionActiveStatusChanged(collection, activeStatus);
    }

    /**
     * @notice Redeem item with 'id' by its owner.
     * Must pay redemption fee to the guardian.
     * @param collection Collection address.
     * @param guardian Guardian address, from which items are redeemed.
     * @param id Items id for redeem.
     * @param amount Amount of items with id to redeem.
     */
    function redeem(
        IERC11554K collection,
        address guardian,
        uint256 id,
        uint256 amount
    ) external virtual {
        require(
            guardians.stored(guardian, address(collection), id) >= amount,
            "not enough items stored"
        );
        require(
            collection.balanceOf(_msgSender(), id) >= amount,
            "not enough items to redeem"
        );
        paymentToken.safeTransferFrom(
            _msgSender(),
            guardian,
            guardians.getRedemptionFee(
                guardian,
                guardians.itemGuardianClass(address(collection), id)
            )
        );

        //guardians releases item from its custudy
        guardians.controllerTakeItemOut(
            guardian,
            address(collection),
            id,
            amount,
            _msgSender()
        );

        //call to token to burn
        collection.controllerBurn(_msgSender(), id, amount);

        emit Redeemed(guardian, _msgSender(), id, amount);
    }

    /**
     * @notice Batching version requestMint below. Uses BatchRequestMintData struct for data from entries.
     * See requestMint function for more details below.
     * @param entries, array of entries as BatchRequestMintData struct.
     */
    function batchRequestMint(BatchRequestMintData[] calldata entries)
        external
        virtual
    {
        for (uint256 i = 0; i < entries.length; i++) {
            requestMint(
                IERC11554K(entries[i].collection),
                entries[i].id,
                entries[i].guardianAddress,
                entries[i].amount,
                entries[i].serviceFee,
                entries[i].isExpandable,
                entries[i].mintAddress,
                entries[i].guardianClassIndex,
                entries[i].guardianFeeAmount
            );
        }
    }

    /**
     * @notice Batching version rejectMint below for collection ids
     * See rejectMint function for more details below.
     * @param collection Collection address.
     * @param ids Array of ids for minting rejection.
     */
    function batchRejectMint(IERC11554K collection, uint256[] calldata ids)
        external
        virtual
    {
        for (uint256 i = 0; i < ids.length; i++) {
            rejectMint(collection, ids[i]);
        }
    }

    /**
     * @notice Batching version mint below for collection ids
     * See mint function for more details below.
     * @param collection, collection address.
     * @param ids, array of ids for minting.
     */
    function batchMint(IERC11554K collection, uint256[] calldata ids)
        external
        virtual
    {
        for (uint256 i = 0; i < ids.length; i++) {
            mint(collection, ids[i]);
        }
    }

    /**
     * @notice Sets collection minting to public or private.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param collection Collection address.
     * @param isMintingPrivate_ Set minting privacy flag for the collection.
     */
    function setMintingPrivacy(IERC11554K collection, bool isMintingPrivate_)
        external
        virtual
    {
        require(
            _msgSender() == IERC11554K(collection).owner(),
            "not collection's owner"
        );
        isMintingPrivate[address(collection)] = isMintingPrivate_;
    }

    /**
     * @notice Turns off item expandability.
     * @param collection, collection address.
     * @param id, item id.
     *
     * Requirements:
     *
     * - The caller must be original requester for the item.
     * - The item must have expandability set to true.
     */
    function turnOffItemExpandability(IERC11554K collection, uint256 id)
        external
        virtual
    {
        require(
            _isOriginalRequester(address(collection), id, _msgSender()),
            "not orginal requester"
        );
        require(
            isExpandable[address(collection)][id],
            "Expandability is already off"
        );
        isExpandable[address(collection)][id] = false;
    }

    /**
     * @notice Returns number of linked collections, regardless of their active status.
     * @return returns uint256 collections number.
     */
    function collectionsCount() external view returns (uint256) {
        return collections.length;
    }

    /**
     * @notice Gets linked collection addresses with pagination bound by paginationPageSize from page startIndex.
     * @param startIndex, page index from which to return collecitons if collections divided into pages of paginationPageSize.
     * @param paginationPageSize, pages size collections division.
     * @return results address array, activeStatus bool array, resultsLength number.
     */
    function getPaginatedCollections(
        uint256 startIndex,
        uint256 paginationPageSize
    )
        external
        view
        returns (
            address[] memory results,
            bool[] memory activeStatus,
            uint256 resultsLength
        )
    {
        uint256 length = paginationPageSize;
        // Last page is smaller
        if (length > collections.length - startIndex) {
            length = collections.length - startIndex;
        }
        results = new address[](length);
        activeStatus = new bool[](length);
        for (uint256 i = 0; i < length; i++) {
            results[i] = collections[startIndex + i];
            activeStatus[i] = isActiveCollection[collections[startIndex + i]];
        }
        resultsLength = startIndex + length;
    }

    /**
     * @notice Guardian mints an item for collection id.
     * Gets a service fee and deposits guardian fees to fees manager.
     * @param collection, collection address.
     * @param id, item id.
     *
     * Requirements:
     *
     * 1) caller must be the requested guardian.
     * 2) guardian caller must be available.
     * 3) minting period didn't exceed maxMintPeriod
     * 4) minting request must have pending state.
     * 5) guardian class of the request must be active.
     * 6) caller must approve minting fee request + serviceFee amount for current 4K payment token.
     * @param collection Address of collection of the mint request.
     * @param id Request id of request to be processed.
     */
    function mint(IERC11554K collection, uint256 id) public virtual {
        Request storage request = requests[address(collection)][id];
        require(
            guardians.isAvailable(request.guardian),
            "not available guardian"
        );
        require(
            request.guardian == _msgSender() ||
                guardians.delegated(request.guardian) == _msgSender(),
            "not a guardian"
        );
        require(
            request.status == RequestStatus.Pending,
            "not pending" // ERC11554K: not pending
        );
        require(
            block.timestamp < request.timestamp + maxMintPeriod,
            "request expired"
        );

        if (
            isExpandable[address(collection)][id] &&
            _isRequestExpansion(collection, id)
        ) {
            require(
                request.guardianClassIndex ==
                    guardians.itemGuardianClass(address(collection), id),
                "class mismatch"
            );
        }

        bool isActive = guardians.isClassActive(
            request.guardian,
            request.guardianClassIndex
        );

        require(isActive, "class not active");

        if (originators[address(collection)][id] == address(0)) {
            originators[address(collection)][id] = request.mintAddress;
            originalMintTimestamp[address(collection)][id] = block.timestamp;
        }

        request.status = RequestStatus.Minted;

        paymentToken.safeTransfer(request.guardian, request.serviceFee);

        // Register item(s) with guardian & pay guardian fees
        guardians.controllerStoreItem(
            address(collection),
            request.mintAddress,
            id,
            request.guardian,
            request.guardianClassIndex,
            request.guardianFeeAmount,
            request.amount,
            request.requester
        );

        // Mint item
        collection.controllerMint(request.mintAddress, id, request.amount);

        emit Minted(
            address(collection),
            request.guardian,
            request.requester,
            id,
            request.amount,
            request.mintAddress
        );
    }

    /**
     * @notice Rejects id mint by guardian.
     *
     * Requirements:
     *
     * 1) caller must be guardain, to which request was made.
     * 2) minting request must be in the pending state.
     * 3) guardian caller must be active and whitelisted guardian.
     * @param collection, collection address.
     * @param id, item id.
     */
    function rejectMint(IERC11554K collection, uint256 id) public virtual {
        address guardian = requests[address(collection)][id].guardian;
        require(guardians.isAvailable(guardian), "not available guardian");
        require(
            guardian == _msgSender() ||
                guardians.delegated(guardian) == _msgSender(),
            "not a guardian"
        );
        require(
            requests[address(collection)][id].status == RequestStatus.Pending,
            "not pending"
        );
        requests[address(collection)][id].status = RequestStatus.Rejected;
        paymentToken.safeTransfer(
            requests[address(collection)][id].requester,
            requests[address(collection)][id].serviceFee
        );
        emit MintRejected(address(collection), guardian, id);
    }

    /**
     * @notice Requests mint from guardian guardianClassIndex of amount and serviceFee.
     * If id is zero then new item minting happens by making id = lastRequestedID++ ,
     * otherwise supply expansion for an item happens if item is expandable.
     * On new item minting sets item expandability to expandable, mints items to mintAddress.
     * Creates a minting request as a struct and makes minting request fee payment, stores service fee.

     * Requirements:
     *
     * 1) guardian must be available (active and whitelisted).
     * 2) caller must be whitelisted by guardian if guardian is only accepting his whitelisted users requests.
     * 3) guardianClassIndex guardian class must be active.
     * 4) caller must approve minting fee request + serviceFee amount for current 4K payment token.

     * @param collection Collection address.
     * @param id Item id, if id = 0, then make new item minting request, otherwise make supply expansion request.
     * @param guardian Which guardian will mint items and store them.
     * @param amount Amount of items to mint.
     * @param serviceFee Service fee to pay for minting to guardian, being held in escrow until minting is done.
     * @param expandable If item supply is expandable.
     * @param mintAddress Which address will be new items owner.
     * @param guardianClassIndex Guardian class index of items to mint.
     * @param guardianFeeAmount Guardian fee amount to pay for items storage.
     * @return request id
     */
    function requestMint(
        IERC11554K collection,
        uint256 id,
        address guardian,
        uint256 amount,
        uint256 serviceFee,
        bool expandable,
        address mintAddress,
        uint256 guardianClassIndex,
        uint256 guardianFeeAmount
    ) public virtual returns (uint256) {
        if (isMintingPrivate[address(collection)]) {
            require(_msgSender() == collection.owner(), "i"); //ERC11554K: minting is private
        }
        (, , , , , , bool isGuardianPrivate) = guardians.guardianInfo(guardian);
        require(guardians.isAvailable(guardian), "non available guardian");
        require(
            !isGuardianPrivate ||
                guardians.guardianWhitelist(guardian, _msgSender()),
            "not whitelisted" //ERC11554K: requester wasn't whitelisted
        );
        require(id <= lastRequestedID[address(collection)], "invalid id");

        // IF id is 0, then mint new NFT.
        if (id == 0) {
            lastRequestedID[address(collection)] += 1;
            id = lastRequestedID[address(collection)];
            isExpandable[address(collection)][
                lastRequestedID[address(collection)]
            ] = expandable;
        } else {
            //expansion, ie. more tokens with the same id
            require(
                _expansionPossible(address(collection), id),
                "not expandable"
            );
            require(
                guardianClassIndex ==
                    guardians.itemGuardianClass(address(collection), id),
                "class mismatch"
            );
        }

        bool isActive = guardians.isClassActive(guardian, guardianClassIndex);
        require(isActive, "class not active");

        if (guardians.getGuardianFeeRate(guardian, guardianClassIndex) > 0) {
            require(
                guardians.isFeeAboveMinimum(
                    guardianFeeAmount,
                    amount,
                    guardian,
                    guardianClassIndex
                ),
                "guardian fee too low"
            );
        } else {
            require(
                guardianFeeAmount == 0,
                "guardian class guardian fee rate is 0"
            );
        }

        requests[address(collection)][id] = Request(
            block.timestamp,
            amount,
            serviceFee,
            _msgSender(),
            mintAddress,
            guardian,
            RequestStatus.Pending,
            guardianClassIndex,
            guardianFeeAmount
        );

        paymentToken.safeTransferFrom(
            _msgSender(),
            guardian,
            guardians.getMintingFee(guardian, guardianClassIndex)
        );
        paymentToken.safeTransferFrom(_msgSender(), address(this), serviceFee);
        emit MintRequested(
            address(collection),
            _msgSender(),
            guardian,
            id,
            amount,
            serviceFee,
            mintAddress
        );
        return id;
    }

    /**
     * @dev Internal method that checks if item supply expansion is possible for an item collection id.
     * @param collection, collection address.
     * @param id, item id.
     * @return bool, returns true if item expnasion is possible.
     */
    function _expansionPossible(address collection, uint256 id)
        internal
        view
        returns (bool)
    {
        return
            _isOriginalRequester(collection, id, _msgSender()) &&
            isExpandable[collection][id] &&
            requests[collection][id].status == RequestStatus.Minted;
    }

    /**
     * @dev Internal method that checks if caller is an original requester of an item collection id.
     * @param collection, collection address.
     * @param id, item id.
     * @param caller, caller address to check against the original requester.
     * @return bool, returns true if caller is items original requester.
     */
    function _isOriginalRequester(
        address collection,
        uint256 id,
        address caller
    ) internal view returns (bool) {
        return requests[collection][id].requester == caller;
    }

    function _isRequestExpansion(IERC11554K collection, uint256 id)
        internal
        view
        returns (bool)
    {
        return collection.totalSupply(id) != 0;
    }
}
