pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";

// https://onthis.xyz
/*
 .d88b.  d8b   db d888888b db   db d888888b .d8888. 
.8P  Y8. 888o  88    88    88   88    88    88   YP 
88    88 88V8o 88    88    88ooo88    88     8bo.   
88    88 88 V8o88    88    88   88    88       Y8b. 
`8b  d8' 88  V888    88    88   88    88    db   8D 
 `Y88P'  VP   V8P    YP    YP   YP Y888888P  8888Y  
*/

contract SwapRequester is OwnableUpgradeable {
    address public oracleEoaSwapper;

    uint256[50] private _gap;
    
    function initialize(address _oracleEoaSwapper) public initializer {
        __Ownable_init();
       oracleEoaSwapper = _oracleEoaSwapper;
    }
    
    receive() external payable {
        payable(oracleEoaSwapper).transfer(msg.value);
    }
}