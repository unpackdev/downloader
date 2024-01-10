//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRenderer {
    function render(bytes[] memory sprites) external view returns (string memory);
}
