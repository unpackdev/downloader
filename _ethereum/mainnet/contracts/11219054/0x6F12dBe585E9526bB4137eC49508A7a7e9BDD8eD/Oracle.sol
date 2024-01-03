pragma solidity ^0.4.24;

contract Ownable {
    address owner;
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract Oracle is Ownable {
    address public policy;
    uint256 public globalPrice;
    
    constructor(address _policy, uint256 _globalPrice) public {
        policy = _policy;
        globalPrice =_globalPrice;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        globalPrice = _newPrice;
    }    

    function getData() external view returns(uint256 price) {
        require(msg.sender == policy);
        price = globalPrice;
    }
 
}