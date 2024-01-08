// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OrderedSet.sol";
import "./OrderedAddressSet.sol";

/**
 * @title RankedSet
 * @dev Ranked data structure using two ordered sets, a mapping of scores to
 * boundary values, a mapping of last ranked scores, and a highest score.
 */
library RankedAddressSet {
    using OrderedSet for OrderedSet.Set;
    using OrderedAddressSet for OrderedAddressSet.Set;

    struct RankGroup {
        uint256 count;
        address start;
        address end;
    }

    struct Set {
        uint256 highScore;
        mapping(uint256 => RankGroup) rankgroups;
        mapping(address => uint256) scores;
        OrderedSet.Set rankedScores;
        OrderedAddressSet.Set rankedItems;
    }

    /**
     * @dev Add an item at the end of the set
     */
    function add(Set storage set, address item) internal {
        set.rankedItems.append(item);
        set.rankgroups[0].end = item;
        set.rankgroups[0].count += 1;
        if (set.rankgroups[0].start == address(0)) {
            set.rankgroups[0].start = item;
        }
    }

    /**
     * @dev Remove an item
     */
    function remove(Set storage set, address item) internal {
        uint256 score = set.scores[item];
        delete set.scores[item];

        RankGroup storage rankgroup = set.rankgroups[score];
        if (rankgroup.count > 0) {
            rankgroup.count -= 1;
        }

        if (rankgroup.count == 0) {
            rankgroup.start = address(0);
            rankgroup.end = address(0);
            if (score == set.highScore) {
                set.highScore = set.rankedScores.next(score);
            }
            if (score > 0) {
                set.rankedScores.remove(score);
            }
        } else {
            if (rankgroup.start == item) {
                rankgroup.start = set.rankedItems.next(item);
            }
            if (rankgroup.end == item) {
                rankgroup.end = set.rankedItems.prev(item);
            }
        }

        set.rankedItems.remove(item);
    }

    /**
     * @dev Returns the head
     */
    function head(Set storage set) internal view returns (address) {
        return set.rankedItems._next[address(0)];
    }

    /**
     * @dev Returns the tail
     */
    function tail(Set storage set) internal view returns (address) {
        return set.rankedItems._prev[address(0)];
    }

    /**
     * @dev Returns the length
     */
    function length(Set storage set) internal view returns (uint256) {
        return set.rankedItems.count;
    }

    /**
     * @dev Returns the next value
     */
    function next(Set storage set, address _value) internal view returns (address) {
        return set.rankedItems._next[_value];
    }

    /**
     * @dev Returns the previous value
     */
    function prev(Set storage set, address _value) internal view returns (address) {
        return set.rankedItems._prev[_value];
    }

    /**
     * @dev Returns true if the value is in the set
     */
    function contains(Set storage set, address value) internal view returns (bool) {
        return set.rankedItems._next[address(0)] == value ||
               set.rankedItems._next[value] != address(0) ||
               set.rankedItems._prev[value] != address(0);
    }

    /**
     * @dev Returns a value's score
     */
    function scoreOf(Set storage set, address value) internal view returns (uint256) {
        return set.scores[value];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Set storage set) internal view returns (address[] memory) {
        address[] memory _values = new address[](set.rankedItems.count);
        address value = set.rankedItems._next[address(0)];
        uint256 i = 0;
        while (value != address(0)) {
            _values[i] = value;
            value = set.rankedItems._next[value];
            i += 1;
        }
        return _values;
    }

    /**
     * @dev Return an array with n values in the set, starting after "from"
     */
    function valuesFromN(Set storage set, address from, uint256 n) internal view returns (address[] memory) {
        address[] memory _values = new address[](n);
        address value = set.rankedItems._next[from];
        uint256 i = 0;
        while (i < n) {
            _values[i] = value;
            value = set.rankedItems._next[value];
            i += 1;
        }
        return _values;
    }

    /**
     * @dev Rank new score
     */
    function rankScore(Set storage set, address item, uint256 newScore) internal {
        RankGroup storage rankgroup = set.rankgroups[newScore];

        if (newScore > set.highScore) {
            remove(set, item);
            rankgroup.start = item;
            set.highScore = newScore;
            set.rankedItems.add(item);
            set.rankedScores.add(newScore);
        } else {
            uint256 score = set.scores[item];
            uint256 prevScore = set.rankedScores.prev(score);

            if (set.rankgroups[score].count == 1) {
                score = set.rankedScores.next(score);
            }

            remove(set, item);

            while (prevScore > 0 && newScore > prevScore) {
                prevScore = set.rankedScores.prev(prevScore);
            }

            set.rankedItems.insert(
                set.rankgroups[prevScore].end,
                item,
                set.rankgroups[set.rankedScores.next(prevScore)].start
            );

            if (rankgroup.count == 0) {
                set.rankedScores.insert(prevScore, newScore, score);
                rankgroup.start = item;
            }
        }

        rankgroup.end = item;
        rankgroup.count += 1;

        set.scores[item] = newScore;
    }
}
