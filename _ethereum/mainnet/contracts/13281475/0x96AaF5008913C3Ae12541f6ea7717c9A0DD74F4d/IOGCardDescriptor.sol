// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./OGCards.sol";
import "./IOGCards.sol";

interface IOGCardDescriptor {
    function tokenURI(address ogCards, uint256 tokenId) external view returns (string memory);
}