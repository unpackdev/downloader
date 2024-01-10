// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TotalSupply {
    uint256 private _totalSupply;

    function _setTotalSupply(uint256 __totalSupply) internal {
        _totalSupply = __totalSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    uint256[49] private __gap;
}