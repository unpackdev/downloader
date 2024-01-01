// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AERC721Factory {
    function createD4AERC721(
        string memory name,
        string memory symbol,
        uint256 startTokenId
    )
        external
        returns (address);
}
