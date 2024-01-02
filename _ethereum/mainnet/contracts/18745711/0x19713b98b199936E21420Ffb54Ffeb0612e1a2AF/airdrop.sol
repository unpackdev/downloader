// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SendToken.sol";

contract AirdropContract {
    SENDToken public sendToken;
    address public owner;
    address public ethWallet;
    address public sendWallet;

    event EthTransfer(address indexed recipient, uint256 amount, bool success);
    event SendTokenTransfer(address indexed recipient, uint256 amount, bool success);
    event EthWalletChanged(address indexed newEthWallet);
    event SendWalletChanged(address indexed newSendWallet);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor(SENDToken _sendToken, address _ethWallet, address _sendWallet) {
        sendToken = _sendToken;
        owner = msg.sender;
        ethWallet = _ethWallet;
        sendWallet = _sendWallet;
    }

    function distributeSENDTokens(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Mismatched arrays");

        for (uint256 i = 0; i < recipients.length; i++) {
            bool success = sendToken.transfer(recipients[i], amounts[i]);
            emit SendTokenTransfer(recipients[i], amounts[i], success);
        }
    }

    function distributeETH(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Mismatched arrays");

        for (uint256 i = 0; i < recipients.length; i++) {
            (bool success, ) = payable(recipients[i]).call{value: amounts[i]}("");
            emit EthTransfer(recipients[i], amounts[i], success);
        }
    }

    function changeEthWallet(address _newEthWallet) external onlyOwner {
        require(_newEthWallet != address(0), "Invalid address");
        ethWallet = _newEthWallet;
        emit EthWalletChanged(_newEthWallet);
    }

    function changeSENDWallet(address _newSendWallet) external onlyOwner {
        require(_newSendWallet != address(0), "Invalid address");
        sendWallet = _newSendWallet;
        emit SendWalletChanged(_newSendWallet);
    }

    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available");
        payable(owner).transfer(balance);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {
        // The contract can react to receiving Ether if necessary
    }
}
