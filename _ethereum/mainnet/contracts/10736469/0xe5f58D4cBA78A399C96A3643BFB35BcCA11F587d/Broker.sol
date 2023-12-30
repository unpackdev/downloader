pragma solidity >=0.6.0;


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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 */
abstract contract VersionedInitializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    uint256 private lastInitializedRevision = 0;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        uint256 revision = getRevision();
        require(
            initializing ||
                isConstructor() ||
                revision > lastInitializedRevision,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            lastInitializedRevision = revision;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev returns the revision number of the contract.
    /// Needs to be defined in the inherited class as a constant.
    function getRevision() internal virtual pure returns (uint256);

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        //solium-disable-next-line
        assembly {
            cs := extcodesize(address())
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[16] private ______gap;
}

abstract contract Initializable is VersionedInitializable {
    function getRevision() internal override pure returns (uint256) {
        return version();
    }
    function version() public virtual pure returns (uint256);
}

interface IAuthentication {
    function accessible(
        address sender,
        address code,
        bytes4 sig
    ) external view returns (bool);
}

contract Assignable {
    event Enable(address sender, bytes4 sig);
    event Disable(address sender, bytes4 sig);

    address public authentication;
    mapping(address => mapping(bytes4 => uint256)) public weights;

    modifier auth() virtual {
        require(
            msg.sender == address(this) ||
                weights[msg.sender][msg.sig] == 1 ||
                IAuthentication(authentication).accessible(
                    msg.sender,
                    address(this),
                    msg.sig
                ),
            "Assignable.auth.EID00001"
        );
        _;
    }

    function enable(address sender, bytes4 sig) public auth {
        weights[sender][sig] = 1;
        emit Enable(sender, sig);
    }

    function disable(address sender, bytes4 sig) public auth {
        weights[sender][sig] = 0;
        emit Disable(sender, sig);
    }

    function _initialize(address _authentication) internal {
        require(_authentication != address(0), "Assignable._initialize.EID00090");
        require(authentication == address(0), "Assignable._initialize.EID00022");
        authentication = _authentication;
    }

    uint256[16] __Assignable_reserved__;
}

contract Ownable {
    address public owner;

    modifier onlyown() {
        require(msg.sender == owner, "Ownable.onlyown.EID00001");
        _;
    }

    function _initialize(address _owner) internal {
        require(_owner != address(0), "Ownable._initialize.EID00090");
        require(owner == address(0), "Ownable._initialize.EID00022");
        owner = _owner;
    }

    uint256[16] __Ownable_reserved__;
}

contract Broker is Assignable, Initializable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    function initialize(address _authentication) public initializer {
        Assignable._initialize(_authentication);
    }

    function version() public override pure returns (uint256) {
        return uint256(0x1);
    }

    //publisher => topic => subscriber
    mapping(address => mapping(bytes32 => EnumerableSet.AddressSet))
        private _subscribers;
    //subscriber => publisher => topic => handler
    mapping(address => mapping(address => mapping(bytes32 => bytes4)))
        public handlers;

    function subscribe(
        address subscriber, //订阅者
        address publisher, //发布者
        bytes32 topic, //被订阅的消息
        bytes4 handler //消息处理函数
    ) public auth {
        require(
            handlers[subscriber][publisher][topic] != handler,
            "Broker.subscribe.EID00015"
        );
        _subscribers[publisher][topic].add(subscriber);
        handlers[subscriber][publisher][topic] = handler;
    }

    function unsubscribe(
        address subscriber,
        address publisher,
        bytes32 topic
    ) public auth {
        require(
            handlers[subscriber][publisher][topic] != bytes4(0),
            "Broker.unsubscribe.EID00016"
        );
        _subscribers[publisher][topic].remove(msg.sender);
        delete handlers[subscriber][publisher][topic];
    }

    //sig: handler(address publiser, bytes32 topic, bytes memory data)
    function publish(bytes32 topic, bytes calldata data) external auth {
        uint256 length = _subscribers[msg.sender][topic].length();
        for (uint256 i = 0; i < length; ++i) {
            address subscriber = _subscribers[msg.sender][topic].at(i);
            bytes memory _data = abi.encodeWithSelector(
                handlers[subscriber][msg.sender][topic],
                msg.sender,
                topic,
                data
            );
            (bool successed, ) = subscriber.call(_data);
            require(successed, "Broker.publish.EID00020");
        }
    }

    function subscribers(address publisher, bytes32 topic)
        external
        view
        returns (address[] memory)
    {
        address[] memory values = new address[](
            _subscribers[publisher][topic].length()
        );
        for (uint256 i = 0; i < values.length; ++i) {
            values[i] = _subscribers[publisher][topic].at(i);
        }
        return values;
    }
}