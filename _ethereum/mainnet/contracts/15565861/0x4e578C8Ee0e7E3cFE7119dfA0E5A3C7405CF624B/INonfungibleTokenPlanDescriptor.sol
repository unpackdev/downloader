// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INonfungiblePlanManager.sol";

interface INonfungibleTokenPlanDescriptor {
    function tokenURI(INonfungiblePlanManager planManager, uint256 tokenId)
        external
        view
        returns (string memory);
}
