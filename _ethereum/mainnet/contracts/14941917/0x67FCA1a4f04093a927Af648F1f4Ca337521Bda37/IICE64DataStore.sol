// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.14;

interface IICE64DataStore {
    function getBaseURI() external view returns (string memory);

    function getRawPhotoData(uint256 id) external view returns (bytes memory);
}
