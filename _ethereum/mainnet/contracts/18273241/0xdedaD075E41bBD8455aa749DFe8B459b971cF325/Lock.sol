// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Lock {
    bool public unlocked;
    address payable public owner;
    address payable private benefactor;

    event Withdrawal(uint amount, uint when);
    event Toggle(bool unlocked);
    event UpdateBenefactor(address benefactor);


    constructor() payable {
        owner = payable(msg.sender);
        unlocked = false;
    }

    function withdraw() public {
        require((msg.sender == owner) || (msg.sender == benefactor), "You aren't the owner nor benefactor");
        require(unlocked == true);
        emit Withdrawal(address(this).balance, block.timestamp);

        //owner.transfer(address(this).balance);
        payable(msg.sender).transfer(address(this).balance);
    }

    function toggle() public returns (bool) {
        require(msg.sender == owner , "You aren't the owner");
        emit Toggle(unlocked);
        unlocked = !unlocked;
        return unlocked;
    }

    function getBenefactor() public view returns (address) {
        return(benefactor);
    }

    function getUnlocked() public view returns (bool) {
        return(unlocked);
    }

    function setBenefactor(address payable _benefactor) public {
        require(msg.sender == owner, "You aren't the owner");
        require(_benefactor != address(0));
        benefactor = _benefactor;
        emit UpdateBenefactor(benefactor);
    }
}

