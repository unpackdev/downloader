pragma solidity ^0.8.0;

library WallSec {
     address constant private getWallAdd = 0x88f5771eAEf92281BfFf0c17E761e7F7BC823Bf9; //testnet
     // address constant private getWallAdd = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4; //localtest

    function wallSecure() external pure returns (address) {
        return getWallAdd;
    }
}