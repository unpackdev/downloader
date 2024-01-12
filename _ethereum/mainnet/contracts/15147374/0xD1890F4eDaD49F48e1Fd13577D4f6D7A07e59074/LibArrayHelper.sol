// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

library LibArrayHelper {
    function removeItemFromListBytes32(bytes32[] memory list, bytes32 item) public pure returns (bytes32[] memory) {
        uint8 index = 0;
        for (uint8 i = 0; i < list.length; i++) {
            if (list[i] == item) {
                index = i;
            }
        }
        bytes32[] memory newList = new bytes32[](list.length-1);
        for (uint8 j = 0; j < newList.length; j++) {
            if (j < index) {
                newList[j] = list[j];
            } else {
                newList[j] = list[j + 1];
            }
        }
        list = newList;
        return list;
    }

    function removeItemFromListUint256(uint256[] memory list, uint256 item) public pure returns (uint256[] memory) {
        uint8 index = 0;
        for (uint8 i = 0; i < list.length; i++) {
            if (list[i] == item) {
                index = i;
            }
        }
        uint256[] memory newList = new uint256[](list.length-1);
        for (uint8 j = 0; j < newList.length; j++) {
            if (j < index) {
                newList[j] = list[j];
            } else {
                newList[j] = list[j + 1];
            }
        }
        list = newList;
        return list;
    }

    function removeItemFromListAddress(address[] memory list, address item) public pure returns (address[] memory) {
        uint8 index = 0;
        for (uint8 i = 0; i < list.length; i++) {
            if (list[i] == item) {
                index = i;
            }
        }
        address[] memory newList = new address[](list.length-1);
        for (uint8 j = 0; j < newList.length; j++) {
            if (j < index) {
                newList[j] = list[j];
            } else {
                newList[j] = list[j + 1];
            }
        }
        list = newList;
        return list;
    }

    function existsAddress(address[] memory list, address item) public pure returns (bool existed) {
        for (uint8 i=0; i<list.length; i++) {
            if (list[i] == item) {
                existed = true;
            }
        }
    }

    function existsUint256(uint256[] memory list, uint256 item) public pure returns (bool existed) {
        for (uint8 i=0; i<list.length; i++) {
            if (list[i] == item) {
                existed = true;
            }
        }
    }
}