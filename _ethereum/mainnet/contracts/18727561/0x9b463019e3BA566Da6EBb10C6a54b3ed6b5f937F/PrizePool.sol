// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract PrizePool {
    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    constructor() {}

    function distributePrizes(address firstPlaceWallet, address secondPlaceWallet, address thirdPlaceWallet) public {
        uint256 balance = address(this).balance;
        uint256 firstPrize = balance * 50 / 100;
        uint256 secondPrize = balance * 30 / 100;
        uint256 thirdPrize = balance - (firstPrize + secondPrize);

        // Send 50% to the first place wallet
        (bool sentFirst, ) = firstPlaceWallet.call{value: firstPrize}("");
        require(sentFirst, "Failed to send Ether to first place");

        // Send 30% to the second place wallet
        (bool sentSecond, ) = secondPlaceWallet.call{value: secondPrize}("");
        require(sentSecond, "Failed to send Ether to second place");

        // Send 20% to the third place wallet
        (bool sentThird, ) = thirdPlaceWallet.call{value: thirdPrize}("");
        require(sentThird, "Failed to send Ether to third place");
    }
}