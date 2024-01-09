// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./SafeCast.sol";

interface Token {
    function balanceOf(address owner) external view returns (uint balance);
}

interface Token1155 {
    function balanceOf(address owner, uint256 id) external view returns (uint balance);
}

library CryptoCocksWhitelistingLib {
    uint8 private constant MAX_PERC_ROYALTIES = 20;

    /**
     * Whitelisted community contract
     */
    struct ListContract {
        bool erc1155; // true if contract implements IERC11555 otherwise IERC20/IERC721
        uint8 id; // unique identifier of a ListContract instance
        uint8 percRoyal; // percentage royal fee for each contract
        uint16 maxSupply; // max NFTs for whitelisted owners
        uint16 minBalance; // min balance needed on whitelisted contracts
        uint16 tracker; // tracking number of minted NFTs per whitelisted contract
        uint128 balance;  // tracking accumulated royalty fee
        uint256 erc1155Id; // erc1155 token type id
        address cc; // community contract addresses
        address wallet; // community wallet addresses
    }

    struct Set {
        // storage of ListContract instances
        ListContract[] _values;

        // position of a ListContract in the `values` array, plus 1 because index 0
        // means a ListContract is not in the set.
        mapping(uint8 => uint8) _indexes;
    }

    struct Whitelist {
        uint8 usedRoyal; // available royal for community wallets (in percentage points)
        Set lists;
    }

    /**
     * @dev Add a ListContract to the set. O(1).
     *
     * Returns true if the ListContract was added to the set, that is if it was not
     * already present.
     */
    function add(Whitelist storage self, ListContract memory lc) private returns (bool) {
        if (!contains(self, lc.id)) {
            self.lists._values.push(lc);
            self.lists._indexes[lc.id] = SafeCast.toUint8(self.lists._values.length);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a ListContract by id. O(1).
     *
     * Returns true if the ListContract was removed from the set, that is if it was
     * present.
     */
    function remove(Whitelist storage self, uint8 lcId) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint8 listContractIndex = self.lists._indexes[lcId];

        if (listContractIndex != 0) {
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array.

            uint8 toDeleteIndex = listContractIndex - 1;
            uint8 lastIndex = SafeCast.toUint8(self.lists._values.length - 1);

            if (lastIndex != toDeleteIndex) {
                ListContract storage lastListContract = self.lists._values[lastIndex];

                // Move the last ListContract to the index where the value to delete is
                self.lists._values[toDeleteIndex] = lastListContract;
                // Update the index for the moved ListContract
                self.lists._indexes[lastListContract.id] = listContractIndex; // Replace lastListContract's index to listContractIndex
            }

            // Delete the slot where the moved ListContract was stored
            self.lists._values.pop();

            // Delete the index for the deleted slot
            delete self.lists._indexes[lcId];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the ListContract with an identifier is already in the set. O(1).
     */
    function contains(Whitelist storage self, uint8 id) private view returns (bool) {
        return self.lists._indexes[id] != 0;
    }

    /**
     * @dev Returns the number of ListContract instances on the set. O(1).
     */
    function length(Whitelist storage self) private view returns (uint8) {
        return SafeCast.toUint8(self.lists._values.length);
    }

    /**
     * @dev Returns the ListContract stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of instances inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     * - `index` must be strictly less than {length}.
     */
    function at(Whitelist storage self, uint8 index) private view returns (ListContract storage) {
        return self.lists._values[index];
    }

    /**
     * Check token balance of address on an ERC721, ERC20 or ERC1155 contract
     */
    function queryBalance(Whitelist storage self, uint8 listIndex, address addressToQuery) public view returns (uint) {
        ListContract storage lc = at(self, listIndex);
        // slither-disable-next-line calls-loop
        return lc.erc1155 ? Token1155(lc.cc).balanceOf(addressToQuery, lc.erc1155Id) : Token(lc.cc).balanceOf(addressToQuery);
    }

    function increaseSupply(Whitelist storage self, uint8 idx) external {
        ListContract storage lc = at(self, idx);
        lc.tracker += 1;
    }

    function depositRoyalties(Whitelist storage self, uint128 value) external {
        for (uint8 idx = 0; (idx < length(self)); idx++) {
            ListContract storage lc = at(self, idx);
            lc.balance += uint128((value * lc.percRoyal) / 100);
        }
    }

    function checkListed(Whitelist storage self, address account) external view returns (bool, uint8) {
        for (uint8 i = 0; (i < length(self)); i++) {
            ListContract storage lc = at(self, i);
            if ((queryBalance(self, i, account) >= lc.minBalance) && (lc.maxSupply > lc.tracker)) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    /**
     * Add contract address to whitelisting with maxSupply
     * Allows token holders to mint NFTs before the Public Sale start
     */
    function addContract(
        Whitelist storage self,
        uint8 id,
        bool erc1155,
        address cc,
        address payable wallet,
        uint16 maxSupply,
        uint16 minBalance,
        uint8 percRoyal,
        uint erc1155Id
    ) public {
        require((MAX_PERC_ROYALTIES - self.usedRoyal) >= percRoyal, "FEE_TOO_HIGH");
        add(self, ListContract(erc1155, id, percRoyal, maxSupply, minBalance, 0, 0, erc1155Id, cc, wallet));
        self.usedRoyal += percRoyal;
    }

    function getListContract(Whitelist storage self, uint8 lcId) public view returns (ListContract storage lc) {
        if (contains(self, lcId)) {
            uint8 idx = self.lists._indexes[lcId] - 1;
            return at(self, idx);
        }
        revert("LC_NOT_FOUND");
    }

    function removeContract(Whitelist storage self, uint8 lcId) public {
        ListContract storage lc = getListContract(self, lcId);
        self.usedRoyal -= lc.percRoyal;
        remove(self, lcId);
    }

    function popRoyalties(Whitelist storage self, address wallet) external returns(uint128 balance) {
        for (uint8 i = 0; (i < length(self)); i++) {
            ListContract storage lc = at(self, i);
            if (lc.wallet == wallet) {
                uint128 lcBalance = lc.balance;
                lc.balance = 0;
                return lcBalance;
            }
        }
        revert("NO_COMMUNITY_WALLET");
    }
}
