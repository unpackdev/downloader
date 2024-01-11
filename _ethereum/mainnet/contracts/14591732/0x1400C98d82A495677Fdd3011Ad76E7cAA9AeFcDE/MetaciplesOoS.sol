
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MetaciplesCore.sol";

contract MetaciplesOoS is MetaciplesCore {
  constructor()
    AM721("Metaciples: Order of Shadows", "MCP: OoS"){
    setActive( true );

    //Acolyte
    setProxy( 101, 0xfBC3c8CfC147aafb098f699224CDDC9E5E033503, 0, false);

    //Fellow
    setProxy( 102, 0x9af8719420d82262CAa8f90f7Ea15c8870dC65F4, 0, false);

    //Magus
    setProxy( 103, 0x653BF61A9131F3e6F98E63f72eE2994B89dd111e, 0, false);
  }
}
