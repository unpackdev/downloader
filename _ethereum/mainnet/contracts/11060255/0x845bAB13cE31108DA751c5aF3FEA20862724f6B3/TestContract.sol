pragma solidity 0.7.3;

contract TestContract {
    address payable public owner;
    uint256 public countSet;
    
    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    }
    
    receive() payable external {
        
    }
    
    function setTesting() public {
        countSet = countSet + 1;
    }
    
    function close() public isOwner {
        selfdestruct(owner);
    }
}