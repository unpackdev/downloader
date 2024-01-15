// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: Puppet Samurai

import "./LabsERC721Token.sol";

/*

*/

contract PuppetSamuraiToken is LabsERC721Token {

 constructor(string memory name, string memory symbol, address proxyRegistryAddress) LabsERC721Token (name, symbol, proxyRegistryAddress) {}

}