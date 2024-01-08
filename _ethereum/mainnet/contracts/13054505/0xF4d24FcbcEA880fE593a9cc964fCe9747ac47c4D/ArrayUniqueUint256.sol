// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract ArrayUniqueUint256 {
    // array of value
    uint256[] _array;

    // value to indice (start from 1)
    mapping(uint256 => uint256) public mapValueToIndex;

    function add(uint256 _val) public returns (uint256) {
        require(mapValueToIndex[_val] == 0, "Value is existed.");

        // add to array
        _array.push(_val);

        // store index into map
        // index number start from 1
        uint256 _index = _array.length;
        mapValueToIndex[_val] = _index;

        // return length of array
        return _array.length;
    }

    function deleteByValue(uint256 _val) public returns (uint256) {
        require(mapValueToIndex[_val] > 0, "Value does not existed.");
        uint256 _index = mapValueToIndex[_val];

        // index number start from 1
        require((_index - 1) < _array.length);

        // swap
        if (_index != _array.length) {
            // swap last to index
            _array[(_index - 1)] = _array[_array.length - 1];
            // update map
            mapValueToIndex[_array[(_index - 1)]] = _index;
        }
        // remove last
        _array.pop();

        // remove from map
        delete mapValueToIndex[_val];

        // return length of array
        return _array.length;
    }

    function containValue(uint256 _val) public view returns (bool) {
        return (mapValueToIndex[_val] > 0);
    }

    function length() public view returns (uint256) {
        return _array.length;
    }

    function get(uint256 i) public view returns (uint256) {
        return _array[i];
    }

    function toArray() public view returns (uint256[] memory) {
        return _array;
    }
}
