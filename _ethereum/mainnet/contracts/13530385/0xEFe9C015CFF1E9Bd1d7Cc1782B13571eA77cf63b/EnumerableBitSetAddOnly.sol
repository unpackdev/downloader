
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library EnumerableBitSetAddOnly {

    struct Set {
        mapping(uint16 => uint8) _bitMap;
        uint16[] _ordered;
    }

    function _contains(Set storage set, uint16 _position) internal view returns (bool result) {
        uint16 byteNum = uint16(_position / 8);
        uint16 bitPos = uint8(_position - byteNum * 8);
        if (set._bitMap[byteNum] == 0) return false;
        return set._bitMap[byteNum] & (0x01 * 2**bitPos) != 0;
    }

    function _add(Set storage set, uint16 _position) private returns (bool) {
        if (!_contains(set, _position)) {

            uint16 byteNum = uint16(_position / 8);
            uint16 bitPos = uint8(_position - byteNum * 8);
            set._bitMap[byteNum] = uint8(set._bitMap[byteNum] | (2**bitPos));
            set._ordered.push(_position);

            return true;
        } else {
            return false;
        }
    }

    function _getUsed(Set storage set, uint8 _page, uint16 _perPage) internal view returns (uint8[] memory values) {
        _perPage = _perPage / 8;
        uint16 i = _perPage * _page;
        uint16 max = i + (_perPage);
        uint16 j = 0;
        uint8[] memory retValues = new uint8[](max);
        while (i < max) {
            retValues[j] = set._bitMap[i];
            j++;
            i++;
        }
        return retValues;
    }

    struct Uint16BitSet {
        Set _inner;
    }

    function add(Uint16BitSet storage set, uint16 _position) internal {
        _add(set._inner, _position);
    }

    function contains(Uint16BitSet storage set, uint16 _position) internal view returns (bool result) {
        return _contains(set._inner, _position);
    }

    function getUsed(Uint16BitSet storage set, uint8 _page, uint16 _perPage) internal view returns (uint8[] memory values) {
        return _getUsed(set._inner, _page, _perPage);
    }

    function getValues(Uint16BitSet storage set) internal view returns (uint16[] memory values) {
        return set._inner._ordered;
    }

    function getLength(Uint16BitSet storage set) internal view returns (uint256 length) {
        return set._inner._ordered.length;
    }
}