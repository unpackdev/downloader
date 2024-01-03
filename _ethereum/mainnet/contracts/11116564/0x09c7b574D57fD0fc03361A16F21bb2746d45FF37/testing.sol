pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract testing {
    
    uint256 public a;
    uint256 public b;
    uint256 public c;
    string public d;
    
    constructor() public payable { }
    
    function someOtherFunction(uint256 _a, uint256 _b, uint256 _c) public {
        require(_a > 10);
        a = _a;
        b = _b;
        c = _c;
        
        anotherFunction();
        
    }
    
    function anotherFunction() internal {
        d = "HELLO WORLD!";
    }
}