// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "./IERC721.sol";

interface IPolymorphicFacesRoot is IERC721 {

    function setMaxSupply(uint256 maxSupply) external;
}
