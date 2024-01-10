// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./PaymentSplitter.sol";
contract Royalities is PaymentSplitter {
  uint256[] private _teamShares = [20, 10, 10, 5, 5, 15, 30, 5];
    address[] private _team = [
         0xfDE43eBd4f75960CdaC70971B731e0bab144c8F2,
        0xEa3184Cd529a7a5a9f033bA98F405F3a56F323A0,
        0x67Ee60ef898bEfd93D9D4b6921172FC4F74bE200,
        0xdBb4135934ca9EFBa9296931ac6690cFa36c645C,
        0xf08eF41e0669c53f7E9c297df4FF5Da9a675b971,
        0x32d09e780B25d905F24a6fCcB132FD9B363eC13F,
        0x697CBD509d8b8804539E50e566AFb54430a44384,
        0x5A6338B837CE975C7F5c9aEF9cE1f7EB256C009F 
    ];
constructor()
    PaymentSplitter( _team, _teamShares)
    { }

}
    