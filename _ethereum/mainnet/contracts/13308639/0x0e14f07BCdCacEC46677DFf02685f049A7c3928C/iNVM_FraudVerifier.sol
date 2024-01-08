// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import "./Lib_NVMCodec.sol";

/* Interface Imports */
import "./iNVM_StateTransitioner.sol";

/**
 * @title iNVM_FraudVerifier
 */
interface iNVM_FraudVerifier {

    /**********
     * Events *
     **********/

    event FraudProofInitialized(
        bytes32 _preStateRoot,
        uint256 _preStateRootIndex,
        bytes32 _transactionHash,
        address _who
    );

    event FraudProofFinalized(
        bytes32 _preStateRoot,
        uint256 _preStateRootIndex,
        bytes32 _transactionHash,
        address _who
    );


    /***************************************
     * Public Functions: Transition Status *
     ***************************************/

    function getStateTransitioner(bytes32 _preStateRoot, bytes32 _txHash) external view
        returns (iNVM_StateTransitioner _transitioner);


    /****************************************
     * Public Functions: Fraud Verification *
     ****************************************/

    function initializeFraudVerification(
        Lib_NVMCodec.Receipt calldata _preReceipt,
        Lib_NVMCodec.Receipt calldata _postReceipt,
        Lib_NVMCodec.Transaction calldata _transaction
    ) external;

    function finalizeFraudVerification(
        Lib_NVMCodec.Receipt calldata _preReceipt,
        Lib_NVMCodec.Receipt calldata _postReceipt,
        Lib_NVMCodec.Transaction calldata _transaction
    ) external;

    function insideFraudProofWindow(
        Lib_NVMCodec.Transaction calldata _ovmTransaction
    )
        external
        view
        returns (
            bool _inside
        );

    function updateFraudProofWindow(
        uint256 _fraudProofWindow
    ) external;

    function sealFraudProofWindow() external;
}
