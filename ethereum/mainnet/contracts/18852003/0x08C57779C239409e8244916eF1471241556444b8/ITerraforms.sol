// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Types.sol";

interface ITerraforms {
    function dreamers() external view returns (uint256);

    function ownerOf(uint256) external view returns (address);

    function tokenToDreamer(uint256) external view returns (address);

    function tokenToPlacement(uint256) external view returns (uint256);

    function tokenToStatus(uint256) external view returns (Status);
}
