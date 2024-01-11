// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IOneWarGold {
    function mint(address _to, uint256 _value) external;

    function burn(address _from, uint256 _value) external;
}
