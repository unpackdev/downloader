//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

/**
    @notice Utility library of inline functions on the address arrays.
 */
library AddressesLib {
    /**
      @notice It adds an address value to the array.
      @param self current array.
      @param newItem new item to add.
    */
    function add(address[] storage self, address newItem) internal {
        require(newItem != address(0x0), "EMPTY_ADDRESS_NOT_ALLOWED");
        self.push(newItem);
    }

    /**
      @notice It removes the value at the given index in an array.
      @param self the current array.
      @param index remove an item in a specific index.
    */
    function removeAt(address[] storage self, uint256 index) internal {
        if (index >= self.length) return;

        if (index != self.length - 1) {
            address temp = self[self.length - 1];
            self[index] = temp;
        }

        delete self[self.length - 1];
        self.pop();
    }

    /**
      @notice It gets the index for a given item.
      @param self the current array.
      @param item to get the index.
      @return found true if the item was found. Otherwise it returns false. indexAt the current index for a given item.
    */
    function getIndex(address[] storage self, address item)
        internal
        view
        returns (bool found, uint256 indexAt)
    {
        for (indexAt = 0; indexAt < self.length; indexAt++) {
            found = self[indexAt] == item;
            if (found) {
                return (found, indexAt);
            }
        }
        return (found, indexAt);
    }

    /**
      @notice It removes an address value from the array.
      @param self the current array.
      @param item the item to remove.
    */
    function remove(address[] storage self, address item) internal {
        (bool found, uint256 indexAt) = getIndex(self, item);
        if (!found) return;

        removeAt(self, indexAt);
    }
}
