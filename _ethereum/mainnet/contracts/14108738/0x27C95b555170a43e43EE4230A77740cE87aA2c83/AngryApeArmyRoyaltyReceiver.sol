// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Ownable.sol";

contract AngryApeArmyRoyaltyReceiver is Ownable {
    address public angryApeArmy;
    address public netvrk;

    constructor() {
        angryApeArmy = 0x6ab71C2025442B694C8585aCe2fc06D877469D30;
        netvrk = 0x901FC05c4a4bC027a8979089D716b6793052Cc16;
    }

    receive() external payable {}

    function withdrawAll() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        require(totalBalance > 0, "Balance is zero");

        uint256 aaaAmount = (totalBalance * 7000) / 10000; // 70.00%
        uint256 netvrkAmount = totalBalance - aaaAmount; // 30.00%

        require(
            payable(angryApeArmy).send(aaaAmount),
            "Withdrawal Failed to AAA"
        );

        require(
            payable(netvrk).send(netvrkAmount),
            "Withdrawal Failed to netvrk"
        );
    }

    // Withdrawal
    function setAaaWithdrawal(address withdrawalAddress_) public onlyOwner {
        require(
            withdrawalAddress_ != address(0),
            "Set a valid withdrawal address"
        );
        angryApeArmy = withdrawalAddress_;
    }

    function setNetvrkWithdrawal(address withdrawalAddress_) public onlyOwner {
        require(
            withdrawalAddress_ != address(0),
            "Set a valid withdrawal address"
        );
        netvrk = withdrawalAddress_;
    }
}
