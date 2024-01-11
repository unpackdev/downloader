// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.3;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IPaymentSplitter.sol";

contract PaymentSplitter is Ownable, ReentrancyGuard, IPaymentSplitter {
    mapping(string => Beneficiary[]) public agreement;
    mapping(address => uint256) public availableToWithdraw;

    uint256 internal constant BASIS_POINTS = 10000;

    function createAgreement(string memory name, Beneficiary[] memory beneficiaries) external override {
        uint256 safetyCheck = 0;
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            agreement[name].push(Beneficiary(beneficiaries[i].payee, beneficiaries[i].basisPoints));
            safetyCheck += beneficiaries[i].basisPoints;
        }

        require(safetyCheck == BASIS_POINTS, "Agreement misconfiguration");

        emit AgreementCreated(name);
    }

    function deleteAgreement(string memory name) external override {
        delete agreement[name];
    }

    function deposit(string memory agreementName) external payable override {
        require(agreement[agreementName][0].basisPoints != 0, "Unknown agreement");

        for (uint256 i = 0; i < agreement[agreementName].length; i++) {
            availableToWithdraw[agreement[agreementName][i].payee] +=
                (msg.value * agreement[agreementName][i].basisPoints) /
                BASIS_POINTS;
        }

        emit Deposit(agreementName, msg.value);
    }

    function withdraw(address to, uint256 amount) external override nonReentrant {
        require(availableToWithdraw[msg.sender] >= amount, "Insufficient balance");

        availableToWithdraw[msg.sender] -= amount;

        payable(to).transfer(amount);

        emit Withdraw(to, amount);
    }

    function emergencyWithdrawal() external override onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
