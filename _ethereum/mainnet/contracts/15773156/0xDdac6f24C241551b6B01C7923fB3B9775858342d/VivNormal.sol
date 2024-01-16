// SPDX-License-Identifier: MIT
// Viv Contracts

pragma solidity ^0.8.4;

import "./Token.sol";
import "./SignUtil.sol";
import "./SafeMath.sol";

/**
 * The ordinary transaction contract is used to solve the problem of trust between the seller and the seller,
 * and is guaranteed by the viv platform or the third-party guarantor found by the buyer and seller.
 * The contract can be withdrawn from the contract only when the three parties meet the signatures of two parties.
 */
contract VivNormal is Token {
    using SafeMath for uint256;

    struct Trade {
        address token;
        address payable seller;
        address payable buyer;
        address payable platform;
        address guarantor;
        uint256 value;
        uint256 feeRate;
        uint256 out;
    }

    mapping(bytes => Trade) _trades;
    mapping(bytes => bool) _couponIds;

    /**
     * purchase
     * note: This function is called by the buyer and completes the purchase
     * @param seller seller
     * @param platform platform
     * @param guarantor guarantor
     * @param feeRate Platform fee rate
     * @param tid trade id
     * @param token token address
     */
    function purchase(
        address seller,
        address platform,
        address guarantor,
        uint256 feeRate,
        uint256 value,
        bytes memory tid,
        address token
    ) external payable {
        _checkTransferIn(token, value);
        require(seller != address(0), "VIV5001");
        require(platform != address(0), "VIV5002");
        require(guarantor != address(0), "VIV5003");
        require(value > 0, "VIV0001");

        Trade storage trade = _trades[tid];
        require(trade.seller == address(0), "VIV5004");

        trade.token = token;
        trade.seller = payable(seller);
        trade.buyer = payable(msg.sender);
        trade.platform = payable(platform);
        trade.guarantor = guarantor;
        trade.feeRate = feeRate;
        trade.value = value;
        _transferFrom(trade.token, trade.buyer, address(this), trade.value);
    }

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
        require(trade.seller == msg.sender || trade.buyer == msg.sender, "VIV5011");

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

        uint256 canWithdraw = trade.value.sub(trade.out);
        require(value <= canWithdraw, "VIV5010");

        trade.out = trade.out.add(value);

        if (fee > 0) {
            _transfer(trade.token, trade.platform, fee);
        }
        if (arbitrateFee > 0) {
            _transfer(trade.token, trade.guarantor, arbitrateFee);
        }
        _transfer(trade.token, msg.sender, available.sub(fee));
    }
}
