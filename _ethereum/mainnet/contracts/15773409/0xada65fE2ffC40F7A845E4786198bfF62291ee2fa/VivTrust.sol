// SPDX-License-Identifier: MIT
// Viv Contracts

pragma solidity ^0.8.4;

import "./Token.sol";
import "./SignUtil.sol";
import "./SafeMath.sol";

/**
 * Functions of traditional trusts: tax avoidance, certain legal protection, avoidance of court certification and property protection for children in divorce.
 * There are many types of trusts according to the needs of customers, including revocable trusts and irrevocable trusts, estate trusts, marriage trusts, family trusts, etc.
 * VIV first does a revocable trust based on smart contracts.
 */
contract VivTrust is Token {
    using SafeMath for uint256;

    struct Withdrawed {
        // The principal has already withdrawn
        uint256 principalWithdrawed;
        // The trustee has already withdrawn
        uint256 trusteeWithdrawed;
        // The trustee withdraws in this round (The start date does not change as one round)
        uint256 currentWithdrawed;
    }

    struct Trade {
        address token;
        address payable principal;
        address payable trustee;
        address payable platform;
        uint256 value;
        uint256 startDate;
        uint256 intervalDays;
        uint256 intervalAmount;
        uint256 feeRate;
        bytes tid;
        Withdrawed withdrawed;
    }

    mapping(bytes => Trade) _trades;

    bytes[] _tids;

    mapping(bytes => bool) _couponIds;

    uint256 constant _INTERNAL_SECONDS = 86400;

    /**
     * get project information
     * @return token token address
     * @return value value
     * @return startDate startDate
     * @return intervalDays intervalDays
     * @return intervalAmount intervalAmount
     */
    function getProject(bytes calldata tid)
        external
        view
        returns (
            address token,
            uint256 value,
            uint256 startDate,
            uint256 intervalDays,
            uint256 intervalAmount
        )
    {
        return (
            _trades[tid].token,
            _trades[tid].value,
            _trades[tid].startDate,
            _trades[tid].intervalDays,
            _trades[tid].intervalAmount
        );
    }

    /**
     * get amount
     * @return value value
     * @return remainderAmount remainderAmount
     * @return principalWithdrawed principalWithdrawed
     * @return trusteeWithdrawed trusteeWithdrawed
     * @return currentWithdrawed currentWithdrawed
     * @return canWithdraw canWithdraw
     */
    function getAmount(bytes calldata tid)
        external
        view
        returns (
            uint256 value,
            uint256 remainderAmount,
            uint256 principalWithdrawed,
            uint256 trusteeWithdrawed,
            uint256 currentWithdrawed,
            uint256 canWithdraw
        )
    {
        return _getAmount(tid, block.timestamp);
    }

    function _getAmount(bytes calldata tid, uint256 currentTime)
        internal
        view
        returns (
            uint256 value,
            uint256 remainderAmount,
            uint256 principalWithdrawed,
            uint256 trusteeWithdrawed,
            uint256 currentWithdrawed,
            uint256 canWithdraw
        )
    {
        Trade memory trade = _trades[tid];
        value = trade.value;
        principalWithdrawed = trade.withdrawed.principalWithdrawed;
        trusteeWithdrawed = trade.withdrawed.trusteeWithdrawed;
        currentWithdrawed = trade.withdrawed.currentWithdrawed;
        remainderAmount = trade.value.sub(trade.withdrawed.principalWithdrawed).sub(trade.withdrawed.trusteeWithdrawed);
        if (currentTime < trade.startDate) {
            canWithdraw = 0;
        }
        uint256 intervalTimes = _getIntervalTimes(currentTime, trade);
        canWithdraw = intervalTimes.mul(trade.intervalAmount).sub(trade.withdrawed.currentWithdrawed);
        if (canWithdraw > remainderAmount) {
            canWithdraw = remainderAmount;
        }
    }

    /**
     * set project information
     * note: This function is called by the principal
     * @param startDate startDate
     * @param intervalDays intervalDays
     * @param intervalAmount intervalAmount
     * @param tid trade id
     */
    function setProject(
        uint256 startDate,
        uint256 intervalDays,
        uint256 intervalAmount,
        bytes calldata tid
    ) external {
        Trade storage trade = _trades[tid];
        require(trade.principal == msg.sender, "VIV5804");
        require(startDate >= trade.startDate, "VIV5805");
        trade.startDate = startDate;
        trade.intervalDays = intervalDays;
        trade.intervalAmount = intervalAmount;
        trade.withdrawed.currentWithdrawed = 0;
    }

    /**
     * purchase
     * note: This function is called by the principal
     * @param trustee trustee
     * @param platform platform
     * @param startDate startDate
     * @param intervalDays intervalDays
     * @param intervalAmount intervalAmount
     * @param value value
     * @param tid trade id
     * @param token token address
     * @param feeRate fee rate
     */
    function purchase(
        address trustee,
        address platform,
        uint256 startDate,
        uint256 intervalDays,
        uint256 intervalAmount,
        uint256 value,
        bytes calldata tid,
        address token,
        uint256 feeRate
    ) external payable {
        require(value > 0, "VIV0001");
        _checkTransferIn(token, value);

        Trade storage trade = _trades[tid];
        if (trade.trustee == address(0)) {
            require(trustee != address(0), "VIV5801");
            require(platform != address(0), "VIV5002");
            trade.token = token;
            trade.trustee = payable(trustee);
            trade.principal = payable(msg.sender);
            trade.platform = payable(platform);
            trade.startDate = startDate;
            trade.intervalDays = intervalDays;
            trade.intervalAmount = intervalAmount;
            trade.value = value;
            trade.tid = tid;
            trade.token = token;
            trade.feeRate = feeRate;
            _tids.push(tid);
        } else {
            trade.value = trade.value.add(value);
        }

        _transferFrom(trade.token, msg.sender, address(this), value);
    }

    /**
     * Withdraw
     * note: Only principal or trustee can withdraw.
     * @param signedValue signed by platform
     * @param value        all amount, include which user can get, platform fee
     * @param couponRate   platform service fee rate
     * @param tid          trade id
     * @param couponId     coupon id
     */
    function withdraw(
        bytes memory signedValue,
        uint256 value,
        uint256 couponRate,
        bytes memory tid,
        bytes memory couponId
    ) external {
        _withdraw(signedValue, value, couponRate, tid, couponId, block.timestamp);
    }

    function _withdraw(
        bytes memory signedValue,
        uint256 value,
        uint256 couponRate,
        bytes memory tid,
        bytes memory couponId,
        uint256 currentTime
    ) internal {
        Trade storage trade = _trades[tid];
        require(trade.trustee != address(0), "VIV5005");
        require(value > 0, "VIV0001");
        require(trade.principal == msg.sender || trade.trustee == msg.sender, "VIV5802");

        uint256 fee = value.rate(trade.feeRate);
        // Calculate the discounted price when couponRate more than 0
        if (couponRate > 0) {
            // Coupon cannot be reused
            require(!_couponIds[couponId], "VIV0006");
            // Check if platform signed
            bytes32 h = ECDSA.toEthSignedMessageHash(abi.encode(couponRate, couponId, tid));
            require(SignUtil.checkSign(h, signedValue, trade.platform), "VIV0007");
            // Use a coupon
            fee = fee.sub(fee.rate(couponRate));
            _couponIds[couponId] = true;
        }

        uint256 canWithdraw = 0;
        // The remaining money in the contract
        uint256 remainderAmount = trade.value.sub(trade.withdrawed.principalWithdrawed).sub(
            trade.withdrawed.trusteeWithdrawed
        );
        if (trade.principal == msg.sender) {
            canWithdraw = remainderAmount;
            // The principal has withdrawn
            trade.withdrawed.principalWithdrawed = trade.withdrawed.principalWithdrawed.add(value);
        } else {
            require(currentTime >= trade.startDate, "VIV5803");
            // The amount that can be withdrawn in this round
            // interval times = (now - start) / 3600 / days + 1, add 1 becasue include the start date.
            uint256 intervalTimes = _getIntervalTimes(currentTime, trade);
            canWithdraw = intervalTimes.mul(trade.intervalAmount).sub(trade.withdrawed.currentWithdrawed);
            if (canWithdraw > remainderAmount) {
                canWithdraw = remainderAmount;
            }
            trade.withdrawed.trusteeWithdrawed = trade.withdrawed.trusteeWithdrawed.add(value);
            trade.withdrawed.currentWithdrawed = trade.withdrawed.currentWithdrawed.add(value);
        }

        require(value <= canWithdraw, "VIV5405");
        require(_balanceOf(trade.token) >= canWithdraw, "VIV5007");

        if (fee > 0) {
            _transfer(trade.token, trade.platform, fee);
        }
        _transfer(trade.token, msg.sender, value.sub(fee));
    }

    function _getIntervalTimes(uint256 currentTime, Trade memory trade) private pure returns (uint256) {
        return currentTime.sub(trade.startDate).div(_INTERNAL_SECONDS).div(trade.intervalDays).add(1);
    }
}
