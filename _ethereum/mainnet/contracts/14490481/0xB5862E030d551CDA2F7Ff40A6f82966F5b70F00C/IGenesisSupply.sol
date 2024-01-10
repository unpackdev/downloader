//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IGenesisTypes.sol";

interface IGenesisSupply is IGenesisTypes {
    function getMetadataForTokenId(uint256 tokenId)
        external
        view
        returns (TokenTraits memory traits);
}
