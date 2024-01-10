//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./Enums.sol";

abstract contract HoneyCombsDeluxeI is Ownable, IERC1155 {
    function burn(
        address _owner,
        uint256 _rarity,
        uint256 _amount
    ) external virtual;
}
