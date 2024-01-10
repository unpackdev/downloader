// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AdminController.sol";

/**
 * @dev SafeListItem Provides SafeList Guard functionality using onlySafeListed
 * Where safe listed wallets can purchase a set amount of tokens
 */

struct Props {
    address[] safeList;
    uint256 maxPurchaseAmount;
}

abstract contract SafeListController is AdminController {
    struct SafeListItem {
        /// @dev how many tokens the address have purchased
        uint256 purchased;
        /// @dev is the address safe listed
        bool isSafe;
    }

    /// @dev the list of addresses who are safe listed
    address[] public safeList;
    /// @dev a map of safe wallets, mapping safeAddress => (purchased, isSafe)
    mapping(address => SafeListItem) public safeListMap;
    /// @dev max amount to purchase per safe address
    uint256 public maxPurchaseAmount;

    constructor(Props memory props) {
        maxPurchaseAmount = props.maxPurchaseAmount;
        uint256 safeListLength = props.safeList.length;
        for (uint256 i = 0; i < safeListLength; i++) {
            address addr = props.safeList[i];
            safeList.push(addr);
            safeListMap[addr] = SafeListItem({isSafe: true, purchased: 0});
        }
    }

    function getSafeListLength() public view returns (uint256) {
        return safeList.length;
    }

    /// @dev set a new max purchase amount
    function setMaxPurchaseAmount(uint256 _maxPurchaseAmount) public onlyAdmin {
        maxPurchaseAmount = _maxPurchaseAmount;
    }

    /// @dev makes sure the user is safe listed and can purchase
    modifier onlySafeListed() {
        SafeListItem memory item = safeListMap[msg.sender];
        require(item.isSafe, "not safe listed");
        require(item.purchased < maxPurchaseAmount, "already purchased");
        _;
    }

    /// @dev checks if the current address is allowed to purchase
    function isAddressSafeListed(address addr) public view returns (bool) {
        SafeListItem memory item = safeListMap[addr];
        return item.isSafe && item.purchased < maxPurchaseAmount;
    }

    /// @dev add new address to the safe list
    function addToSafeList(address addr) public onlyAdmin {
        safeList.push(addr);
        safeListMap[addr] = SafeListItem(0, true);
    }

    /// @dev add new addresses to the safe list
    function addManyToSafeList(address[] calldata addrs) public onlyAdmin {
        uint256 arrayLength = addrs.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            addToSafeList(addrs[i]);
        }
    }

    /// @dev remove an address from the safe list
    function removeFromSafeList(address addr) public onlyAdmin {
        delete safeListMap[addr];
        uint256 length = safeList.length;
        for (uint256 i = 0; i < length; i++) {
            if (safeList[i] == addr) {
                delete safeList[i];
                break;
            }
        }
    }

    /// @dev remove many addresses from the safe list
    function removeManyFromSafeList(address[] calldata addrs) public onlyAdmin {
        uint256 length = addrs.length;
        for (uint256 i = 0; i < length; i++) {
            removeFromSafeList(addrs[i]);
        }
    }

    /// @dev replaces the safe list with a new safe list
    function replaceSafeList(address[] calldata newSafeList) public onlyAdmin {
        uint256 length = safeList.length;
        for (uint256 i = 0; i < length; i++) {
            address addr = safeList[i];
            delete safeListMap[addr];
        }
        delete safeList;
        addManyToSafeList(newSafeList);
    }

    /// @dev increase the purchased count of the current wallet
    function _incrementAddressPurchasedCount(uint256 inc) internal virtual {
        safeListMap[msg.sender].purchased += inc;
    }
}
