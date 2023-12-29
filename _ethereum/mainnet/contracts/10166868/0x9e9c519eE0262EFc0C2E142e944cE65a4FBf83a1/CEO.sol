pragma solidity ^0.4.23;

contract CEO {
    address private target;
    address public ceo1;
    address public ceo2;
    
    constructor(address _target, address _ceo1, address _ceo2) public {
        target = _target;
        ceo1 = _ceo1;
        ceo2 = _ceo2;
    }
    
    function() external {
        require(msg.data.length != 0, "msg.data.length == 0");
        require(msg.sender == ceo1 || msg.sender == ceo2, "not a ceo address");
        require(target.call(msg.data), "call to Core failed");
    }
}