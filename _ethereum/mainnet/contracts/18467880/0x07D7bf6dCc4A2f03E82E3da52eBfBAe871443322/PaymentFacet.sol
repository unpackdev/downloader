// SPDX-License-Identifier: BUSL-1.1

// @author cSigma Finance Inc., a Delaware company, for its Real World Credit tokenization protocol
pragma solidity ^0.8.0;

import "./VaultFacet.sol";
import "./Strings.sol";

library PaymentLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("csigma.payment.storage");

    struct PaymentState {
        mapping(string => Payment) payments;
        uint256 paymentId;
    }

    struct Payment {
        string roleId;
        string creditPoolId;
        PaymentType paymentType;
        uint64 timeStamp;
        address from;
        address to;
        uint256 amount;
    }

    enum PaymentType {
        INVESTMENT,
        PANDC,
        DEPOSIT,
        WITHDRAW,
        FEE,
        EXIT,
        PRINCIPAL,
        COUPON,
        PASTDUE
    }

    event PaymentEvent(PaymentLib.Payment payment);

    function diamondStorage() internal pure returns (PaymentState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function getPayment(string calldata _paymentId) internal view returns (Payment memory) {
        PaymentState storage paymentState = diamondStorage();
        return paymentState.payments[_paymentId];
    }

    function getLastPaymentId() internal view returns (uint256) {
        PaymentState storage paymentState = diamondStorage();
        return paymentState.paymentId;
    }

    function addPayment(
        string memory _roleId,
        string memory _creditPoolId,
        PaymentType _type,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (string memory) {
        VaultLib.enforceIsVault();
        PaymentState storage paymentState = diamondStorage();
        paymentState.paymentId++;
        string memory _paymentId = Strings.toString(paymentState.paymentId);
        paymentState.payments[_paymentId] = Payment(_roleId, _creditPoolId, _type, uint64(block.timestamp), _from, _to, _amount);
        emit PaymentEvent(paymentState.payments[_paymentId]);
        return _paymentId;
    }
}

contract PaymentFacet {
    function getPayment(string calldata _paymentId) external view returns (PaymentLib.Payment memory) {
        return PaymentLib.getPayment(_paymentId);
    }

    function getLastPaymentId() external view returns (uint256) {
        return PaymentLib.getLastPaymentId();
    }
}
