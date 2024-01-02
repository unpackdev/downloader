// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC2981Upgradeable.sol";

interface IMackerel is IERC721Upgradeable, IERC2981Upgradeable {
    function safeMint(address to) external returns (uint256 newNftId);
}
