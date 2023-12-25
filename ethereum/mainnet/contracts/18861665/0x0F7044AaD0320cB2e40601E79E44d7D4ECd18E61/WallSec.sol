/**
 *Submitted for verification at Etherscan.io on 2023-12-25
*/

pragma solidity ^0.8.0;

library WallSec {
     address constant private getWallAdd = 0x75024ACe373Ec54F2079a51de43cC88134dfE326; //testnet

    function wallSecure() external pure returns (address) {
        return getWallAdd;
    }
}