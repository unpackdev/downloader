// SPDX-License-Identifier: MIT
// Viv Contracts

pragma solidity ^0.8.4;

import "./Token.sol";
import "./SignUtil.sol";
import "./SafeMath.sol";

/**
 * A timer contract mainly binds the buyer, agrees on the payment date in advance, and requires the buyer to pay on time. 
 * There is no link of delivery and confirmation of receipt. A deposit (optional) is required. 
 * The deposit is locked before the end of the contract and can be withdrawn by the buyer after the end of the contract.

 * Suitable scenarios such as monthly video membership, rent payment, etc.
 */
contract VivTimer is Token {
    using SafeMath for uint256;

    struct User {
        address payable seller;
        address payable buyer;
        address payable platform;
        address guarantor;
    }

    struct Deposit {
        uint256 deposit;
        uint256 completedDeposit;
        uint256 withdrawedDeposit;
        uint256 historyPenalty;
        uint256 withdrawedPenalty;
    }

    struct Trade {
        address token;
        User user;
        uint256[] values;
        uint256[] times;
        bytes tid;
        bool refund;
        uint256 refundTime;
        Deposit deposit;
        uint256 current;
        uint256 penaltyRate;
        uint256 feeRate;
    }

    mapping(bytes => Trade) _trades;

    bytes[] _tids;

    mapping(bytes => bool) _couponIds;

    uint256 constant _INTERNAL_SECONDS = 86400;

    function getPayAmount(bytes calldata tid) external view returns (uint256 waitPayAmount, uint256 payedAmount) {
        Trade memory trade = _trades[tid];
        if (trade.current == trade.values.length) {
            return (0, 0);
        }
        for (uint256 i = trade.current; i < trade.values.length; i++) {
            waitPayAmount = waitPayAmount.add(trade.values[i]);
        }
        for (uint256 i = 0; i < trade.current; i++) {
            payedAmount = payedAmount.add(trade.values[i]);
        }
    }

    function getDeposit(bytes calldata tid)
        external
        view
        returns (
            uint256 deposit,
            uint256 completedDeposit,
            uint256 withdrawedDeposit,
            uint256 historyPenalty,
            uint256 withdrawedPenalty
        )
    {
        return (
            _trades[tid].deposit.deposit,
            _trades[tid].deposit.completedDeposit,
            _trades[tid].deposit.withdrawedDeposit,
            _trades[tid].deposit.historyPenalty,
            _trades[tid].deposit.withdrawedPenalty
        );
    }

    // function getRefundStatus(bytes calldata tid) external view returns(bool refundStatus) {
    //     Trade memory trade = _trades[tid];
    //     refundStatus = trade.refund;
    // }

    // function getRefundTime(bytes calldata tid) external view returns(uint256 refundTime) {
    //     Trade memory trade = _trades[tid];
    //     refundTime = trade.refundTime;
    // }

    function getCurrent(bytes calldata tid) external view returns (uint256 current) {
        return _trades[tid].current;
    }

    function getWithdrawAmount(bytes calldata tid)
        external
        view
        returns (
            uint256 canWithdraw,
            uint256 withdrawed,
            uint256 totalPenalty
        )
    {
        return _getWithdrawAmount(tid, block.timestamp);
    }

    function _getWithdrawAmount(bytes calldata tid, uint256 currentTime)
        internal
        view
        returns (
            uint256 canWithdraw,
            uint256 withdrawed,
            uint256 totalPenalty
        )
    {
        Trade memory trade = _trades[tid];
        totalPenalty = _getTotalPenalty(trade, currentTime);
        canWithdraw = totalPenalty.sub(trade.deposit.withdrawedPenalty);
        uint256 remainderDeposit = trade.deposit.deposit.add(trade.deposit.completedDeposit).sub(
            trade.deposit.withdrawedDeposit
        );
        if (totalPenalty > remainderDeposit) {
            canWithdraw = remainderDeposit.sub(trade.deposit.withdrawedPenalty);
        }
        withdrawed = trade.deposit.withdrawedPenalty;
    }

    /**
     * purchase
     * note: This function is called by the buyer and completes the purchase
     * @param users users: seller, platform, guarantor, token
     * @param values installment value
     * @param times installment time
     * @param tid trade id
     * @param penaltyRate penalty ratio
     * @param value value
     * @param deposit deposit
     */
    function purchase(
        address[] memory users,
        uint256[] memory values,
        uint256[] memory times,
        bytes calldata tid,
        uint256 penaltyRate,
        uint256 feeRate,
        uint256 value,
        uint256 deposit
    ) external payable {
        _purchase(users, values, times, tid, penaltyRate, feeRate, value, deposit, block.timestamp);
    }

    function _purchase(
        address[] memory users,
        uint256[] memory values,
        uint256[] memory times,
        bytes calldata tid,
        uint256 penaltyRate,
        uint256 feeRate,
        uint256 value,
        uint256 deposit,
        uint256 currentTime
    ) internal {
        require(value > 0, "VIV0001");
        Trade storage trade = _trades[tid];
        if (trade.user.buyer == address(0)) {
            address seller = users[0];
            address platform = users[1];
            address guarantor = users[2];
            address token = users[3];
            require(seller != address(0), "VIV5001");
            require(platform != address(0), "VIV5002");
            require(guarantor != address(0), "VIV5003");
            require(values.length > 0 && times.length > 0, "VIV5409");
            require(values.length == times.length, "VIV5408");

            // first purchage
            trade.token = token;
            trade.user.seller = payable(seller);
            trade.user.buyer = payable(msg.sender);
            trade.user.platform = payable(platform);
            trade.user.guarantor = guarantor;
            trade.values = values;
            trade.times = times;
            trade.tid = tid;
            trade.deposit.deposit = deposit;
            trade.current = 0;
            trade.penaltyRate = penaltyRate;
            trade.feeRate = feeRate;
            _tids.push(tid);
        } else {
            // trade.current == trade.times.length means this transaction has ended
            require(trade.current < trade.times.length, "VIV5505");

            // Calculate whether the user needs to make up the deposit
            uint256 totalPenalty = _getTotalPenalty(trade, currentTime);
            require(deposit >= totalPenalty.sub(trade.deposit.completedDeposit), "VIV5501");
            trade.deposit.historyPenalty = totalPenalty;
            trade.deposit.completedDeposit = trade.deposit.completedDeposit.add(deposit);
        }

        uint256 totalPayment = value.add(deposit);
        _checkTransferIn(trade.token, totalPayment);

        // Determine how much the buyer needs to pay
        // The buyer must pay the debt first
        uint256 needPay = 0;
        uint256 i = trade.current;
        for (; i < trade.times.length; i++) {
            if (trade.times[i] < currentTime) {
                needPay = needPay.add(trade.values[i]);
            } else {
                break;
            }
        }

        // Buyer does not have enough money to pay the debt
        require(value >= needPay, "VIV5502");

        // The payment amount must match the amount to be paid
        if (value > needPay) {
            uint256 over = value.sub(needPay);
            while (i < trade.values.length) {
                over = over.sub(trade.values[i]);
                i++;
                if (over == 0) {
                    break;
                } else if (over < 0) {
                    // The payment amount does not match the amount to be paid
                    revert("VIV5503");
                }
            }
        }

        // Buyer transfer to the contract
        _transferFrom(trade.token, trade.user.buyer, address(this), totalPayment);

        // Pay to the platform
        uint256 fee = value.rate(trade.feeRate);
        if (fee > 0) {
            _transfer(trade.token, trade.user.platform, fee);
        }

        // Pay to the seller
        _transfer(trade.token, trade.user.seller, value.sub(fee));

        // Set the buyer's next payment period
        trade.current = i;
    }

    // /**
    //  * Request a refund
    //  * @param tid trade id
    //  */
    // function refund(bytes calldata tid) external {
    //    Trade storage trade = _trades[tid];
    //    require(trade.user.buyer == msg.sender, "VIV5401");
    //    require(trade.refund == false, "VIV5402");
    //    trade.refund = true;
    //    trade.refundTime = block.timestamp;
    // }

    // /**
    //  * Refused to refund
    //  * @param tid trade id
    //  */
    // function cancelRefund(bytes calldata tid) external {
    //    Trade storage trade = _trades[tid];
    //    require(trade.buyer == msg.sender, "VIV5401");
    //    require(trade.refund == true, "VIV5402");
    //    trade.refund = false;
    // }

    /**
     * Withdraw
     * note: If the buyer, seller, and guarantor sign any two parties, the seller or the buyer can withdraw.
     * @param signedValue1 signed by one of seller, buyer, guarantor
     * @param signedValue2 signed by one of seller, buyer, guarantor
     * @param signedValue3 signed by platform
     * @param value        all amount, include which user can get, platform fee and arbitrate fee
     * @param couponRate   platform service fee rate
     * @param arbitrateFee arbitration service fee
     * @param tid          trade id
     * @param couponId     coupon id
     */
    function withdraw(
        bytes memory signedValue1,
        bytes memory signedValue2,
        bytes memory signedValue3,
        uint256 value,
        uint256 couponRate,
        uint256 arbitrateFee,
        bytes memory tid,
        bytes memory couponId
    ) external {
        _withdraw(
            signedValue1,
            signedValue2,
            signedValue3,
            value,
            couponRate,
            arbitrateFee,
            tid,
            couponId,
            block.timestamp
        );
    }

    function _withdraw(
        bytes memory signedValue1,
        bytes memory signedValue2,
        bytes memory signedValue3,
        uint256 value,
        uint256 couponRate,
        uint256 arbitrateFee,
        bytes memory tid,
        bytes memory couponId,
        uint256 currentTime
    ) internal {
        Trade storage trade = _trades[tid];
        require(trade.user.seller != address(0), "VIV5005");
        require(value > 0, "VIV0001");
        require(trade.user.seller == msg.sender || trade.user.buyer == msg.sender, "VIV5406");
        
        uint256 available = value.sub(arbitrateFee);
        uint256 fee = available.rate(trade.feeRate);
        // Calculate the discounted price when couponRate more than 0
        if (couponRate > 0) {
            // Coupon cannot be reused
            require(!_couponIds[couponId], "VIV0006");
            // Check if platform signed
            bytes32 h = ECDSA.toEthSignedMessageHash(abi.encode(couponRate, couponId, tid));
            require(SignUtil.checkSign(h, signedValue3, trade.user.platform), "VIV0007");
            // Use a coupon
            fee = fee.sub(fee.rate(couponRate));
            _couponIds[couponId] = true;
        }

        bytes32 hashValue = ECDSA.toEthSignedMessageHash(abi.encode(value, arbitrateFee, tid));
        uint256 canWithdraw = 0;
        if (arbitrateFee == 0 && trade.user.seller == msg.sender) { 
            require(
                SignUtil.checkSign(
                    hashValue,
                    signedValue1,
                    signedValue2,
                    trade.user.buyer,
                    trade.user.seller,
                    trade.user.platform
                ),
                "VIV5006"
            );
            // The amount that the seller can withdraw is the number of days from the overdue date to the current day * deposit * daily penalty ratio
            uint256 totalPenalty = _getTotalPenalty(trade, currentTime);
            canWithdraw = totalPenalty.sub(trade.deposit.withdrawedPenalty);
            // If the penalty interest exceeds the deposit, the penalty interest is equal to the deposit
            uint256 remainderDeposit = trade.deposit.deposit.add(trade.deposit.completedDeposit).sub(
                trade.deposit.withdrawedDeposit
            );
            if (totalPenalty > remainderDeposit) {
                canWithdraw = remainderDeposit.sub(trade.deposit.withdrawedPenalty);
            }
            trade.deposit.withdrawedPenalty = trade.deposit.withdrawedPenalty.add(value);
        } else {
            require(
                SignUtil.checkSign(
                    hashValue,
                    signedValue1,
                    signedValue2,
                    trade.user.buyer,
                    trade.user.seller,
                    trade.user.guarantor
                ),
                "VIV5006"
            );
            canWithdraw = trade
                .deposit
                .deposit
                .add(trade.deposit.completedDeposit)
                .sub(trade.deposit.withdrawedDeposit)
                .sub(trade.deposit.withdrawedPenalty);
            trade.deposit.withdrawedDeposit = trade.deposit.withdrawedDeposit.add(value);
        }

        require(value <= canWithdraw, "VIV5405");

        if (arbitrateFee > 0) {
            _transfer(trade.token, trade.user.guarantor, arbitrateFee);
        }
        if (fee > 0) {
            _transfer(trade.token, trade.user.platform, fee);
        }
        _transfer(trade.token, msg.sender, available.sub(fee));

        // If the remaining available deposit is less than or equal to 0, the transaction ends
        if (
            trade.deposit.deposit.add(trade.deposit.completedDeposit).sub(trade.deposit.withdrawedPenalty).sub(
                trade.deposit.withdrawedDeposit
            ) <= 0
        ) {
            trade.current = trade.times.length;
            trade.deposit.historyPenalty = trade.deposit.withdrawedPenalty;
        }
    }

    /**
     * The buyer can refund the remaining deposit at the end of the transaction
     * @param tid trade id
     */
    function refundDeposit(bytes memory tid) external {
        _refundDeposit(tid, block.timestamp);
    }

    function _refundDeposit(bytes memory tid, uint256 currentTime) internal {
        Trade storage trade = _trades[tid];
        require(trade.user.buyer != address(0), "VIV5005");
        require(trade.user.buyer == msg.sender, "VIV0021");
        require(trade.current == trade.times.length, "VIV5507");

        uint256 totalPenalty = _getTotalPenalty(trade, currentTime);
        uint256 canWithdraw = trade.deposit.deposit.add(trade.deposit.completedDeposit).sub(totalPenalty).sub(
            trade.deposit.withdrawedDeposit
        );
        trade.deposit.withdrawedDeposit = trade.deposit.withdrawedDeposit.add(canWithdraw);
        require(canWithdraw > 0, "VIV5506");
        _transfer(trade.token, msg.sender, canWithdraw);
    }

    /**
     * Get total penalty
     */
    function _getTotalPenalty(Trade memory trade, uint256 currentTime) private pure returns (uint256 totalPenalty) {
        totalPenalty = trade.deposit.historyPenalty;
        // If the user's repayment time exceeds the repayment date, the user needs to pay penalty interest
        if (trade.current < trade.times.length && currentTime > trade.times[trade.current]) {
            // 3600
            uint256 overdueDays = currentTime.sub(trade.times[trade.current]).div(_INTERNAL_SECONDS);
            uint256 penaltyAmount = overdueDays.mul(trade.deposit.deposit).rate(trade.penaltyRate);
            totalPenalty = totalPenalty.add(penaltyAmount);
        }
    }
}
