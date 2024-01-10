// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";

error WithdrawalFailedAngryApeArmy();
error WithdrawalFailedNetvrk();
error ZeroBalance();
error ZeroAddress();

contract AngryApeArmyRoyaltyReceiver is Ownable {
    address public angryApeArmy;
    address public netvrk;

    constructor() {
        angryApeArmy = 0x6ab71C2025442B694C8585aCe2fc06D877469D30;
        netvrk = 0x901FC05c4a4bC027a8979089D716b6793052Cc16;
    }

    receive() external payable {}

    function calculateSplit(uint256 balance)
        public
        pure
        returns (uint256 angryApeArmyAmount, uint256 netvrkAmount)
    {
        angryApeArmyAmount = (balance * 7000) / 10000; // 70.00%
        netvrkAmount = balance - angryApeArmyAmount; // 30.00%
    }

    function withdrawErc20(IERC20 token) external onlyOwner {
        uint256 totalBalance = token.balanceOf(address(this));
        if (totalBalance == 0) revert ZeroBalance();

        (uint256 angryApeArmyAmount, uint256 netvrkAmount) = calculateSplit(
            totalBalance
        );

        if (!token.transfer(angryApeArmy, angryApeArmyAmount))
            revert WithdrawalFailedAngryApeArmy();

        if (!token.transfer(netvrk, netvrkAmount))
            revert WithdrawalFailedNetvrk();
    }

    function withdrawEth() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        if (totalBalance == 0) revert ZeroBalance();

        (uint256 angryApeArmyAmount, uint256 netvrkAmount) = calculateSplit(
            totalBalance
        );

        if (!payable(angryApeArmy).send(angryApeArmyAmount))
            revert WithdrawalFailedAngryApeArmy();

        if (!payable(netvrk).send(netvrkAmount))
            revert WithdrawalFailedNetvrk();
    }

    function setAngryApeArmyAddress(address address_) public onlyOwner {
        if (address_ == address(0)) revert ZeroAddress();
        angryApeArmy = address_;
    }

    function setNetvrkAddress(address address_) public onlyOwner {
        if (address_ == address(0)) revert ZeroAddress();
        netvrk = address_;
    }
}
