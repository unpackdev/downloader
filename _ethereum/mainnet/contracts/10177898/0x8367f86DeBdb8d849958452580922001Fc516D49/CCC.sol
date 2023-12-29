pragma solidity >0.6.4 <0.7.0;

/**
 * 
 * There is an immutable keyword righthere
 * And another immutable, keyword, right, there.
 **/
 
contract CCC {
    uint256 public decimals;
    address public owner;

    constructor(uint8 _decimals) public {
        decimals = _decimals;
        owner = msg.sender;
    }
    
    function IhaveAPenAndPencilAndAnEraserAndApple() public view returns (uint256) {
        uint256 tmp = 25;
        return tmp * decimals;
    }
}