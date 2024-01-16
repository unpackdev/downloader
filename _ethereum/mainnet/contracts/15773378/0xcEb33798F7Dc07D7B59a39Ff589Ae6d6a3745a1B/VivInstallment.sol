// SPDX-License-Identifier: MIT
// Viv Contracts

pragma solidity ^0.8.4;

import "./Token.sol";
import "./SignUtil.sol";
import "./SafeMath.sol";

/**
 * The sub-contract is used for the scenario where the payment is paid to the smart contract at one time,
 * and the seller is allowed to withdraw it in multiple batches.
 */
contract VivInstallment is Token {
    using SafeMath for uint256;

    struct Trade {
        address token;
        address payable seller;
        address payable buyer;
        address payable platform;
        address guarantor;
        uint256[] values;
        uint256[] times;
        bytes tid;
        bool refund;
        uint256 refundTime;
        uint256 out;
        uint256 feeRate;
    }

    mapping(bytes => Trade) _trades;

    bytes[] _tids;

    mapping(bytes => bool) _couponIds;

    event Refund(address indexed sender);

    function getUnlockAmount(bytes calldata tid) external view returns (uint256 unlockAmount) {
        return _getUnlockAmount(tid);
    }

    function _getUnlockAmount(bytes calldata tid) internal view returns (uint256 unlockAmount) {
        Trade memory trade = _trades[tid];
        uint256 length = trade.values.length;
        for (uint256 i = 0; i < length; i++) {
            if (trade.times[i] < block.timestamp && (!trade.refund || trade.times[i] < trade.refundTime)) {
                unlockAmount = unlockAmount.add(trade.values[i]);
            }
        }
    }

    function getCanWithdrawAmount(bytes calldata tid) external view returns (uint256 canWithdraw) {
        uint256 unlockAmount = _getUnlockAmount(tid);
        Trade memory trade = _trades[tid];
        canWithdraw = unlockAmount.sub(trade.out);
    }

    function getWithdrawedAmount(bytes calldata tid) external view returns (uint256 withdrawed) {
        Trade memory trade = _trades[tid];
        withdrawed = trade.out;
    }

    function getRefundStatus(bytes calldata tid) external view returns (bool refundStatus) {
        Trade memory trade = _trades[tid];
        refundStatus = trade.refund;
    }

    function getRefundTime(bytes calldata tid) external view returns (uint256 refundTime) {
        Trade memory trade = _trades[tid];
        refundTime = trade.refundTime;
    }

    /**
     * purchase
     * note: This function is called by the buyer and completes the purchase
     * @param seller seller
     * @param platform platform
     * @param guarantor guarantor
     * @param values installment value
     * @param times installment time
     * @param tid trade id
     * @param token token address
     * @param feeRate fee rate
     */
    function purchase(
        address seller,
        address platform,
        address guarantor,
        uint256[] memory values,
        uint256[] memory times,
        bytes calldata tid,
        address token,
        uint256 feeRate
    ) external payable {
        require(seller != address(0), "VIV5001");
        require(platform != address(0), "VIV5002");
        require(guarantor != address(0), "VIV5003");
        require(values.length > 0 && times.length > 0, "VIV5409");
        require(values.length == times.length, "VIV5408");

        Trade storage trade = _trades[tid];
        require(trade.buyer == address(0), "VIV5004");

        uint256 value = 0;
        for (uint256 i = 0; i < values.length; i++) {
            value = value.add(values[i]);
        }
        require(value > 0, "VIV0001");
        _checkTransferIn(token, value);

        trade.token = token;
        trade.seller = payable(seller);
        trade.buyer = payable(msg.sender);
        trade.platform = payable(platform);
        trade.guarantor = guarantor;
        trade.values = values;
        trade.times = times;
        trade.tid = tid;
        trade.refund = false;
        trade.feeRate = feeRate;

        _tids.push(tid);

        _transferFrom(trade.token, trade.buyer, address(this), value);
    }

    /**
     * refund
     * @param tid trade id
     */
    function refund(bytes calldata tid) external {
        Trade storage trade = _trades[tid];
        require(trade.buyer == msg.sender, "VIV5401");
        require(trade.refund == false, "VIV5402");
        trade.refund = true;
        trade.refundTime = block.timestamp;
        emit Refund(msg.sender);
    }

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
        Trade storage trade = _trades[tid];
        require(trade.seller != address(0), "VIV5005");
        require(value > 0, "VIV0001");
        require(arbitrateFee >= 0, "VIV5403");
        require(trade.seller == msg.sender || trade.buyer == msg.sender, "VIV5406");

        uint256 available = value.sub(arbitrateFee);
        uint256 fee = available.rate(trade.feeRate);
        // Calculate the discounted price when couponRate more than 0
        if (couponRate > 0) {
            // Coupon cannot be reused
            require(!_couponIds[couponId], "VIV0006");
            // Check if platform signed
            bytes32 h = ECDSA.toEthSignedMessageHash(abi.encode(couponRate, couponId, tid));
            require(SignUtil.checkSign(h, signedValue3, trade.platform), "VIV0007");
            // Use a coupon
            fee = fee.sub(fee.rate(couponRate));
            _couponIds[couponId] = true;
        }

        if (arbitrateFee == 0) {
            bytes32 hashValue = ECDSA.toEthSignedMessageHash(abi.encode(tid));
            require(
                SignUtil.checkSign(hashValue, signedValue1, signedValue2, trade.buyer, trade.seller, trade.guarantor),
                "VIV5006"
            );
        } else {
            bytes32 hashValue = ECDSA.toEthSignedMessageHash(abi.encode(value, arbitrateFee, tid));
            require(
                SignUtil.checkSign(hashValue, signedValue1, signedValue2, trade.buyer, trade.seller, trade.guarantor),
                "VIV5006"
            );
        }

        // normal withdraw when arbitrateFee == 0
        uint256 canWithdraw = 0;
        uint256 length = trade.values.length;
        // When the arbitration amount is 0, it means ordinary withdrawal, otherwise it is arbitration withdrawal
        if (arbitrateFee == 0) {
            if (trade.seller == msg.sender) {
                // The buyer applies for a refund and cannot withdraw any more
                require(!trade.refund, "VIV5410");
                // Seller withdraws normally
                for (uint256 i = 0; i < length; i++) {
                    if (trade.times[i] < block.timestamp) {
                        canWithdraw = canWithdraw.add(trade.values[i]);
                    }
                }
                canWithdraw = canWithdraw.sub(trade.out);
                trade.out = trade.out.add(value);
            } else {
                // Buyer applies for withdrawal, seller agrees to withdraw
                // Non-refundable status, buyers cannot withdraw cash
                require(trade.refund, "VIV5407");
                // Buyers can only withdraw cash after the refund time
                for (uint256 i = 0; i < length; i++) {
                    canWithdraw = canWithdraw.add(trade.values[i]);
                }
                canWithdraw = canWithdraw.sub(trade.out);
                trade.out = trade.out.add(value);
            }
        } else {
            for (uint256 i = 0; i < length; i++) {
                canWithdraw = canWithdraw.add(trade.values[i]);
            }
            canWithdraw = canWithdraw.sub(trade.out);
            trade.out = trade.out.add(value);
        }

        require(value <= canWithdraw, "VIV5405");
        // require(_balanceOf(trade.token) >= canWithdraw, "VIV5007");

        if (arbitrateFee > 0) {
            _transfer(trade.token, trade.guarantor, arbitrateFee);
        }
        if (fee > 0) {
            _transfer(trade.token, trade.platform, fee);
        }
        _transfer(trade.token, msg.sender, available.sub(fee));
    }
}
