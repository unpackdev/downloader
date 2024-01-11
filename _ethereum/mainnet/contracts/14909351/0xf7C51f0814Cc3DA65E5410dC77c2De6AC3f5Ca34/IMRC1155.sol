// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155.sol";

interface IMRC1155 is IERC1155{

    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;

    function burn(address user, uint256 id, uint256 amount) external;
    
}
