// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";

interface IDaisy is IERC165 {
    function safeMint(address to, uint256 count, bytes memory data) external;
}
