// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721MetadataUpgradeable.sol";

interface IOpenSeaCompatible is IERC721MetadataUpgradeable {
    /**
     * Get the contract metadata
     */
    function contractURI() external view returns (string memory);
}
