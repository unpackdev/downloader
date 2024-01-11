
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MetaciplesCore.sol";

contract MetaciplesSilver is MetaciplesCore {
  constructor()
    AM721("Metaciples: Silver", "MCP: S"){
    setActive( true );


    //Metaciples: Bronze
    setProxy( 1, 0x5f4f308AB2412fe0C7B8b578435D52eC0DA6eFA3, 0, true);

    //FLS
    setProxy( 2, 0x7D99e982A65966424C217458fCcb0bEA5735831b, 0, true);

    //Hunnys
    setProxy( 3, 0xb6c6B39AdA86c8A137B59E17e97c28fa74b649e2, 0, true);


    //Acolyte
    setProxy( 101, 0xfBC3c8CfC147aafb098f699224CDDC9E5E033503, 0, false);

    //Fellow
    setProxy( 102, 0x9af8719420d82262CAa8f90f7Ea15c8870dC65F4, 0, false);

    //Magus
    setProxy( 103, 0x653BF61A9131F3e6F98E63f72eE2994B89dd111e, 0, false);


    //Metaciples: Silver
    setProxy( 201, 0xe8Bcb1807173E6F61692503eC7Dbff340a0125C2, 0, false);
  }
}
