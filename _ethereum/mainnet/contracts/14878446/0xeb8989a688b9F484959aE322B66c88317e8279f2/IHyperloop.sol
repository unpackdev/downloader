// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC1155.sol";

interface IHyperloop is IERC1155 {
    function mintMatrix(address, uint256) external;

    function mintCube(
        address,
        uint256,
        uint8
    ) external;

    function mintSquare(
        address,
        uint256,
        uint8
    ) external;
}
