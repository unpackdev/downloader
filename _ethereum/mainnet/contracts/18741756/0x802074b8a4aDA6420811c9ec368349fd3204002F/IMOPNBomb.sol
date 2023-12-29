// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC1155.sol";

interface IMOPNBomb is IERC1155 {
    function mint(address to, uint256 id, uint256 amount) external;

    function burn(address from, uint256 id, uint256 amount) external;

    function transferOwnership(address newOwner) external;
}
