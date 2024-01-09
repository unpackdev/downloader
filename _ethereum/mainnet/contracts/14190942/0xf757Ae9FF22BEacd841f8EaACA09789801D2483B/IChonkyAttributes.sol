// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IChonkyAttributes {
    enum AttributeType {
        NONE,
        BRAIN,
        CUTE,
        POWER,
        WICKED
    }

    function getAttributeValues(uint256[12] memory _attributes, uint256 _setId)
        external
        pure
        returns (uint256[4] memory result);
}
