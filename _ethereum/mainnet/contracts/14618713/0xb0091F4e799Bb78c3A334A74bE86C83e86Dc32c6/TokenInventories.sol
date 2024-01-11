// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev A subscription-based inventory system that can be used as a middle layer between owners and tokens.
 * There may be MAX_SUPPLY + 1 inventory owners in total, as the zero-address owns the first inventory.
 * Inventory IDs are packed together with inventory balances to save storage.
 * Implementation inspired by Azuki's batch-minting technique.
 */
contract TokenInventories {
    uint256 constant MAX_SUPPLY = 10101;
    uint256 constant MAX_SUPPLY_EQ = MAX_SUPPLY + 1;

    uint16[] private _vacantInventories;
    address[] private _inventoryToOwner;
    mapping(address => uint256) private _ownerToInventory;

    constructor() {
        _inventoryToOwner.push(address(0));
    }

    function _getInventoryOwner(uint256 inventory)
        internal
        view
        returns (address)
    {
        return _inventoryToOwner[inventory];
    }

    function _getInventoryId(address owner) internal view returns (uint256) {
        return _ownerToInventory[owner] & 0xFFFF;
    }

    function _getBalance(address owner) internal view returns (uint256) {
        return _ownerToInventory[owner] >> 16;
    }

    function _setBalance(address owner, uint256 balance) internal {
        _ownerToInventory[owner] = _getInventoryId(owner) | (balance << 16);
    }

    function _increaseBalance(address owner, uint256 count) internal {
        unchecked {
            _setBalance(owner, _getBalance(owner) + count);
        }
    }

    /**
     * @dev Decreases an owner's inventory balance and unsubscribes from the inventory when it's empty.
     * @param count must be equal to owner's balance at the most
     */
    function _decreaseBalance(address owner, uint256 count) internal {
        uint256 balance = _getBalance(owner);
        
        if (balance == count) {
            _unsubscribeInventory(owner);
        } else {
            unchecked {
                _setBalance(owner, balance - count);
            }
        }
    }

    /**
     * @dev Returns an owner's inventory ID. If the owner doesn't have an inventory they are assigned a
     * vacant one.
     */
    function _getOrSubscribeInventory(address owner)
        internal
        returns (uint256)
    {
        uint256 id = _getInventoryId(owner);
        return id == 0 ? _subscribeInventory(owner) : id;
    }

    /**
     * @dev Subscribes an owner to a vacant inventory and returns its ID.
     * The inventory list's length has to be MAX_SUPPLY + 1 before inventories from the vacant inventories
     * list are assigned.
     */
    function _subscribeInventory(address owner) private returns (uint256) {
        if (_inventoryToOwner.length < MAX_SUPPLY_EQ) {
            _ownerToInventory[owner] = _inventoryToOwner.length;
            _inventoryToOwner.push(owner);
        } else if (_vacantInventories.length > 0) {
            unchecked {
                uint256 id = _vacantInventories[_vacantInventories.length - 1];
                _vacantInventories.pop();
                _ownerToInventory[owner] = id;
                _inventoryToOwner[id] = owner;
            }
        }
        return _ownerToInventory[owner];
    }

    /**
     * @dev Unsubscribes an owner from their inventory and updates the vacant inventories list.
     */
    function _unsubscribeInventory(address owner) private {
        uint256 id = _getInventoryId(owner);
        delete _ownerToInventory[owner];
        delete _inventoryToOwner[id];
        _vacantInventories.push(uint16(id));
    }
}
