// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Color.sol";

interface IMetadataRenderer {
    function renderUnreveal(uint16 tokenId) external view returns (string memory);
    function render(uint16 tokenId, Color memory color) external view returns (string memory);
}
