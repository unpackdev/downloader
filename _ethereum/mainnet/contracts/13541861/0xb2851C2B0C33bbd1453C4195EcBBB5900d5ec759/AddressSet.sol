// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

contract AddressSet {
    struct Set {
        address[] addresses;
        mapping(address => uint256) positions;
        uint256 count;
    }
    mapping(bytes32 => Set) private sets;

    function addAddressToSet(
        bytes32 key,
        address addr,
        bool maintainList
    ) internal {
        Set storage set = sets[key];
        require(set.positions[addr] == 0, "ALREADY_IN_SET");

        if (maintainList) {
            require(
                set.addresses.length == set.count,
                "PREVIOUSLY_NOT_MAINTAILED"
            );
            set.addresses.push(addr);
        } else {
            require(set.addresses.length == 0, "MUST_MAINTAIN");
        }

        set.count += 1;
        set.positions[addr] = set.count;
    }

    function removeAddressFromSet(bytes32 key, address addr) internal {
        Set storage set = sets[key];
        uint256 pos = set.positions[addr];
        require(pos != 0, "NOT_IN_SET");

        delete set.positions[addr];
        set.count -= 1;

        if (set.addresses.length > 0) {
            address lastAddr = set.addresses[set.count];
            if (lastAddr != addr) {
                set.addresses[pos - 1] = lastAddr;
                set.positions[lastAddr] = pos;
            }
            set.addresses.pop();
        }
    }

    function isAddressInSet(bytes32 key, address addr)
        internal
        view
        returns (bool)
    {
        return sets[key].positions[addr] != 0;
    }

    function numAddressesInSet(bytes32 key) internal view returns (uint256) {
        Set storage set = sets[key];
        return set.count;
    }

    function addressesInSet(bytes32 key)
        internal
        view
        returns (address[] memory)
    {
        Set storage set = sets[key];
        require(set.count == set.addresses.length, "NOT_MAINTAINED");
        return sets[key].addresses;
    }
}
