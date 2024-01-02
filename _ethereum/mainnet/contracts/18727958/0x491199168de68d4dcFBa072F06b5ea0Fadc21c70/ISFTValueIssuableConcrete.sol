// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ISFTIssuableConcrete.sol";

interface ISFTValueIssuableConcrete is ISFTIssuableConcrete {
    function burnOnlyDelegate(uint256 tokenId, uint256 burnValue) external;
}