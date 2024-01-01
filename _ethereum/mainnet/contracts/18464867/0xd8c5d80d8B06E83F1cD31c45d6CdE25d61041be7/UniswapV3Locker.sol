// SPDX-License-Identifier: MIT                                                                               
                                                    
pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

library Structs {
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }
}

interface IUniswapPositions is IERC721Enumerable {
    function collect(Structs.CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract UniswapV3Locker is Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    IUniswapPositions public immutable positionsContract;

    event LockedLP(Lock lock);
    
    event WithdrewLP(Lock lock);

    event EditedLock(Lock lock);

    event HarvestedFees(uint256 amount0, uint256 amount1, uint256 indexed tokenId);

    event FeeRateUpdated(uint256 _feeRate);

    event FeeReceiverUpdated(address _feeReceiver);

    event ValidFeeTokenUpdated(address _tokenAddress, bool _isValid);


    Lock[] private _locks;
    mapping(address => EnumerableSet.UintSet) private _userLpLockIds;
    mapping(address => EnumerableSet.UintSet) private _tokenLockIds;

    mapping(address => bool) public isValidFeeToken;
    address public feeReceiver;
    uint256 public feeRate;
    uint256 public constant FEE_DIVISOR = 10000;

    struct Lock {
        uint256 id;
        uint256 token;
        address owner;
        uint256 lockDate;
        uint256 unlockDate;
        uint256 lpRemovalDate;
    }

    constructor() {
        positionsContract = IUniswapPositions(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
        feeRate = 300;
        feeReceiver = msg.sender;
        if(block.chainid == 1){
            isValidFeeToken[0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2] = true;
        } else if(block.chainid == 5){
            isValidFeeToken[0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6] = true;
        }
    }

    function updateFeeRate(uint256 _feeRateWithTwoDecimals) external onlyOwner {
        require(_feeRateWithTwoDecimals <= 500, "Cannot set fee rate higher than 5%");
        feeRate = _feeRateWithTwoDecimals;
        emit FeeRateUpdated(_feeRateWithTwoDecimals);
    }

    function updateFeeReceiver(address _feeReceiver) external onlyOwner {
        require(_feeReceiver != address(0), "Zero address");
        feeReceiver = _feeReceiver;
        emit FeeReceiverUpdated(_feeReceiver);
    }

    function setValidFeeToken(address _tokenAddress, bool _isValid) external onlyOwner {
        isValidFeeToken[_tokenAddress] = _isValid;
        emit ValidFeeTokenUpdated(_tokenAddress, _isValid);
    }

    function getLockedPositions(address _wallet) public view returns (uint256[] memory){
        return _userLpLockIds[_wallet].values();
    }

    function getLockInfo(uint256 _lockId) external view returns (Lock memory){
        return _locks[_lockId];
    }

    function getLockLength() external view returns (uint256){
        return _locks.length;
    }

    function collectFromSinglePosition(uint256 _lockId) external {

        require(_userLpLockIds[msg.sender].contains(_lockId), "Not lock owner");
        
        uint256 _tokenId = _locks[_lockId].token;
        uint256 amount0;
        uint256 amount1;
        address token0;
        address token1;
        (token0, token1,,,,,,) = getPositionInfo(_tokenId);
        address recipient = (isValidFeeToken[token0] || isValidFeeToken[token1]) ? address(this) : msg.sender;
        (amount0, amount1) = positionsContract.collect(Structs.CollectParams({
            tokenId: _tokenId,
            recipient: recipient,
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        }));
        if(recipient == address(this)){
            if(isValidFeeToken[token0]){
                IERC20(token0).transfer(feeReceiver, amount0 * feeRate / FEE_DIVISOR);
            }
            if(isValidFeeToken[token1]){
                IERC20(token1).transfer(feeReceiver, amount1 * feeRate / FEE_DIVISOR);
            }
            IERC20(token0).transfer(msg.sender, IERC20(token0).balanceOf(address(this)));
            IERC20(token1).transfer(msg.sender, IERC20(token1).balanceOf(address(this)));
        }
        emit HarvestedFees(amount0, amount1, _tokenId);
    }

    function collectFromAllPositions() external {
        uint256[] memory openPositions = getLockedPositions(msg.sender);
        uint256 amount0;
        uint256 amount1;
        address token0;
        address token1;
        uint256 tokenId;
        for(uint256 i = 0; i < openPositions.length; i++){
            tokenId = _locks[i].token;
            (token0, token1,,,,,,) = getPositionInfo(tokenId);
            address recipient = (isValidFeeToken[token0] || isValidFeeToken[token1]) ? address(this) : msg.sender;
            (amount0, amount1) = positionsContract.collect(Structs.CollectParams({
                tokenId: tokenId,
                recipient: recipient,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            }));
            if(recipient == address(this)){
                if(isValidFeeToken[token0]){
                    IERC20(token0).transfer(feeReceiver, IERC20(token0).balanceOf(address(this)) * feeRate / FEE_DIVISOR);
                }
                if(isValidFeeToken[token1]){
                    IERC20(token1).transfer(feeReceiver, IERC20(token1).balanceOf(address(this)) * feeRate / FEE_DIVISOR);
                }
                IERC20(token0).transfer(msg.sender, IERC20(token0).balanceOf(address(this)));
                IERC20(token1).transfer(msg.sender, IERC20(token1).balanceOf(address(this)));
            }
            emit HarvestedFees(amount0, amount1, tokenId);
        }
    }

    function getPositionInfo(uint256 _tokenId) public view returns (
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint128 tokensOwed0,
            uint128 tokensOwed1){
                (,
                ,
                token0,
                token1,
                fee,
                tickLower,
                tickUpper,
                liquidity,
                ,
                ,
                tokensOwed0,
                tokensOwed1) = positionsContract.positions(_tokenId);
            }

    function lockLp(uint256 _tokenId, uint256 _unlockDate, address _lockOwner) external {
        (address token0,address token1,,,,,,) = getPositionInfo(_tokenId);

        // transfer NFT to owner
        IERC721(positionsContract).transferFrom(address(msg.sender), address(this), _tokenId);

        require(_unlockDate > block.timestamp, "lock must be in the future");

        // create new lock
        uint256 lockId = _locks.length;

        Lock memory lock = Lock({
            id: lockId,
            token: _tokenId,
            owner: _lockOwner,
            lockDate: block.timestamp,
            unlockDate: _unlockDate,
            lpRemovalDate: 0
        });

        // update mappings
        _userLpLockIds[_lockOwner].add(lockId);
        if(!_tokenLockIds[token0].contains(lockId)){
            _tokenLockIds[token0].add(lockId);
        }
        if(!_tokenLockIds[token1].contains(lockId)){
            _tokenLockIds[token1].add(lockId);
        }
        
        // add lock to array
        _locks.push(lock);

        emit LockedLP(lock);
    }

    function editLock(uint256 _lockId, uint256 _unlockDate, address _lockOwner) external {
        Lock storage lock = _locks[_lockId];

        require(msg.sender == lock.owner, "Not lock owner");
        require(lock.lpRemovalDate == 0, "Already removed");
        require(_unlockDate >= lock.unlockDate, "Cannot move lock backwards");

        if(lock.owner != _lockOwner){
            _userLpLockIds[msg.sender].remove(_lockId);
            _userLpLockIds[_lockOwner].add(_lockId);
            lock.owner = _lockOwner;
        }

        lock.unlockDate = _unlockDate;

        emit EditedLock(lock);
    }

    function unlockLp(uint256 _lockId) external {
        Lock storage lock = _locks[_lockId];
        
        //logical checks
        require(msg.sender == lock.owner, "Not lock owner");
        require(block.timestamp >= lock.unlockDate, "Token still locked");
        require(lock.lpRemovalDate == 0, "Already removed");

        // update lock values and mappings
        lock.lpRemovalDate = block.timestamp;
        _userLpLockIds[msg.sender].remove(_lockId);

        (address token0,address token1,,,,,,) = getPositionInfo(lock.token);
        _tokenLockIds[token0].remove(_lockId);
        _tokenLockIds[token1].remove(_lockId);

        // transfer NFT to owner
        IERC721(positionsContract).transferFrom(address(this), msg.sender, lock.token);
        emit WithdrewLP(lock);
    }
}