//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155.sol";

interface IBrawlerBearzFaction is IERC1155 {
    function getFaction(address _address) external view returns (uint256);
}
