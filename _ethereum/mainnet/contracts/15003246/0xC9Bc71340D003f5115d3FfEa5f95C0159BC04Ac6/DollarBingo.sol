//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract DollarBingo is Ownable {
    uint256 public payoutPercentage = 90;

    constructor() {}

    function payoutWinner(address winner) public onlyOwner {
        address payable pWinner = payable(winner);
        pWinner.transfer((address(this).balance * payoutPercentage) / 100);
    }

    function setPayoutPercentage(uint256 _payoutPercentage) public onlyOwner {
        payoutPercentage = _payoutPercentage;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    fallback() external payable {}
}
