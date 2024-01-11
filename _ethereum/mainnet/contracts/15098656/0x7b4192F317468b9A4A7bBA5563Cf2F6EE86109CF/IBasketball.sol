pragma solidity ^0.8.10;
// SPDX-License-Identifier: UNLICENSED

import "./IERC1155Upgradeable.sol";

interface IBasketball is IERC1155Upgradeable {
    function burn(address _owner, uint256 _id, uint256 _value) external;
}