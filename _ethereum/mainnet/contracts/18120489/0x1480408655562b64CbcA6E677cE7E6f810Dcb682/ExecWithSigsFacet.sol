// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./BFacetOwner.sol";
import "./LibDiamond.sol";
import "./GelatoBytes.sol";
import "./ExecWithSigsBase.sol";
import "./GelatoCallUtils.sol";
import "./Utils.sol";
import "./CallTypes.sol";
import "./SignerStorage.sol";
import "./ECDSA.sol";
import "./GelatoRelayUtils.sol";

contract ExecWithSigsFacet is ExecWithSigsBase, BFacetOwner {
    using GelatoCallUtils for address;
    using LibDiamond for address;

    //solhint-disable-next-line const-name-snakecase
    string public constant name = "ExecWithSigsFacet";
    //solhint-disable-next-line const-name-snakecase
    string public constant version = "1";

    address public immutable feeCollector;

    event LogExecWithSigsTrackFee(
        bytes32 correlationId,
        MessageTrackFee msg,
        address indexed executorSigner,
        address indexed checkerSigner,
        uint256 observedFee,
        uint256 estimatedGasUsed,
        address sender
    );

    event LogExecWithSigs(
        bytes32 correlationId,
        Message msg,
        address indexed executorSigner,
        address indexed checkerSigner,
        uint256 estimatedGasUsed,
        address sender
    );

    event LogExecWithSigsFeeCollector(
        bytes32 correlationId,
        MessageFeeCollector msg,
        address indexed executorSigner,
        address indexed checkerSigner,
        uint256 observedFee,
        uint256 estimatedGasUsed,
        address sender
    );

    event LogExecWithSigsRelayContext(
        bytes32 correlationId,
        MessageRelayContext msg,
        address indexed executorSigner,
        address indexed checkerSigner,
        uint256 observedFee,
        uint256 estimatedGasUsed,
        address sender
    );

    constructor(address _feeCollector) {
        feeCollector = _feeCollector;
    }

    // solhint-disable function-max-lines
    /// @param _call Execution payload packed into ExecWithSigsTrackFee struct
    /// @return estimatedGasUsed Estimated gas used using gas metering
    /// @return observedFee The fee transferred to the fee collector or diamond
    function execWithSigsTrackFee(
        ExecWithSigsTrackFee calldata _call
    ) external returns (uint256 estimatedGasUsed, uint256 observedFee) {
        uint256 startGas = gasleft();

        require(
            msg.sender == tx.origin,
            "ExecWithSigsFacet.execWithSigsTrackFee: only EOAs"
        );

        _requireSignerDeadline(
            _call.msg.deadline,
            "ExecWithSigsFacet.execWithSigsTrackFee._requireSignerDeadline:"
        );

        bytes32 digest = _getDigestTrackFee(_getDomainSeparator(), _call.msg);

        address executorSigner = _requireExecutorSignerSignature(
            digest,
            _call.executorSignerSig,
            "ExecWithSigsFacet.execWithSigsTrackFee._requireExecutorSignerSignature:"
        );

        address checkerSigner = _requireCheckerSignerSignature(
            digest,
            _call.checkerSignerSig,
            "ExecWithSigsFacet.execWithSigsTrackFee._requireCheckerSignerSignature:"
        );

        address feeRecipient = _call.msg.isFeeCollector
            ? feeCollector
            : address(this);

        {
            uint256 preFeeTokenBalance = _getBalance(
                _call.msg.feeToken,
                feeRecipient
            );

            // call forward
            _call.msg.service.revertingContractCall(
                _call.msg.data,
                "ExecWithSigsFacet.execWithSigsTrackFee:"
            );

            uint256 postFeeTokenBalance = _getBalance(
                _call.msg.feeToken,
                feeRecipient
            );

            observedFee = postFeeTokenBalance - preFeeTokenBalance;
        }

        estimatedGasUsed = startGas - gasleft();

        emit LogExecWithSigsTrackFee(
            _call.correlationId,
            _call.msg,
            executorSigner,
            checkerSigner,
            observedFee,
            estimatedGasUsed,
            msg.sender
        );
    }

    // solhint-disable function-max-lines
    /// @param _call Execution payload packed into ExecWithSigs struct
    /// @return estimatedGasUsed Estimated gas used using gas metering
    function execWithSigs(
        ExecWithSigs calldata _call
    ) external returns (uint256 estimatedGasUsed) {
        uint256 startGas = gasleft();

        require(
            msg.sender == tx.origin,
            "ExecWithSigsFacet.execWithSigs: only EOAs"
        );

        _requireSignerDeadline(
            _call.msg.deadline,
            "ExecWithSigsFacet.execWithSigs._requireSignerDeadline:"
        );

        bytes32 digest = _getDigest(_getDomainSeparator(), _call.msg);

        address executorSigner = _requireExecutorSignerSignature(
            digest,
            _call.executorSignerSig,
            "ExecWithSigsFacet.execWithSigs._requireExecutorSignerSignature:"
        );

        address checkerSigner = _requireCheckerSignerSignature(
            digest,
            _call.checkerSignerSig,
            "ExecWithSigsFacet.execWithSigs._requireCheckerSignerSignature:"
        );

        // call forward
        _call.msg.service.revertingContractCall(
            _call.msg.data,
            "ExecWithSigsFacet.execWithSigs:"
        );

        estimatedGasUsed = startGas - gasleft();

        emit LogExecWithSigs(
            _call.correlationId,
            _call.msg,
            executorSigner,
            checkerSigner,
            estimatedGasUsed,
            msg.sender
        );
    }

    // solhint-disable function-max-lines
    /// @param _call Execution payload packed into ExecWithSigsFeeCollector struct
    /// @return estimatedGasUsed Estimated gas used using gas metering
    /// @return observedFee The fee transferred to the fee collector
    function execWithSigsFeeCollector(
        ExecWithSigsFeeCollector calldata _call
    ) external returns (uint256 estimatedGasUsed, uint256 observedFee) {
        uint256 startGas = gasleft();

        require(
            msg.sender == tx.origin,
            "ExecWithSigsFacet.execWithSigsFeeCollector: only EOAs"
        );

        _requireSignerDeadline(
            _call.msg.deadline,
            "ExecWithSigsFacet.execWithSigsFeeCollector._requireSignerDeadline:"
        );

        bytes32 digest = _getDigestFeeCollector(
            _getDomainSeparator(),
            _call.msg
        );

        address executorSigner = _requireExecutorSignerSignature(
            digest,
            _call.executorSignerSig,
            "ExecWithSigsFacet.execWithSigsFeeCollector._requireExecutorSignerSignature:"
        );

        address checkerSigner = _requireCheckerSignerSignature(
            digest,
            _call.checkerSignerSig,
            "ExecWithSigsFacet.execWithSigsFeeCollector._requireCheckerSignerSignature:"
        );

        {
            uint256 preFeeTokenBalance = _getBalance(
                _call.msg.feeToken,
                feeCollector
            );

            // call forward + append fee collector
            _call.msg.service.revertingContractCall(
                _encodeFeeCollector(_call.msg.data, feeCollector),
                "ExecWithSigsFacet.execWithSigsFeeCollector:"
            );

            uint256 postFeeTokenBalance = _getBalance(
                _call.msg.feeToken,
                feeCollector
            );

            observedFee = postFeeTokenBalance - preFeeTokenBalance;
        }

        estimatedGasUsed = startGas - gasleft();

        emit LogExecWithSigsFeeCollector(
            _call.correlationId,
            _call.msg,
            executorSigner,
            checkerSigner,
            observedFee,
            estimatedGasUsed,
            msg.sender
        );
    }

    // solhint-disable function-max-lines
    /// @param _call Execution payload packed into ExecWithSigsRelayContext struct
    /// @return estimatedGasUsed Estimated gas used using gas metering
    /// @return observedFee The fee transferred to the fee collector
    function execWithSigsRelayContext(
        ExecWithSigsRelayContext calldata _call
    ) external returns (uint256 estimatedGasUsed, uint256 observedFee) {
        uint256 startGas = gasleft();

        require(
            msg.sender == tx.origin,
            "ExecWithSigsFacet.execWithSigsRelayContext: only EOAs"
        );

        _requireSignerDeadline(
            _call.msg.deadline,
            "ExecWithSigsFacet.execWithSigsRelayContext._requireSignerDeadline:"
        );

        bytes32 digest = _getDigestRelayContext(
            _getDomainSeparator(),
            _call.msg
        );

        address executorSigner = _requireExecutorSignerSignature(
            digest,
            _call.executorSignerSig,
            "ExecWithSigsFacet.execWithSigsRelayContext._requireExecutorSignerSignature:"
        );

        address checkerSigner = _requireCheckerSignerSignature(
            digest,
            _call.checkerSignerSig,
            "ExecWithSigsFacet.execWithSigsRelayContext._requireCheckerSignerSignature:"
        );

        {
            uint256 preFeeTokenBalance = _getBalance(
                _call.msg.feeToken,
                feeCollector
            );

            // call forward + append fee collector, feeToken, fee
            _call.msg.service.revertingContractCall(
                _encodeRelayContext(
                    _call.msg.data,
                    feeCollector,
                    _call.msg.feeToken,
                    _call.msg.fee
                ),
                "ExecWithSigsFacet.execWithSigsRelayContext:"
            );

            uint256 postFeeTokenBalance = _getBalance(
                _call.msg.feeToken,
                feeCollector
            );

            observedFee = postFeeTokenBalance - preFeeTokenBalance;
        }

        estimatedGasUsed = startGas - gasleft();

        emit LogExecWithSigsRelayContext(
            _call.correlationId,
            _call.msg,
            executorSigner,
            checkerSigner,
            observedFee,
            estimatedGasUsed,
            msg.sender
        );
    }

    /// @dev Used for off-chain simulation only!
    function simulateExecWithSigsTrackFee(
        address _service,
        bytes calldata _data,
        address _feeToken
    )
        external
        returns (
            uint256 estimatedGasUsed,
            uint256 observedFee,
            bool isFeeCollector
        )
    {
        uint256 startGas = gasleft();

        uint256 preFeeCollectorBalance = _getBalance(_feeToken, feeCollector);
        uint256 preDiamondBalance = _getBalance(_feeToken, address(this));

        (bool success, bytes memory returndata) = _service.call(_data);

        uint256 observedFeeCollectorFee = _getBalance(_feeToken, feeCollector) -
            preFeeCollectorBalance;
        uint256 observedDiamondFee = _getBalance(_feeToken, address(this)) -
            preDiamondBalance;

        if (observedDiamondFee > observedFeeCollectorFee) {
            observedFee = observedDiamondFee;
        } else {
            observedFee = observedFeeCollectorFee;
            isFeeCollector = true;
        }

        estimatedGasUsed = startGas - gasleft();

        if (tx.origin != address(0) || !success) {
            _revertWithFeeAndIsFeeCollector(
                success,
                isFeeCollector,
                returndata,
                estimatedGasUsed,
                observedFee
            );
        }
    }

    /// @dev Used for off-chain simulation only!
    function simulateExecWithSigs(
        address _service,
        bytes memory _data
    ) external returns (uint256 estimatedGasUsed) {
        uint256 startGas = gasleft();

        (bool success, bytes memory returndata) = _service.call(_data);

        estimatedGasUsed = startGas - gasleft();

        if (tx.origin != address(0) || !success) {
            _revert(success, returndata, estimatedGasUsed);
        }
    }

    /// @dev Used for off-chain simulation only!
    function simulateExecWithSigsFeeCollector(
        address _service,
        bytes calldata _data,
        address _feeToken
    ) external returns (uint256 estimatedGasUsed, uint256 observedFee) {
        uint256 startGas = gasleft();

        uint256 preFeeTokenBalance = _getBalance(_feeToken, feeCollector);

        (bool success, bytes memory returndata) = _service.call(
            _encodeFeeCollector(_data, feeCollector)
        );

        uint256 postFeeTokenBalance = _getBalance(_feeToken, feeCollector);
        observedFee = postFeeTokenBalance - preFeeTokenBalance;
        estimatedGasUsed = startGas - gasleft();

        if (tx.origin != address(0) || !success) {
            _revertWithFee(success, returndata, estimatedGasUsed, observedFee);
        }
    }

    /// @dev Used for off-chain simulation only!
    function simulateExecWithSigsRelayContext(
        address _service,
        bytes calldata _data,
        address _feeToken,
        uint256 _fee
    ) external returns (uint256 estimatedGasUsed, uint256 observedFee) {
        uint256 startGas = gasleft();

        uint256 preFeeTokenBalance = _getBalance(_feeToken, feeCollector);

        (bool success, bytes memory returndata) = _service.call(
            _encodeRelayContext(_data, feeCollector, _feeToken, _fee)
        );

        uint256 postFeeTokenBalance = _getBalance(_feeToken, feeCollector);
        observedFee = postFeeTokenBalance - preFeeTokenBalance;
        estimatedGasUsed = startGas - gasleft();

        if (tx.origin != address(0) || !success) {
            _revertWithFee(success, returndata, estimatedGasUsed, observedFee);
        }
    }

    //solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _getDomainSeparator();
    }

    function _getDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        bytes(
                            //solhint-disable-next-line max-line-length
                            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                        )
                    ),
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    block.chainid,
                    address(this)
                )
            );
    }
}
