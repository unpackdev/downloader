// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


import "./Counters.sol";
import "./IDEX.sol";
/**
> Collection
@notice this contract is standard ERC721 to used as xanalia user's collection managing his NFTs
 */
contract CollectionStorage {
using Counters for Counters.Counter;

Counters.Counter tokenIds;
string public baseURI;
mapping(address => bool) _allowAddress;
Counters.Counter launchpadBox;
address public launchPadAddress;//required only for proxy

  uint256 maxLaunchPadSupply;
  Counters.Counter launchPadSupply;
  address authorAddress;
  uint256 royalty;

IDEX dex;
 
}