//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "./IERC1155Upgradeable.sol";

interface IPlot is IERC1155Upgradeable {
    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;
}
