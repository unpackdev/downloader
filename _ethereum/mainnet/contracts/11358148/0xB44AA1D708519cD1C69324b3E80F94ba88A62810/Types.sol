pragma experimental ABIEncoderV2;
pragma solidity ^0.6.10;

contract Types {

    /*@dev A type to store amounts of cTokens, to make sure they are not confused with amounts of the underlying */
    struct CTokenAmount {
        uint val;
    }

    /* @dev A type to store numbers scaled up by 18 decimals*/
    struct Exp {
        uint mantissa;
    }
}
