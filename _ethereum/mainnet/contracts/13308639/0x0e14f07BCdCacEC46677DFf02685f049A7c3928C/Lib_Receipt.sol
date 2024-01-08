pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import "./Lib_NVMCodec.sol";
import "./ECDSA.sol";

/**
 * @title Lib_Receipt
 * @dev A library for dealing with the receipt verification
 */
library Lib_Receipt {
    using ECDSA for bytes32;

    /**
     * Verifies the operator signature.
     * @param _receipt receipt to verify for.
     * @return Boolean whether the operator signature is valid.
     */
    function verifyOperatorSignature(
        Lib_NVMCodec.Receipt memory _receipt,
        address _operatorAddress
    )
        internal
        pure
        returns (
            bool
        )
    {
        bytes memory encoded = abi.encodePacked(
            _receipt.stateRoot,
            _receipt.index,
            _receipt.nvmTransactionHash
        );

        address operatorAddress = keccak256(encoded).recover(_receipt.operatorSignature);
        return _operatorAddress == operatorAddress;
    }

    /**
     * Verifies whether a transaction is valid.
     * @param _transaction Transaction to verify.
     * @param _receipt Receipt to verify.
     * @return True if the transaction exists in the CTC, false if not.
     */
    function verifyTransaction(
        Lib_NVMCodec.Transaction memory _transaction,
        Lib_NVMCodec.Receipt memory _receipt
    )
        internal
        pure
        returns (
            bool
        )
    {
        bytes32 nvmTxHash = Lib_NVMCodec.hashTransaction(_transaction);
        return nvmTxHash == _receipt.nvmTransactionHash;
    }
}
