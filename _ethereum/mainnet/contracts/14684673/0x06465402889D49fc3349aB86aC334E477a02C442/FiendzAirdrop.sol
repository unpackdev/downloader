
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Base.sol";

contract FiendzAirdrop is ERC1155Base{
  constructor()
    ERC1155Base( "Fiendz Airdrop", "F:A" ){
    setToken( 0, "Kyle Munson airdrop #3", "https://fiendz.io/airdrop/eth-0.json", 105,
      false, 1 ether,
      false, 1 ether );
  }
}
