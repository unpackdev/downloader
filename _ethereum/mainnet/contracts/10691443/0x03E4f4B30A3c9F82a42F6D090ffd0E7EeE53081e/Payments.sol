pragma solidity ^0.5.14;

contract Payments {

    address public addrPayment;
    address owner;

    function() external payable {}

    modifier onlyOwner{
        require(owner == msg.sender, "Only the owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function withdrawEth() public {
        address(uint160(addrPayment)).transfer(address(this).balance);
    }

    function setAddrPayment(address _addr) external onlyOwner {
        addrPayment = _addr;
    }

}