pragma solidity ^0.5.9;

contract WithdrawFund {
    
    
    address owner ;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function withdraw(address payable which) external {
        require(msg.sender == owner,"only owner");
        uint256 value = address(this).balance;
        which.transfer(value);
    }
    
   
    // function() external payable {}
    
}