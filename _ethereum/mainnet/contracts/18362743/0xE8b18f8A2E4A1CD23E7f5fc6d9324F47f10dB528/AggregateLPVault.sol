// SPDX-License-Identifier: GPL-3.0-or-later
// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File libraries/ScaledMath.sol

pragma solidity ^0.8.17;

library ScaledMath {
    uint256 internal constant ONE = 1e18;

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / ONE;
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * ONE) / b;
    }

    function changeScale(
        uint256 a,
        uint256 from,
        uint256 to
    ) internal pure returns (uint256) {
        if (from == to) return a;
        else if (from < to) return a * 10 ** (to - from);
        else return a / 10 ** (from - to);
    }
}


// File libraries/VotingPowerHistory.sol

pragma solidity ^0.8.17;

library VotingPowerHistory {
    using VotingPowerHistory for History;
    using VotingPowerHistory for Record;
    using ScaledMath for uint256;

    struct Record {
        uint256 at;
        uint256 baseVotingPower;
        uint256 multiplier;
        int256 netDelegatedVotes;
    }

    function zeroRecord() internal pure returns (Record memory) {
        return
            Record({
                at: 0,
                baseVotingPower: 0,
                multiplier: ScaledMath.ONE,
                netDelegatedVotes: 0
            });
    }

    function total(Record memory record) internal pure returns (uint256) {
        return
            uint256(
                int256(record.baseVotingPower.mulDown(record.multiplier)) +
                    record.netDelegatedVotes
            );
    }

    struct History {
        mapping(address => Record[]) votes;
        mapping(address => mapping(address => uint256)) _delegations;
        mapping(address => uint256) _delegatedToOthers;
        mapping(address => uint256) _delegatedToSelf;
    }

    event VotesDelegated(address from, address to, uint256 amount);
    event VotesUndelegated(address from, address to, uint256 amount);

    function updateVotingPower(
        History storage history,
        address for_,
        uint256 baseVotingPower,
        uint256 multiplier,
        int256 netDelegatedVotes
    ) internal returns (Record memory) {
        Record[] storage votesFor = history.votes[for_];
        Record memory updatedRecord = Record({
            at: block.timestamp,
            baseVotingPower: baseVotingPower,
            multiplier: multiplier,
            netDelegatedVotes: netDelegatedVotes
        });
        Record memory lastRecord = history.currentRecord(for_);
        if (lastRecord.at == block.timestamp && votesFor.length > 0) {
            votesFor[votesFor.length - 1] = updatedRecord;
        } else {
            history.votes[for_].push(updatedRecord);
        }
        return updatedRecord;
    }

    function getVotingPower(
        History storage history,
        address for_,
        uint256 at
    ) internal view returns (uint256) {
        (, Record memory record) = binarySearch(history.votes[for_], at);
        return record.total();
    }

    function currentRecord(
        History storage history,
        address for_
    ) internal view returns (Record memory) {
        Record[] memory records = history.votes[for_];
        if (records.length == 0) {
            return zeroRecord();
        } else {
            return records[records.length - 1];
        }
    }

    function binarySearch(
        Record[] memory records,
        uint256 at
    ) internal view returns (bool found, Record memory) {
        return _binarySearch(records, at, 0, records.length);
    }

    function _binarySearch(
        Record[] memory records,
        uint256 at,
        uint256 startIdx,
        uint256 endIdx
    ) internal view returns (bool found, Record memory) {
        if (startIdx >= endIdx) {
            return (false, zeroRecord());
        }

        if (endIdx - startIdx == 1) {
            Record memory rec = records[startIdx];
            return rec.at <= at ? (true, rec) : (false, zeroRecord());
        }

        uint256 midIdx = (endIdx + startIdx) / 2;
        Record memory lowerBound = records[midIdx - 1];
        Record memory upperBound = records[midIdx];
        if (lowerBound.at <= at && at < upperBound.at) {
            return (true, lowerBound);
        } else if (upperBound.at <= at) {
            return _binarySearch(records, at, midIdx, endIdx);
        } else {
            return _binarySearch(records, at, startIdx, midIdx);
        }
    }

    function delegateVote(
        History storage history,
        address from,
        address to,
        uint256 amount
    ) internal {
        Record memory fromCurrent = history.currentRecord(from);

        uint256 availableToDelegate = fromCurrent.baseVotingPower.mulDown(
            fromCurrent.multiplier
        ) - history._delegatedToOthers[from];
        require(
            availableToDelegate >= amount,
            "insufficient balance to delegate"
        );

        history._delegatedToSelf[to] += amount;
        history._delegatedToOthers[from] += amount;
        history._delegations[from][to] += amount;

        history.updateVotingPower(
            from,
            fromCurrent.baseVotingPower,
            fromCurrent.multiplier,
            history.netDelegatedVotingPower(from)
        );
        Record memory toCurrent = history.currentRecord(to);
        history.updateVotingPower(
            to,
            toCurrent.baseVotingPower,
            toCurrent.multiplier,
            history.netDelegatedVotingPower(to)
        );

        emit VotesDelegated(from, to, amount);
    }

    function undelegateVote(
        History storage history,
        address from,
        address to,
        uint256 amount
    ) internal {
        require(
            history._delegations[from][to] >= amount,
            "user has not delegated enough to delegate"
        );

        history._delegatedToSelf[to] -= amount;
        history._delegatedToOthers[from] -= amount;
        history._delegations[from][to] -= amount;

        Record memory fromCurrent = history.currentRecord(from);
        history.updateVotingPower(
            from,
            fromCurrent.baseVotingPower,
            fromCurrent.multiplier,
            history.netDelegatedVotingPower(from)
        );
        Record memory toCurrent = history.currentRecord(to);
        history.updateVotingPower(
            to,
            toCurrent.baseVotingPower,
            toCurrent.multiplier,
            history.netDelegatedVotingPower(to)
        );

        emit VotesUndelegated(from, to, amount);
    }

    function netDelegatedVotingPower(
        History storage history,
        address who
    ) internal view returns (int256) {
        return
            int256(history._delegatedToSelf[who]) -
            int256(history._delegatedToOthers[who]);
    }

    function delegatedVotingPower(
        History storage history,
        address who
    ) internal view returns (uint256) {
        return history._delegatedToOthers[who];
    }

    function updateMultiplier(
        History storage history,
        address who,
        uint256 multiplier
    ) internal {
        Record memory current = history.currentRecord(who);
        require(current.multiplier <= multiplier, "cannot decrease multiplier");
        history.updateVotingPower(
            who,
            current.baseVotingPower,
            multiplier,
            current.netDelegatedVotes
        );
    }
}


// File interfaces/IVault.sol

pragma solidity ^0.8.17;

interface IVault {
    function getRawVotingPower(address account) external view returns (uint256);

    function getCurrentRecord(
        address account
    ) external view returns (VotingPowerHistory.Record memory);

    function getRawVotingPower(
        address account,
        uint256 timestamp
    ) external view returns (uint256);

    function getTotalRawVotingPower() external view returns (uint256);

    function getVaultType() external view returns (string memory);
}


// File libraries/Errors.sol

pragma solidity ^0.8.17;

library Errors {
    error DuplicatedVault(address vault);
    error InvalidTotalWeight(uint256 totalWeight);
    error NotAuthorized(address actual, address expected);
    error InvalidVotingPowerUpdate(
        uint256 actualTotalPower,
        uint256 givenTotalPower
    );
    error MultisigSunset();

    error ZeroDivision();
}


// File contracts/access/ImmutableOwner.sol

pragma solidity ^0.8.17;

contract ImmutableOwner {
    address public immutable owner;

    modifier onlyOwner() {
        if (msg.sender != owner) revert Errors.NotAuthorized(msg.sender, owner);
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }
}


// File interfaces/IVaultWithThreshold.sol

pragma solidity ^0.8.17;

interface IVaultWithThreshold {
    event ThresholdSet(uint256 threshold);

    function threshold() external view returns (uint256);

    function setThreshold(uint256 threshold) external;
}


// File contracts/vaults/VaultWithThreshold.sol

pragma solidity ^0.8.17;

contract VaultWithThreshold is IVaultWithThreshold {
    uint256 public override threshold;

    function setThreshold(uint256 _threshold) external {
        threshold = _threshold;
        emit ThresholdSet(_threshold);
    }
}


// File @openzeppelin/contracts/utils/structs/EnumerableSet.sol@v4.8.0

// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}


// File @openzeppelin/contracts/utils/structs/EnumerableMap.sol@v4.8.0

// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}


// File libraries/DataTypes.sol

pragma solidity ^0.8.17;

library DataTypes {
    enum Status {
        Undefined,
        Active,
        Rejected,
        Queued,
        Executed,
        Vetoed
    }

    struct ProposalAction {
        address target;
        bytes data;
    }

    struct Proposal {
        uint64 createdAt;
        uint64 executableAt;
        uint64 votingEndsAt;
        uint64 voteThreshold;
        uint64 quorum;
        uint16 id;
        uint8 actionLevel;
        address proposer;
        Status status;
        ProposalAction[] actions;
    }

    struct PendingWithdrawal {
        uint256 id;
        uint256 withdrawableAt;
        uint256 amount;
        address to;
        address delegate;
    }

    struct VaultWeightSchedule {
        VaultWeightConfiguration[] vaults;
        uint256 startsAt;
        uint256 endsAt;
    }

    struct VaultWeightConfiguration {
        address vaultAddress;
        uint256 initialWeight;
        uint256 targetWeight;
    }

    struct VaultWeight {
        address vaultAddress;
        uint256 currentWeight;
        uint256 initialWeight;
        uint256 targetWeight;
    }

    struct VaultVotingPower {
        address vaultAddress;
        uint256 votingPower;
    }

    struct Tier {
        uint64 quorum;
        uint64 proposalThreshold;
        uint64 voteThreshold;
        uint32 timeLockDuration;
        uint32 proposalLength;
        uint8 actionLevel;
    }

    struct EmergencyRecoveryProposal {
        uint64 createdAt;
        uint64 completesAt;
        Status status;
        bytes payload;
        EnumerableMap.AddressToUintMap vetos;
    }

    enum Ballot {
        Undefined,
        For,
        Against,
        Abstain
    }

    struct VoteTotals {
        VaultVotingPower[] _for;
        VaultVotingPower[] against;
        VaultVotingPower[] abstentions;
    }

    struct VaultSnapshot {
        address vaultAddress;
        uint256 weight;
        uint256 totalVotingPower;
    }

    enum ProposalOutcome {
        Undefined,
        QuorumNotMet,
        ThresholdNotMet,
        Successful
    }

    struct LimitUpgradeabilityParameters {
        uint8 actionLevelThreshold;
        uint256 emaThreshold;
        uint256 minBGYDSupply;
        address tierStrategy;
    }

    struct Delegation {
        address delegate;
        uint256 amount;
    }
}


// File contracts/vaults/BaseVault.sol

pragma solidity ^0.8.17;



abstract contract BaseVault is IVault {
    using VotingPowerHistory for VotingPowerHistory.History;

    VotingPowerHistory.History internal history;

    function getCurrentRecord(
        address account
    ) external view returns (VotingPowerHistory.Record memory) {
        return history.currentRecord(account);
    }

    function getRawVotingPower(
        address account
    ) external view returns (uint256) {
        return getRawVotingPower(account, block.timestamp);
    }

    function getRawVotingPower(
        address account,
        uint256 timestamp
    ) public view virtual returns (uint256);
}


// File contracts/vaults/AggregateLPVault.sol

pragma solidity ^0.8.17;





contract AggregateLPVault is BaseVault, VaultWithThreshold, ImmutableOwner {
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using ScaledMath for uint256;

    string internal constant _VAULT_TYPE = "AggregateLP";

    struct VaultWeight {
        address vaultAddress;
        uint256 weight;
    }

    EnumerableMap.AddressToUintMap internal vaultsToWeights;

    constructor(
        address _owner,
        uint256 _threshold,
        VaultWeight[] memory vaultWeights
    ) ImmutableOwner(_owner) {
        threshold = _threshold;
        _setVaultWeights(vaultWeights);
    }

    function setVaultWeights(
        VaultWeight[] calldata vaultWeights
    ) external onlyOwner {
        _removeAllVaultWeights();
        _setVaultWeights(vaultWeights);
    }

    function getVaultWeights() external view returns (VaultWeight[] memory) {
        uint256 length = vaultsToWeights.length();
        VaultWeight[] memory vaultWeights = new VaultWeight[](length);

        for (uint256 i = 0; i < length; i++) {
            (address vault, uint256 weight) = vaultsToWeights.at(i);
            vaultWeights[i] = VaultWeight(vault, weight);
        }

        return vaultWeights;
    }

    function _removeAllVaultWeights() internal {
        uint256 length = vaultsToWeights.length();
        for (uint256 i = 0; i < length; i++) {
            (address key, ) = vaultsToWeights.at(0);
            vaultsToWeights.remove(key);
        }
    }

    function getRawVotingPower(
        address _user,
        uint256 timestamp
    ) public view override returns (uint256) {
        uint256 rawVotingPower = 0;
        for (uint256 i = 0; i < vaultsToWeights.length(); i++) {
            (address vault, uint256 weight) = vaultsToWeights.at(i);
            rawVotingPower += IVault(vault)
                .getRawVotingPower(_user, timestamp)
                .mulDown(weight);
        }

        return rawVotingPower;
    }

    function getTotalRawVotingPower() public view override returns (uint256) {
        uint256 totalRawVotingPower = 0;
        for (uint256 i = 0; i < vaultsToWeights.length(); i++) {
            (address vault, uint256 weight) = vaultsToWeights.at(i);
            totalRawVotingPower += IVault(vault)
                .getTotalRawVotingPower()
                .mulDown(weight);
        }

        if (totalRawVotingPower <= threshold) {
            totalRawVotingPower = threshold;
        }

        return totalRawVotingPower;
    }

    function getVaultType() external pure returns (string memory) {
        return _VAULT_TYPE;
    }

    function _setVaultWeights(VaultWeight[] memory vaultWeights) internal {
        for (uint256 i; i < vaultWeights.length; i++) {
            VaultWeight memory v = vaultWeights[i];
            require(v.weight > 0, "cannot have a 0 weight");
            vaultsToWeights.set(v.vaultAddress, v.weight);
        }
    }
}