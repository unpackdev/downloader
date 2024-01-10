//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./EIP712Library.sol";

abstract contract LondonTxSupport is EIP712Library {
    using SafeMath for uint256;

    struct TxRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
        uint256 deadline;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
    }

    int public constant TX_VERSION = 2;

    bytes32 public constant TX_REQUEST_TYPEHASH = keccak256("TxRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data,uint256 deadline,uint256 maxFeePerGas,uint256 maxPriorityFeePerGas)");

    function _getSigner(bytes32 _ds, TxRequest calldata _tx, bytes calldata _sign) internal pure returns (address) {
        bytes32 digest = keccak256(abi.encodePacked(
                "\x19\x01",
                _ds,
                keccak256(abi.encodePacked(
                    TX_REQUEST_TYPEHASH,
                    uint256(uint160(_tx.from)),
                    uint256(uint160(_tx.to)),
                    _tx.value,
                    _tx.gas,
                    _tx.nonce,
                    keccak256(_tx.data),
                    _tx.deadline,
                    _tx.maxFeePerGas,
                    _tx.maxPriorityFeePerGas
                ))
            ));

        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(_sign);
        return ecrecover(digest, v, r, s);
    }

    function _calculateCharge(uint256 _gasUsed, uint256 _txRelayFeePercent, TxRequest calldata _tx) internal view returns (uint256, uint256) {
        uint256 baseFee = block.basefee.add(_tx.maxPriorityFeePerGas);
        uint256 feePerGas = baseFee < _tx.maxFeePerGas ? baseFee : _tx.maxFeePerGas;

        uint256 feeForAllGas = _gasUsed.mul(feePerGas);
        uint256 totalFee = feeForAllGas.mul(_txRelayFeePercent.add(100)).div(100);
        uint256 txRelayFee = totalFee.sub(feeForAllGas);

        return (totalFee, txRelayFee);
    }
}
