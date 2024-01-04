pragma solidity ^0.6.0;

contract splitter {
    
    address ownerAddress;
    mapping (uint256 => uint256) proportions;
    mapping (uint256 => address payable) addresses;
    
    modifier onlyOwner {
        if (msg.sender == ownerAddress) {
            _;
        }
    }
    
    constructor () public {
        ownerAddress = msg.sender;
        proportions[0] = 30; 
        proportions[1] = 20;
        addresses[0] = msg.sender;
        addresses[1] = msg.sender;
        addresses[2] = msg.sender;
    }
    
    function setProportion(uint256 index, uint256 value) public onlyOwner {
        proportions[index] = value;
    }
    
    function setAddress(uint256 index, address payable addr) public onlyOwner {
        addresses[index] = addr;
    }
    
    receive() external payable {
        uint256 lastValue = 100 -(proportions[0]+proportions[1]);
        addresses[0].transfer(msg.value*proportions[0]/100); 
        addresses[1].transfer(msg.value*proportions[1]/100);
        addresses[2].transfer(msg.value*lastValue/100);
    }
}