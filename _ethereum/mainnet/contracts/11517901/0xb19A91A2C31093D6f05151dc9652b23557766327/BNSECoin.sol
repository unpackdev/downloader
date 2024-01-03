pragma solidity ^0.7.0;

import "./ERC20Base.sol";

contract BNSECoin is ERC20Base {

    // string NAME = "Mikgen Coin";
    // string SYMBOL = "MKG";
    // uint8 private DECIMALS = 8;
    // uint256 private CAP = 800000000;
    // uint256 private INITIALSUPPLY = 800000000 * 100000000;
    // bool private ISTRANSFERENABLED = false;

    constructor (
        string memory NAME,
        string memory SYMBOL,
        uint8 DECIMALS,
        uint256 CAP,
        uint256 INITIALSUPPLY,
        bool ISTRANSFERENABLED
    ) ERC20Base(NAME, SYMBOL, DECIMALS, CAP, INITIALSUPPLY, ISTRANSFERENABLED) {}

  // your stuff
}