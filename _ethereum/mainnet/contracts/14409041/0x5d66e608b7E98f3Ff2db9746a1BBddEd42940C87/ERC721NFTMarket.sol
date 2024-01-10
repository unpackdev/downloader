
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Holder.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

interface ICollectionWhitelistChecker {
    function canList(uint256 _tokenId) external view returns (bool);
}
interface IPancakeRouter {
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}
contract ERC721NFTMarket is ERC721Holder, Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    using SafeERC20 for IERC20;

    enum CollectionStatus {
        Pending,
        Open,
        Close
    }

    address public immutable WBNB;
    address public immutable MEXI;
    address public PancakeRouter;

    uint256 public constant TOTAL_MAX_FEE = 1000; // 10% of a sale

    address public adminAddress;
    address public treasuryAddress;

    uint256 public minimumAskPrice; // in wei
    uint256 public maximumAskPrice; // in wei

    mapping(address => mapping(address => uint256)) public pendingRevenue; // user -> buy asset -> revenue // For creator/treasury to claim

    EnumerableSet.AddressSet private _collectionAddressSet;

    mapping(address => mapping(uint256 => Ask)) public _askDetails; // Ask details (price + seller address) for a given collection and a tokenId
    mapping(address => EnumerableSet.UintSet) private _askTokenIds; // Set of tokenIds for a collection
    mapping(address => Collection) private _collections; // Details about the collections
    mapping(address => mapping(address => EnumerableSet.UintSet)) private _tokenIdsOfSellerForCollection;
    mapping(string => mapping(address => EnumerableSet.UintSet)) private _tokenIdsOfHashForCollection;

    mapping(address => uint256) public totalOrderCollection; // Collection => total
    mapping(string => uint256) public totalOrderPerhash;
    uint256 public totalCollection;
    uint256 public volume;
    mapping(address => uint256) public volumeCollection; // Collection => volume
    mapping(address => bool) public assetAccept;

    struct Ask {
        address seller; // address of the seller
        uint256 price; // price of the token
        address acceptAsset; // optional asset to buy
    }

    struct Collection {
        CollectionStatus status; // status of the collection
        address creatorAddress; // address of the creator
        address whitelistChecker; // whitelist checker (if not set --> 0x00)
        uint256 tradingFee; // trading fee (100 = 1%, 500 = 5%, 5 = 0.05%)
        uint256 creatorFee; // creator fee (100 = 1%, 500 = 5%, 5 = 0.05%)
    }

    // Ask order is cancelled
    event AskCancel(address indexed collection, address indexed seller, uint256 indexed tokenId);

    // Ask order is created
    event AskNew(address indexed collection, address indexed seller, uint256 indexed tokenId, uint256 askPrice, address _assetAccept);

    // Ask order is updated
    event AskUpdate(address indexed collection, address indexed seller, uint256 indexed tokenId, uint256 askPrice, address _assetAccept);

    // Collection is closed for trading and new listings
    event CollectionClose(address indexed collection);

    // New collection is added
    event CollectionNew(
        address indexed collection,
        address indexed creator,
        address indexed whitelistChecker,
        uint256 tradingFee,
        uint256 creatorFee
    );

    // Existing collection is updated
    event CollectionUpdate(
        address indexed collection,
        address indexed creator,
        address indexed whitelistChecker,
        uint256 tradingFee,
        uint256 creatorFee
    );

    // Admin and Treasury Addresses are updated
    event NewPancakeRouterAddresses(address indexed pancakeRouter);

    // Admin and Treasury Addresses are updated
    event NewAdminAndTreasuryAddresses(address indexed admin, address indexed treasury);

    // Minimum/maximum ask prices are updated
    event NewMinimumAndMaximumAskPrices(uint256 minimumAskPrice, uint256 maximumAskPrice);

    // Recover NFT tokens sent by accident
    event NonFungibleTokenRecovery(address indexed token, uint256 indexed tokenId);

    // Pending revenue is claimed
    event RevenueClaim(address indexed claimer, uint256 amount);

    // Recover ERC20 tokens sent by accident
    event TokenRecovery(address indexed token, uint256 amount);

    // Ask order is matched by a trade
    event Trade(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 askPrice,
        uint256 netPrice,
        bool withBNB
    );

    // Modifier for the admin
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Management: Not admin");
        _;
    }

    /**
     * @notice Constructor
     * @param _adminAddress: address of the admin
     * @param _treasuryAddress: address of the treasury
     * @param _WBNBAddress: WBNB address
     * @param _minimumAskPrice: minimum ask price
     * @param _maximumAskPrice: maximum ask price
     */
    constructor(
        address _adminAddress,
        address _treasuryAddress,
        address _WBNBAddress,
        address _MEXIAddress,
        address _PancakeRouteAddress,
        uint256 _minimumAskPrice,
        uint256 _maximumAskPrice
    ) {
        require(_adminAddress != address(0), "Operations: Admin address cannot be zero");
        require(_treasuryAddress != address(0), "Operations: Treasury address cannot be zero");
        require(_WBNBAddress != address(0), "Operations: WBNB address cannot be zero");
        require(_MEXIAddress != address(0), "Operations: MEXI address cannot be zero");
        require(_PancakeRouteAddress != address(0), "Operations: PancakeRouteAddress address cannot be zero");
        require(_minimumAskPrice < _maximumAskPrice, "Operations: _minimumAskPrice < _maximumAskPrice");

        adminAddress = _adminAddress;
        treasuryAddress = _treasuryAddress;

        WBNB = _WBNBAddress;
        MEXI = _MEXIAddress;
        assetAccept[WBNB] = true;
        assetAccept[MEXI] = true;
        PancakeRouter = _PancakeRouteAddress;

        minimumAskPrice = _minimumAskPrice;
        maximumAskPrice = _maximumAskPrice;
        _addCollection(0x41e72f59152305C290CE42074a6fe5d097AC8410, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000, 0, 0);
        _addCollection(0x13B17c3176F98063B28578689792eE0972968521, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000, 0, 0);
    }
    function setAssetAccept(address[] memory assets, bool _status) external {
        for(uint i = 0; i < assets.length; i++) {
            assetAccept[assets[i]] = _status;
        }
    }
    /**
     * @notice Buy token with BNB by matching the price of an existing ask order
     * @param _collection: contract address of the NFT
     * @param _tokenId: tokenId of the NFT purchased
     */
    function buyTokenUsingBNB(address _collection, uint256 _tokenId, string memory _hash) external payable nonReentrant {
        // Wrap BNB
        IWETH(WBNB).deposit{value: msg.value}();

        _buyToken(_collection, _tokenId, msg.value, true, _hash);
    }
    function buyTokenUsingBNB2Seller(address _collection, uint256 _tokenId, string memory _hash) external payable nonReentrant {
        _buyTokenTakeFeeBaseOnBuyAsset(_collection, _tokenId, msg.value, true, _hash, address(0), msg.value);
    }

    /**
     * @notice Buy token with MEXI by matching the price of an existing ask order
     * @param _collection: contract address of the NFT
     * @param _tokenId: tokenId of the NFT purchased
     * @param _price: price (must be equal to the askPrice set by the seller)
     */
    function buyTokenUsingMEXI(
        address _collection,
        uint256 _tokenId,
        uint256 _price,
        string memory _hash
    ) external nonReentrant {
        address[] memory path = new address[](2);
        path[0] = MEXI;
        path[1] = WBNB;
        uint[] memory amounts = IPancakeRouter(PancakeRouter).getAmountsIn(_price, path);
        IERC20(MEXI).safeTransferFrom(address(msg.sender), address(this), amounts[0]);
        IERC20(MEXI).approve(PancakeRouter, amounts[0]);
        IPancakeRouter(PancakeRouter).swapExactTokensForTokens(amounts[0], _price, path, address(this), block.timestamp);
        _buyToken(_collection, _tokenId, _price, false, _hash);
    }

    function buyTokenUsingAsset2Seller(
        address _collection,
        uint256 _tokenId,
        uint256 _price,
        string memory _hash
    ) external nonReentrant {
        Ask memory askOrder = _askDetails[_collection][_tokenId];
        address[] memory path = new address[](2);
        path[0] = askOrder.acceptAsset;
        path[1] = WBNB;
        uint[] memory amounts = IPancakeRouter(PancakeRouter).getAmountsIn(_price, path);
        IERC20(path[0]).safeTransferFrom(address(msg.sender), address(this), amounts[0]);
        _buyTokenTakeFeeBaseOnBuyAsset(_collection, _tokenId, _price, false, _hash, path[0], amounts[0]);
    }
    /**
     * @notice Buy token with WBNB by matching the price of an existing ask order
     * @param _collection: contract address of the NFT
     * @param _tokenId: tokenId of the NFT purchased
     * @param _price: price (must be equal to the askPrice set by the seller)
     */
    function buyTokenUsingWBNB(
        address _collection,
        uint256 _tokenId,
        uint256 _price,
        string memory _hash
    ) external nonReentrant {
        IERC20(WBNB).safeTransferFrom(address(msg.sender), address(this), _price);

        _buyToken(_collection, _tokenId, _price, false, _hash);
    }
    function buyTokenUsingWBNB2Seller(
        address _collection,
        uint256 _tokenId,
        uint256 _price,
        string memory _hash
    ) external nonReentrant {
        IERC20(WBNB).safeTransferFrom(address(msg.sender), address(this), _price);
        _buyTokenTakeFeeBaseOnBuyAsset(_collection, _tokenId, _price, false, _hash, WBNB, _price);
    }

    /**
     * @notice Cancel existing ask order
     * @param _collection: contract address of the NFT
     * @param _tokenId: tokenId of the NFT
     */
    function cancelAskOrder(address _collection, uint256 _tokenId, string memory _hash) external nonReentrant {
        // Verify the sender has listed it
        require(_tokenIdsOfSellerForCollection[msg.sender][_collection].contains(_tokenId), "Order: Token not listed");

        // Adjust the information
        _tokenIdsOfSellerForCollection[msg.sender][_collection].remove(_tokenId);
        _tokenIdsOfHashForCollection[_hash][_collection].remove(_tokenId);
        delete _askDetails[_collection][_tokenId];
        _askTokenIds[_collection].remove(_tokenId);

        // Transfer the NFT back to the user
        IERC721(_collection).safeTransferFrom(address(this), address(msg.sender), _tokenId);
        totalOrderCollection[_collection]--;
        totalOrderPerhash[_hash]--;
        // Emit event
        emit AskCancel(_collection, msg.sender, _tokenId);
    }

    /**
     * @notice Claim pending revenue (treasury or creators)
     */
    function claimPendingRevenue(address buyAsset) external nonReentrant {
        uint256 revenueToClaim = pendingRevenue[msg.sender][buyAsset];
        require(revenueToClaim != 0, "Claim: Nothing to claim");
        pendingRevenue[msg.sender][buyAsset] = 0;
        if(buyAsset == address(0)) payable(msg.sender).transfer(revenueToClaim);
        else IERC20(buyAsset).safeTransfer(address(msg.sender), revenueToClaim);

        emit RevenueClaim(msg.sender, revenueToClaim);
    }

    /**
     * @notice Create ask order
     * @param _collection: contract address of the NFT
     * @param _tokenId: tokenId of the NFT
     * @param _askPrice: price for listing (in wei)
     */
    function createAskOrder(
        address _collection,
        uint256 _tokenId,
        uint256 _askPrice,
        string memory _hash,
        address _assetAccept
    ) external nonReentrant {
        require(assetAccept[_assetAccept], "Order: Asset not accepted");
        // Verify price is not too low/high
        require(_askPrice >= minimumAskPrice && _askPrice <= maximumAskPrice, "Order: Price not within range");

        // Verify collection is accepted
        require(_collections[_collection].status == CollectionStatus.Open, "Collection: Not for listing");

        // Verify token has restriction
        require(_canTokenBeListed(_collection, _tokenId), "Order: tokenId not eligible");

        // Transfer NFT to this contract
        IERC721(_collection).safeTransferFrom(address(msg.sender), address(this), _tokenId);

        // Adjust the information
        _tokenIdsOfSellerForCollection[msg.sender][_collection].add(_tokenId);
        _tokenIdsOfHashForCollection[_hash][_collection].add(_tokenId);
        _askDetails[_collection][_tokenId] = Ask({seller: msg.sender, price: _askPrice, acceptAsset: _assetAccept});

        // Add tokenId to the askTokenIds set
        _askTokenIds[_collection].add(_tokenId);
        totalOrderCollection[_collection]++;
        totalOrderPerhash[_hash]++;
        // Emit event
        emit AskNew(_collection, msg.sender, _tokenId, _askPrice, _assetAccept);
    }

    /**
     * @notice Modify existing ask order
     * @param _collection: contract address of the NFT
     * @param _tokenId: tokenId of the NFT
     * @param _newPrice: new price for listing (in wei)
     */
    function modifyAskOrder(
        address _collection,
        uint256 _tokenId,
        uint256 _newPrice,
        address _assetAccept
    ) external nonReentrant {
        // Verify new price is not too low/high
        require(_newPrice >= minimumAskPrice && _newPrice <= maximumAskPrice, "Order: Price not within range");

        // Verify collection is accepted
        require(_collections[_collection].status == CollectionStatus.Open, "Collection: Not for listing");

        // Verify the sender has listed it
        require(_tokenIdsOfSellerForCollection[msg.sender][_collection].contains(_tokenId), "Order: Token not listed");

        // Adjust the information
        _askDetails[_collection][_tokenId].price = _newPrice;

        // Emit event
        emit AskUpdate(_collection, msg.sender, _tokenId, _newPrice, _assetAccept);
    }

    /**
     * @notice Add a new collection
     * @param _collection: collection address
     * @param _creator: creator address (must be 0x00 if none)
     * @param _whitelistChecker: whitelist checker (for additional restrictions, must be 0x00 if none)
     * @param _tradingFee: trading fee (100 = 1%, 500 = 5%, 5 = 0.05%)
     * @param _creatorFee: creator fee (100 = 1%, 500 = 5%, 5 = 0.05%, 0 if creator is 0x00)
     * @dev Callable by admin
     */
    function _addCollection(address _collection, address _creator, address _whitelistChecker, uint256 _tradingFee, uint256 _creatorFee) internal {
        _collectionAddressSet.add(_collection);

        _collections[_collection] = Collection({
            status: CollectionStatus.Open,
            creatorAddress: _creator,
            whitelistChecker: _whitelistChecker,
            tradingFee: _tradingFee,
            creatorFee: _creatorFee
        });
        totalCollection++;
    }
    function addCollection(
        address _collection,
        address _creator,
        address _whitelistChecker,
        uint256 _tradingFee,
        uint256 _creatorFee
    ) external onlyAdmin {
        require(!_collectionAddressSet.contains(_collection), "Operations: Collection already listed");
        require(IERC721(_collection).supportsInterface(0x80ac58cd), "Operations: Not ERC721");

        require(
            (_creatorFee == 0 && _creator == address(0)) || (_creatorFee != 0 && _creator != address(0)),
            "Operations: Creator parameters incorrect"
        );

        require(_tradingFee + _creatorFee <= TOTAL_MAX_FEE, "Operations: Sum of fee must inferior to TOTAL_MAX_FEE");
        _addCollection(_collection, _creator, _whitelistChecker, _tradingFee, _creatorFee);

        emit CollectionNew(_collection, _creator, _whitelistChecker, _tradingFee, _creatorFee);
    }

    /**
     * @notice Allows the admin to close collection for trading and new listing
     * @param _collection: collection address
     * @dev Callable by admin
     */
    function closeCollectionForTradingAndListing(address _collection) external onlyAdmin {
        require(_collectionAddressSet.contains(_collection), "Operations: Collection not listed");

        _collections[_collection].status = CollectionStatus.Close;
        _collectionAddressSet.remove(_collection);
        totalCollection--;
        emit CollectionClose(_collection);
    }

    /**
     * @notice Modify collection characteristics
     * @param _collection: collection address
     * @param _creator: creator address (must be 0x00 if none)
     * @param _whitelistChecker: whitelist checker (for additional restrictions, must be 0x00 if none)
     * @param _tradingFee: trading fee (100 = 1%, 500 = 5%, 5 = 0.05%)
     * @param _creatorFee: creator fee (100 = 1%, 500 = 5%, 5 = 0.05%, 0 if creator is 0x00)
     * @dev Callable by admin
     */
    function modifyCollection(
        address _collection,
        address _creator,
        address _whitelistChecker,
        uint256 _tradingFee,
        uint256 _creatorFee
    ) external onlyAdmin {
        require(_collectionAddressSet.contains(_collection), "Operations: Collection not listed");

        require(
            (_creatorFee == 0 && _creator == address(0)) || (_creatorFee != 0 && _creator != address(0)),
            "Operations: Creator parameters incorrect"
        );

        require(_tradingFee + _creatorFee <= TOTAL_MAX_FEE, "Operations: Sum of fee must inferior to TOTAL_MAX_FEE");

        _collections[_collection] = Collection({
        status: CollectionStatus.Open,
        creatorAddress: _creator,
        whitelistChecker: _whitelistChecker,
        tradingFee: _tradingFee,
        creatorFee: _creatorFee
        });

        emit CollectionUpdate(_collection, _creator, _whitelistChecker, _tradingFee, _creatorFee);
    }

    /**
     * @notice Allows the admin to update minimum and maximum prices for a token (in wei)
     * @param _minimumAskPrice: minimum ask price
     * @param _maximumAskPrice: maximum ask price
     * @dev Callable by admin
     */
    function updateMinimumAndMaximumPrices(uint256 _minimumAskPrice, uint256 _maximumAskPrice) external onlyAdmin {
        require(_minimumAskPrice < _maximumAskPrice, "Operations: _minimumAskPrice < _maximumAskPrice");

        minimumAskPrice = _minimumAskPrice;
        maximumAskPrice = _maximumAskPrice;

        emit NewMinimumAndMaximumAskPrices(_minimumAskPrice, _maximumAskPrice);
    }

    /**
     * @notice Allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @dev Callable by owner
     */
    function recoverFungibleTokens(address _token) external onlyOwner {
        require(_token != WBNB, "Operations: Cannot recover WBNB");
        uint256 amountToRecover = IERC20(_token).balanceOf(address(this));
        require(amountToRecover != 0, "Operations: No token to recover");

        IERC20(_token).safeTransfer(address(msg.sender), amountToRecover);

        emit TokenRecovery(_token, amountToRecover);
    }

    /**
     * @notice Allows the owner to recover NFTs sent to the contract by mistake
     * @param _token: NFT token address
     * @param _tokenId: tokenId
     * @dev Callable by owner
     */
    function recoverNonFungibleToken(address _token, uint256 _tokenId) external onlyOwner nonReentrant {
        require(!_askTokenIds[_token].contains(_tokenId), "Operations: NFT not recoverable");
        IERC721(_token).safeTransferFrom(address(this), address(msg.sender), _tokenId);

        emit NonFungibleTokenRecovery(_token, _tokenId);
    }

    /**
     * @notice Set pancake router address
     * @dev Only callable by owner
     * @param _pancakeRouter: address of the pancakeRouter
     */
    function setPancakeRouteAddresses(address _pancakeRouter) external onlyOwner {
        require(_pancakeRouter != address(0), "Operations: PancakeRouter address cannot be zero");

        PancakeRouter = _pancakeRouter;

        emit NewPancakeRouterAddresses(_pancakeRouter);
    }

    /**
     * @notice Set admin address
     * @dev Only callable by owner
     * @param _adminAddress: address of the admin
     * @param _treasuryAddress: address of the treasury
     */
    function setAdminAndTreasuryAddresses(address _adminAddress, address _treasuryAddress) external onlyOwner {
        require(_adminAddress != address(0), "Operations: Admin address cannot be zero");
        require(_treasuryAddress != address(0), "Operations: Treasury address cannot be zero");

        adminAddress = _adminAddress;
        treasuryAddress = _treasuryAddress;

        emit NewAdminAndTreasuryAddresses(_adminAddress, _treasuryAddress);
    }

    /**
     * @notice View ask orders for a given collection across all sellers
     * @param collection: address of the collection
     * @param cursor: cursor
     * @param size: size of the response
     */
    function viewAsksByCollection(
        address collection,
        uint256 cursor,
        uint256 size
    )
    external
    view
    returns (
        uint256[] memory tokenIds,
        Ask[] memory askInfo,
        uint256
    )
    {
        uint256 length = size;

        if (length > _askTokenIds[collection].length() - cursor) {
            length = _askTokenIds[collection].length() - cursor;
        }

        tokenIds = new uint256[](length);
        askInfo = new Ask[](length);

        for (uint256 i = 0; i < length; i++) {
            tokenIds[i] = _askTokenIds[collection].at(cursor + i);
            askInfo[i] = _askDetails[collection][tokenIds[i]];
        }

        return (tokenIds, askInfo, cursor + length);
    }
    /**
     * @notice View ask orders for a given collection and a hash
     * @param collection: address of the collection
     * @param hash: string of the hash
     * @param cursor: cursor
     * @param size: size of the response
     */
    function viewAsksByCollectionAndHash(
        address collection,
        string memory hash,
        uint256 cursor,
        uint256 size
    )
    external
    view
    returns (
        uint256[] memory tokenIds,
        Ask[] memory askInfo,
        uint256
    )
    {
        uint256 length = size;

        if (length > _tokenIdsOfHashForCollection[hash][collection].length() - cursor) {
            length = _tokenIdsOfHashForCollection[hash][collection].length() - cursor;
        }

        tokenIds = new uint256[](length);
        askInfo = new Ask[](length);

        for (uint256 i = 0; i < length; i++) {
            tokenIds[i] = _tokenIdsOfHashForCollection[hash][collection].at(cursor + i);
            askInfo[i] = _askDetails[collection][tokenIds[i]];
        }

        return (tokenIds, askInfo, cursor + length);
    }
    /**
     * @notice View ask orders for a given collection and a seller
     * @param collection: address of the collection
     * @param seller: address of the seller
     * @param cursor: cursor
     * @param size: size of the response
     */
    function viewAsksByCollectionAndSeller(
        address collection,
        address seller,
        uint256 cursor,
        uint256 size
    )
    external
    view
    returns (
        uint256[] memory tokenIds,
        Ask[] memory askInfo,
        uint256
    )
    {
        uint256 length = size;

        if (length > _tokenIdsOfSellerForCollection[seller][collection].length() - cursor) {
            length = _tokenIdsOfSellerForCollection[seller][collection].length() - cursor;
        }

        tokenIds = new uint256[](length);
        askInfo = new Ask[](length);

        for (uint256 i = 0; i < length; i++) {
            tokenIds[i] = _tokenIdsOfSellerForCollection[seller][collection].at(cursor + i);
            askInfo[i] = _askDetails[collection][tokenIds[i]];
        }

        return (tokenIds, askInfo, cursor + length);
    }

    /*
     * @notice View addresses and details for all the collections available for trading
     * @param cursor: cursor
     * @param size: size of the response
     */
    function viewCollections(uint256 cursor, uint256 size)
    external
    view
    returns (
        address[] memory collectionAddresses,
        Collection[] memory collectionDetails,
        uint256
    )
    {
        uint256 length = size;

        if (length > _collectionAddressSet.length() - cursor) {
            length = _collectionAddressSet.length() - cursor;
        }

        collectionAddresses = new address[](length);
        collectionDetails = new Collection[](length);

        for (uint256 i = 0; i < length; i++) {
            collectionAddresses[i] = _collectionAddressSet.at(cursor + i);
            collectionDetails[i] = _collections[collectionAddresses[i]];
        }

        return (collectionAddresses, collectionDetails, cursor + length);
    }

    /**
     * @notice Calculate price and associated fees for a collection
     * @param collection: address of the collection
     * @param price: listed price
     */
    function calculatePriceAndFeesForCollection(address collection, uint256 price)
    external
    view
    returns (
        uint256 netPrice,
        uint256 tradingFee,
        uint256 creatorFee
    )
    {
        if (_collections[collection].status != CollectionStatus.Open) {
            return (0, 0, 0);
        }

        return (_calculatePriceAndFeesForCollection(collection, price));
    }

    /**
     * @notice Checks if an array of tokenIds can be listed
     * @param _collection: address of the collection
     * @param _tokenIds: array of tokenIds
     * @dev if collection is not for trading, it returns array of bool with false
     */
    function canTokensBeListed(address _collection, uint256[] calldata _tokenIds)
    external
    view
    returns (bool[] memory listingStatuses)
    {
        listingStatuses = new bool[](_tokenIds.length);

        if (_collections[_collection].status != CollectionStatus.Open) {
            return listingStatuses;
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            listingStatuses[i] = _canTokenBeListed(_collection, _tokenIds[i]);
        }

        return listingStatuses;
    }

    function _buyTokenTakeFeeBaseOnBuyAsset(
        address _collection,
        uint256 _tokenId,
        uint256 _price,
        bool _withBNB,
        string memory _hash,
        address asset2Buy,
        uint _priceOnAsset2Buy
    ) internal {
        require(_collections[_collection].status == CollectionStatus.Open, "Collection: Not for trading");
        require(_askTokenIds[_collection].contains(_tokenId), "Buy: Not for sale");

        Ask memory askOrder = _askDetails[_collection][_tokenId];

        // Front-running protection
        require(_price == askOrder.price, "Buy: Incorrect price");
        require(msg.sender != askOrder.seller, "Buy: Buyer cannot be seller");

        // Calculate the net price (collected by seller), trading fee (collected by treasury), creator fee (collected by creator)
        (uint256 netPrice, uint256 tradingFee, uint256 creatorFee) = _calculatePriceAndFeesForCollection(_collection, _priceOnAsset2Buy);

        // Update storage information
        _tokenIdsOfSellerForCollection[askOrder.seller][_collection].remove(_tokenId);
        _tokenIdsOfHashForCollection[_hash][_collection].remove(_tokenId);
        delete _askDetails[_collection][_tokenId];
        _askTokenIds[_collection].remove(_tokenId);

        // Transfer to seller
        if(_withBNB) payable(askOrder.seller).transfer(netPrice);
        else IERC20(asset2Buy).safeTransfer(askOrder.seller, netPrice);
        // Update pending revenues for treasury/creator (if any!)
        if (creatorFee != 0) {
            pendingRevenue[_collections[_collection].creatorAddress][asset2Buy] += creatorFee;
        }

        // Update trading fee if not equal to 0
        if (tradingFee != 0) {
            pendingRevenue[treasuryAddress][asset2Buy] += tradingFee;
        }

        // Transfer NFT to buyer
        IERC721(_collection).safeTransferFrom(address(this), address(msg.sender), _tokenId);
        totalOrderCollection[_collection]--;
        totalOrderPerhash[_hash]--;

        volume += _price;
        volumeCollection[_collection] += _price;
        // Emit event
        emit Trade(_collection, _tokenId, askOrder.seller, msg.sender, _price, netPrice, _withBNB);
    }
    /**
     * @notice Buy token by matching the price of an existing ask order
     * @param _collection: contract address of the NFT
     * @param _tokenId: tokenId of the NFT purchased
     * @param _price: price (must match the askPrice from the seller)
     * @param _withBNB: whether the token is bought with BNB (true) or WBNB (false)
     */
    function _buyToken(
        address _collection,
        uint256 _tokenId,
        uint256 _price,
        bool _withBNB,
        string memory _hash
    ) internal {
        require(_collections[_collection].status == CollectionStatus.Open, "Collection: Not for trading");
        require(_askTokenIds[_collection].contains(_tokenId), "Buy: Not for sale");

        Ask memory askOrder = _askDetails[_collection][_tokenId];

        // Front-running protection
        require(_price == askOrder.price, "Buy: Incorrect price");
        require(msg.sender != askOrder.seller, "Buy: Buyer cannot be seller");

        // Calculate the net price (collected by seller), trading fee (collected by treasury), creator fee (collected by creator)
        (uint256 netPrice, uint256 tradingFee, uint256 creatorFee) = _calculatePriceAndFeesForCollection(
            _collection,
            _price
        );

        // Update storage information
        _tokenIdsOfSellerForCollection[askOrder.seller][_collection].remove(_tokenId);
        _tokenIdsOfHashForCollection[_hash][_collection].remove(_tokenId);
        delete _askDetails[_collection][_tokenId];
        _askTokenIds[_collection].remove(_tokenId);

        // Transfer WBNB
        IERC20(WBNB).safeTransfer(askOrder.seller, netPrice);

        // Update pending revenues for treasury/creator (if any!)
        if (creatorFee != 0) {
            pendingRevenue[_collections[_collection].creatorAddress][WBNB] += creatorFee;
        }

        // Update trading fee if not equal to 0
        if (tradingFee != 0) {
            pendingRevenue[treasuryAddress][WBNB] += tradingFee;
        }

        // Transfer NFT to buyer
        IERC721(_collection).safeTransferFrom(address(this), address(msg.sender), _tokenId);
        totalOrderCollection[_collection]--;
        totalOrderPerhash[_hash]--;

        volume += _price;
        volumeCollection[_collection] += _price;
        // Emit event
        emit Trade(_collection, _tokenId, askOrder.seller, msg.sender, _price, netPrice, _withBNB);
    }

    /**
     * @notice Calculate price and associated fees for a collection
     * @param _collection: address of the collection
     * @param _askPrice: listed price
     */
    function _calculatePriceAndFeesForCollection(address _collection, uint256 _askPrice) internal view returns (
        uint256 netPrice,
        uint256 tradingFee,
        uint256 creatorFee
    ){
        tradingFee = (_askPrice * _collections[_collection].tradingFee) / 10000;
        creatorFee = (_askPrice * _collections[_collection].creatorFee) / 10000;

        netPrice = _askPrice - tradingFee - creatorFee;

        return (netPrice, tradingFee, creatorFee);
    }

    /**
     * @notice Checks if a token can be listed
     * @param _collection: address of the collection
     * @param _tokenId: tokenId
     */
    function _canTokenBeListed(address _collection, uint256 _tokenId) internal view returns (bool) {
        address whitelistCheckerAddress = _collections[_collection].whitelistChecker;
        return
        (whitelistCheckerAddress == address(0)) ||
        ICollectionWhitelistChecker(whitelistCheckerAddress).canList(_tokenId);
    }
}