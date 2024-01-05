// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Address.sol";

abstract contract RevenueSplit {

    struct RevenueShare {
        address payable receiver;
        uint256 share;
    }

    uint256 public totalShares;
    RevenueShare[] public receiverInfos;

    function receiverExists(address receiver) internal view returns (bool) {
        for (uint256 idx = 0; idx < receiverInfos.length; idx++) {
            if (receiverInfos[idx].receiver == receiver) {
                return true;
            }
        }

        return false;
    }

    function authorizeRevenueChange(address receiver, bool add) virtual internal;

    function addRevenueSplit(address payable receiver, uint256 share) public {
        authorizeRevenueChange(receiver, true);
        require(!receiverExists(receiver), "Receiver Already Registered");
        receiverInfos.push();
        uint256 newIndex = receiverInfos.length - 1;

        receiverInfos[newIndex].receiver = receiver;
        receiverInfos[newIndex].share = share;
        totalShares += share;
    }

    function removeRevenueSplit(address receiver) public {
        authorizeRevenueChange(receiver, false);
        require(receiverExists(receiver), "Receiver not Registered");

        for (uint256 idx = 0; idx < receiverInfos.length; idx++) {
            if (receiverInfos[idx].receiver == receiver) {
                // subtract this receiver's share
                totalShares -= receiverInfos[idx].share;

                // if this isn't the last entry, copy the last entry to this slot
                // after the loop we will drop the tail
                if (idx < receiverInfos.length - 1) {
                    receiverInfos[idx] = receiverInfos[receiverInfos.length - 1];
                }
                break;
            }
        }

        receiverInfos.pop();
    }

    function processRevenue(uint256 totalAmount, address payable defaultRecipient) internal {
        if (totalShares == 0) {
            Address.sendValue(defaultRecipient, totalAmount);
            return;
        }

        uint256 remainingAmount = totalAmount;
        RevenueShare[] memory payments = new RevenueShare[](receiverInfos.length);

        for( uint256 idx = 0; idx < receiverInfos.length; idx ++) {
            uint256 thisShare = SafeMath.div(SafeMath.mul(totalAmount, receiverInfos[idx].share), totalShares);
            require(thisShare <= remainingAmount, "Error splitting revenue");
            remainingAmount = remainingAmount - thisShare;
            payments[idx].receiver = receiverInfos[idx].receiver;
            payments[idx].share = thisShare;
        }

        // round robin any excess
        uint256 nextIdx = 0;
        while (remainingAmount > 0) {
            payments[nextIdx % payments.length].share = payments[nextIdx % payments.length].share + 1;
            remainingAmount = remainingAmount - 1;
            nextIdx = nextIdx + 1;
        }

        // process payouts now that we are done reading state (for re-entrancy safety)
        for( uint256 idx = 0; idx < payments.length; idx ++) {
            Address.sendValue(payments[idx].receiver, payments[idx].share);
        }
    }
}