// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: Puppet Samurai

import "./LabsERC721DynamicMinter.sol";

/*

*/

contract PuppetSamuraiMinter is LabsERC721DynamicMinter {

 constructor(address creator, string memory prefix, uint256 mintPrice, uint256 maxMints) LabsERC721DynamicMinter(creator, prefix, mintPrice, maxMints) {}

}