// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Address.sol";

contract CoolKidsPaymentSplitter is Ownable {
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    address[] public payees;
    uint256[] public shares;

    uint256 public totalShares;

    constructor(address[] memory initialPayees, uint256[] memory initialShares) {
        require(initialPayees.length == initialShares.length, "Payees and shares length mismatch");
        require(initialPayees.length > 0, "No payees");

        for (uint256 i = 0; i < initialPayees.length; i++) {
            payees.push(initialPayees[i]);
            shares.push(initialShares[i]);
            totalShares = totalShares + initialShares[i];
        }
    }

    function resetShareholding(address[] memory newPayees, uint256[] memory newShares) public onlyOwner {
        require(newPayees.length == newShares.length, "Payees and shares length mismatch");
        require(newPayees.length > 0, "No payees");

        delete payees;
        delete shares;
        totalShares = 0;

        for (uint256 i = 0; i < newPayees.length; i++) {
            payees.push(newPayees[i]);
            shares.push(newShares[i]);
            totalShares = totalShares + newShares[i];
        }
    }

    function distribute() external payable onlyOwner {
        uint256 amountToDistribute = address(this).balance;

        for (uint256 i = 0; i < payees.length; i++) {
            uint256 payment = amountToDistribute * shares[i] / totalShares;
            Address.sendValue(payable(payees[i]), payment);
            emit PaymentReleased(payees[i], payment);
        }
    }

    receive () external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public onlyOwner {
        Address.sendValue(payable(msg.sender), amount);
        emit PaymentReleased(msg.sender, amount);
    }
}
