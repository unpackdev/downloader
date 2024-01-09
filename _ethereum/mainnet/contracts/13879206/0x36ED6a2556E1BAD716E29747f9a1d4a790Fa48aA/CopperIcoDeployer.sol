pragma solidity ^0.5.5;

/////////////////////////////////////////////////////
//////////////////////// ICO ////////////////////////
/////////////////////////////////////////////////////
//
// **************************************************
// Token:
// ==================================================
// Name        : peg63.546u Copper
// Symbol      : CU
// Total supply: Will be set after the Crowdsale
// ==================================================
//
//
// **************************************************
// Crowdsale:
// ==================================================
// Token : peg63.546u Copper
// Price : 0.00002
// Start : 28 December 2021 00:00 UTC±0
// End   : 4 January 2021 00:00 UTC±0
// Wallet: 0x6d4459AB286C86579C8013Cb9ef55F3C47b33F84
// ==================================================


import "./CopperToken.sol";
import "./CopperSale.sol";



contract CopperIcoDeployer {
    address public token_address;
    address public token_sale_address;

    constructor() public {
        CopperToken token = new CopperToken();
        token_address = address(token);
        CopperSale token_sale = new CopperSale(50000, 0x6d4459AB286C86579C8013Cb9ef55F3C47b33F84, token, 1640649600, 1641254400);
        token_sale_address = address(token_sale);
        token.addMinter(token_sale_address);
        token.renounceMinter();
    }
}