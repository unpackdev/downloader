// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract FiatPurchase {
    using SafeERC20 for IERC20;

    constructor(address _feeReceiver, address _adminAddress) {
        feeReceiver = _feeReceiver;
        adminAddress = _adminAddress;
    }

    event Buy(address wallet, uint256 memeAmount, uint256 ethAmount);

    address immutable feeReceiver;
    address immutable adminAddress;

    mapping(address => uint256) purchaseRecord;

    struct ClaimRecord {
        address user;
        uint256 amount;
    }

    function recoverClaimRecords(ClaimRecord[] memory records) public {
        require(msg.sender == adminAddress, "Only admin can recover claim records");
        for (uint256 i = 0; i < records.length; i++) {
            purchaseRecord[records[i].user] = records[i].amount;
        }
    }

    function purchase(address wallet, uint256 memeAmount) public payable {
        purchaseRecord[wallet] = purchaseRecord[wallet] + memeAmount;

        emit Buy(wallet, memeAmount, msg.value);

        payable(feeReceiver).transfer(msg.value);
    }

    function getUserPurchasedAmount(address wallet) public view returns (uint256) {
        return purchaseRecord[wallet];
    }

    receive() external payable {
        // Handle the received Ether
    }
}
