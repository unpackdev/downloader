// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./IJuicy.sol";
import "./BubbleGumStruct.sol";
import "./BubbleGumEvents.sol";

contract BubbleGumState is ERC721Enumerable, BubbleGumStruct, BubbleGumEvents {
  using Counters for Counters.Counter;
  Counters.Counter internal _ids;

  uint public totalGenesis;
  mapping(uint256 => uint256) public genesis;
  mapping(uint256 => Meta) public meta;
  mapping(uint256 => address) public stakeOwners;
  mapping(Var => uint) public vars;
  mapping(address => uint256) public totalStakedGums;

  IJuicy internal _juicy;
  mapping(uint256 => uint256) internal _genesisIdx;
  mapping(address => mapping(uint256 => uint256)) internal _stakedGums;
  mapping(uint256 => uint256) internal _stakedGumsIndex;

  string constant DESCRIPTION = "The juiciest NFT game on Ethereum, where Chewers compete to blow the biggest bubble gum bubbles with the highest flavor intensity. If they're not careful, bubbles can burst and be destroyed or their gum can be dropped and lost forever. Genesis bubble gum chewers receive extra juicy gum from their frens.";
  uint launchAt;

  constructor(string memory _name, string memory _symbol, uint _launchAt) ERC721(_name, _symbol) {
    vars[Var.TOTAL_GENESIS] = 10000;
    vars[Var.TARGET_SUPPLY] = 25000;
    vars[Var.FEE_GENESIS]   = 0.3 ether;
    vars[Var.FEE_BLOW]      = 25 ether;
    vars[Var.FEE_JOIN]      = 250 ether;
    vars[Var.PROBA_BURST]   = 2;
    vars[Var.PROBA_SHARE]   = 100;
    vars[Var.PROBA_DROP]    = 2;
    vars[Var.PROBA_FREN]    = 10000;
    vars[Var.STAKE_SPLIT]   = 40;
    vars[Var.CHEW_RATE]     = 0.001 ether;

    launchAt = _launchAt;
  }
}