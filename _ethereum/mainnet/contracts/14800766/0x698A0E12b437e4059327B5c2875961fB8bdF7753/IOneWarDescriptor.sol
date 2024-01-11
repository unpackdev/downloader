// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IOneWar.sol";

interface IOneWarDescriptor {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}
