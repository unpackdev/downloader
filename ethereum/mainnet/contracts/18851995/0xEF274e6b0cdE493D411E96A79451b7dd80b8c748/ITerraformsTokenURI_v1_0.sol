// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Types.sol";

interface ITerraformsTokenURI_v1_0 {
    function tokenURI(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256[] memory
    ) external view returns (string memory);

    function tokenHTML(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256[] memory
    ) external view returns (string memory);

    function tokenSVG(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256[] memory
    ) external view returns (string memory);

    function animationParameters(
        uint256,
        uint256
    ) external view returns (AnimParams memory);

    function durations(uint256) external view returns (uint256);
}
