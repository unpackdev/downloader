// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";


/// @custom:security-contact security@lincoinpool.io
contract GnosisWithdraw is Ownable {
    address public WITHDRAW_ADDRESS = 0xA9Fba30e95C42c1862C803eB7c9bB535d178778f;

    constructor() {
    }

    function pay() external payable {
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(WITHDRAW_ADDRESS).transfer(balance);
    }

    function setWithdrawAddress(address withdrawAddress) external onlyOwner {
        WITHDRAW_ADDRESS = withdrawAddress;
    }
}
