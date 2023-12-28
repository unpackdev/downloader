pragma solidity 0.6.7;

contract DeadManSwitch {
    
    uint256 public expirationTime = 1589481422;
    address[] public Benificiaries;
    address payable owner;
    uint256 public lastPing;
    
    constructor() public{
        owner = msg.sender;
        lastPing = block.timestamp;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "You need to be the owner of the contract to execute this function");
        _;
    }
    
    modifier afterExpiration() {
        require(block.timestamp > expirationTime, "Operation is not allowed yet.");
        _;
    }
    
    function withdraw() public onlyOwner afterExpiration {
        uint256 currentBalance = address(this).balance; 
        ping();
        owner.transfer(currentBalance);
    }
    
    function diposite() public payable onlyOwner {
        require(msg.value > 0, "Diposite has to be more than 0");
        ping();
    }
    
    function ping() public onlyOwner {
        lastPing = block.timestamp;
    }
    
    function isOwnerAlive() public view returns(bool) {
        if (block.timestamp - lastPing > 3 days) {
            return false;
        } else {
            return true;
        }
    }
    
    function becomeSoleBeneficiary() public {
        require(!isOwnerAlive(), "Owener is not dead yet.");
        uint256 currentBalance = address(this).balance; 
        address payable soleBeneficiary = msg.sender;
        soleBeneficiary.transfer(currentBalance);
    }
    
}