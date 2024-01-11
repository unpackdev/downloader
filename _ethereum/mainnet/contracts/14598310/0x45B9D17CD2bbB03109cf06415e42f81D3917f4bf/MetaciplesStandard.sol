
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MetaciplesCore.sol";

contract MetaciplesStandard is MetaciplesCore {
  constructor()
    AM721("Metaciples", "MCP"){
    setActive( true );


    //Metaciples: Bronze
    setProxy( 1, 0x5f4f308AB2412fe0C7B8b578435D52eC0DA6eFA3, 0, true);

    //FLS
    setProxy( 2, 0x7D99e982A65966424C217458fCcb0bEA5735831b, 0, true);

    //Hunnys
    setProxy( 3, 0xb6c6B39AdA86c8A137B59E17e97c28fa74b649e2, 0, true);
  }
}
