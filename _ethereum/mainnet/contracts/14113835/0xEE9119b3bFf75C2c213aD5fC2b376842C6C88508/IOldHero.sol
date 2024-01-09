// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IRaidERC721.sol";

interface IOldHero is IRaidERC721 {
    function burnBatch(uint256[] calldata tokenIds) external;
}
