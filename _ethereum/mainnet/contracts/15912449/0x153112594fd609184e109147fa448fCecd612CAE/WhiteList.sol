// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import "./Vendor.sol";
import "./IOwner.sol";
import "./IWhiteList.sol";

contract WhiteList is IWhiteList {
    mapping(address => mapping(address => WhiteListItem)) public whiteListItems;
    mapping(address => bool) public whiteListOpen;
    mapping(address => bool) public allOpen;
    mapping(address => address[]) public idList;

    function getCollectionWhiteListAddress(address token)
        external
        view
        override
        returns (address[] memory)
    {
        return idList[token];
    }

    function getCollectionWhiteList(address token)
        external
        view
        override
        returns (WhiteListItem[] memory)
    {
        address[] memory _idList = idList[token];
        WhiteListItem[] memory list = new WhiteListItem[](_idList.length);
        for (uint256 i = 0; i < _idList.length; i++) {
            list[i] = whiteListItems[token][_idList[i]];
        }
        return list;
    }

    function getCollectionAllOpen(address token)
        external
        view
        override
        returns (bool)
    {
        return allOpen[token];
    }

    function getCollectionWhiteListOpen(address token)
        external
        view
        override
        returns (bool)
    {
        return whiteListOpen[token];
    }

    function getCollectionWhiteListItem(address token, address addr)
        external
        view
        override
        returns (WhiteListItem memory)
    {
        return whiteListItems[token][addr];
    }

    function setWhiteList(
        address token,
        address[] calldata addressArray,
        uint256[] calldata priceArray,
        uint256[] calldata limitArray
    ) external override {
        _setWhiteList(token, addressArray, priceArray, limitArray);
    }

    function _setWhiteList(
        address token,
        address[] memory addressArray,
        uint256[] memory priceArray,
        uint256[] memory limitArray
    ) internal {
        require(owner(token) == msg.sender, "Only owner can set");
        idList[token] = addressArray;
        for (uint256 i; i < addressArray.length; i++) {
            WhiteListItem storage item = whiteListItems[token][addressArray[i]];
            item.price = priceArray[i];
            item.addr = addressArray[i];
            item.limit = limitArray[i];
        }
    }

    function setCollectionWhiteListOpen(address token, bool open)
        external
        override
    {
        require(owner(token) == msg.sender, "Only owner can set");
        whiteListOpen[token] = open;
    }

    function setCollectionAllOpen(address token, bool open) external override {
        require(owner(token) == msg.sender, "Only owner can set");
        allOpen[token] = open;
    }

    function addWhiteListUsedCount(
        address token,
        address addr
    ) external override returns(uint256){
        require(owner(token) == msg.sender, "Only owner can set");
        WhiteListItem storage item = whiteListItems[token][addr];
        if(
                this.getCollectionWhiteListOpen(token) &&
                item.price != 0 &&
                item.usedCount < item.limit
        ){
            item.usedCount += 1;
            return item.price;
        }
        return 0;
    }

    function owner(address token) internal view returns (address owner_) {
        owner_ = IOwner(address(token)).owner();
    }

    function isOpen(address token, address addr)
        external
        view
        override
        returns (bool)
    {
        return
            this.getCollectionAllOpen(token) ||
            (this.getCollectionWhiteListOpen(token) &&
                this.getCollectionWhiteListItem(token, addr).price != 0);
    }

    function whiteListPrice(address token, address addr) external override view returns(uint256) {
        WhiteListItem memory item = whiteListItems[token][addr];
        if(
                whiteListOpen[token]
                && item.price != 0
                && item.usedCount < item.limit)
                return item.price;
        return 0;
    }
}
