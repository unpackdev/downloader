pragma solidity ^0.6.0;
 
import "./Oracle.sol"; 
// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract OracleBCB is Oracle { 

    /* ========== CONSTRUCTOR ========== */
    constructor(
        address _factory,
        address _tokenA,
        address _tokenB,
        uint256 _period,
        uint256 _startTime
    ) public Oracle(_factory,_tokenA,_tokenB,_period, _startTime) { 

    }
 
}
