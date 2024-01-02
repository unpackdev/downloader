// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

contract CADepTransferV1 is Initializable, OwnableUpgradeable {
    uint256 public commissionPercent;

    struct Payment {
        address payable recipient;
        uint256 amount;
    }

    event Transfer(
        address sender,
        address recipient,
        uint256 ethAmount,
        string status
    );

    function initialize(uint256 _percent) public initializer {
        __Ownable_init(msg.sender);
        commissionPercent = _percent;
    }

    receive() external payable {}

    function setCommissionPercent(uint256 _commissionPercent) public onlyOwner {
        commissionPercent = _commissionPercent;
    }

    function getCommissionPercent() public view returns (uint256) {
        return commissionPercent;
    }

    function transferToMultipleAddresses(
        Payment[] memory payments
    ) public payable {
        uint256 totalAmount = 0;

        for (uint i = 0; i < payments.length; i++) {
            totalAmount += payments[i].amount;
        }

        uint256 totalCommission = (msg.value * commissionPercent) / 100;

        require(msg.value >= totalAmount, "Insufficient Ether sent");

        uint256 remainingAmount = msg.value - totalCommission;

        for (uint i = 0; i < payments.length; i++) {
            uint256 amountToSend = (payments[i].amount * remainingAmount) /
                totalAmount;
            payments[i].recipient.transfer(amountToSend);
            emit Transfer(
                msg.sender,
                payments[i].recipient,
                payments[i].amount,
                "Transfer successful"
            );
        }
    }

    function withdrawCommissions() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
        emit Transfer(
            address(this),
            owner(),
            address(this).balance,
            "Withdraw successful"
        );
    }

    function estimatedGasPerTransfer() private pure returns (uint256) {
        return 21000;
    }
}
