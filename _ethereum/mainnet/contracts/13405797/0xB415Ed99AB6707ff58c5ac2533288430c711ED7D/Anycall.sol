pragma solidity 0.6.7;

// Perform any calls from delegatecall only proxies/timelocks (DSProxy).
contract Anycall {
    function call(address target, bytes memory data) public {
        (bool success, ) = target.call(data);
        require(success, "Anycall: Call reverted");
    }    
}