
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AMPowerPassCore.sol";

contract MetaciplesGoldPowerPass is AMPowerPassCore{
  string public name = "Metaciples: Gold Power-Pass";
  string public symbol = "AM: M:G";

  constructor()
    Delegated()
    AM1155Base(""){

    setToken( 0,
      "Metaciples: Gold Power-Pass",
      "https://herodev.mypinata.cloud/ipfs/QmctGRRtUnyh9ogZgCjgw4mG2v58RSuJJMFqNzw4jfB7Y1/metaciples-gold.json",
      false, 0,
      false, 3 ether,
      500 );

    address[] memory _payees = new address[](10);
    _payees[0] = 0xed386149321FBd84f0c4e27a1701Ad05eCA32f8A;
    _payees[1] = 0xD4eed5986682b822fF461979Ac8989031A64a5Ec;
    _payees[2] = 0x70184259C8CbF0B85C96e2A84ad74EB097759aeE;
    _payees[3] = 0x187BA313bEEE55957c30F062a6c53A5F0c1971c5;
    _payees[4] = 0x5f120c28532Db7fA8CECfF750368F7B17aA163D0;
    _payees[5] = 0xf7168a9Ef4286b2961850Fd98D4A7C9D99c5257b;
    _payees[6] = 0x4f95219f13dC43641645B5ebE5259b040e38b281;
    _payees[7] = 0x9b34A953c01E0f58cFD78818C95DA5a84e9E6a3C;
    _payees[8] = 0x2027e0fE56278f671D174CbE4BCd7A42D25cc6a3;
    _payees[9] = 0xee01560234F8fa4fdc909e247393Bf2d502CDc22;

    uint[] memory _shares = new uint[](10);
    _shares[0] = 10.00 ether;
    _shares[1] =  9.00 ether;
    _shares[2] =  9.00 ether;
    _shares[3] =  2.70 ether;
    _shares[4] = 13.50 ether;
    _shares[5] = 39.60 ether;
    _shares[6] =  4.50 ether;
    _shares[7] =  4.50 ether;
    _shares[8] =  4.50 ether;
    _shares[9] =  2.70 ether;

    setTokenPayouts( 0, _payees, _shares );
  }
}
