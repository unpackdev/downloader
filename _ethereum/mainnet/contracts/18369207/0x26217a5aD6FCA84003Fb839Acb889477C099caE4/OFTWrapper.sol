// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import "./IERC20.sol";
import "./ICommonOFT.sol";
import "./IOFTCore.sol";
import "./IOFTV2.sol";
import "./IOFTWithFee.sol";
import "./ILayerZeroEndpoint.sol";
import "./OFTWrapperBase.sol";
import "./OFTWrapperStatus.sol";
import "./OFTWrapperStorage.sol";
import '../../helpers/RefundHelper.sol' as RefundHelper;
import '../../helpers/TransferHelper.sol' as TransferHelper;

/**
 * @title OFTWrapper
 * @notice The OFT wrapper contract
 */
contract OFTWrapper is OFTWrapperBase, OFTWrapperStatus {
    /**
     * @notice OFT `sendFrom` parameters structure (OFT v2)
     * @param from The owner of token
     * @param dstChainId The destination chain identifier
     * @param toAddress Can be any size depending on the `dstChainId`
     * @param amount The quantity of tokens in wei
     * @param callParams LayerZero call parameters
     */
    struct SendFromParams {
        address from;
        uint16 dstChainId;
        bytes32 toAddress;
        uint256 amount;
        ICommonOFT.LzCallParams callParams;
    }

    /**
     * @notice OFT `sendFrom` parameters structure (OFTWithFee)
     * @param from The owner of token
     * @param dstChainId The destination chain identifier
     * @param toAddress Can be any size depending on the `dstChainId`
     * @param amount The quantity of tokens in wei
     * @param minAmount The minimum amount of tokens to receive on the destination chain
     * @param callParams LayerZero call parameters
     */
    struct SendFromWithMinAmountParams {
        address from;
        uint16 dstChainId;
        bytes32 toAddress;
        uint256 amount;
        uint256 minAmount;
        ICommonOFT.LzCallParams callParams;
    }

    /**
     * @notice OFT `sendFrom` parameters structure (OFT v1)
     * @param from The owner of token
     * @param dstChainId The destination chain identifier
     * @param toAddress Can be any size depending on the `dstChainId`
     * @param amount The quantity of tokens in wei
     * @param refundAddress Refund address
     * @param zroPaymentAddress ZRO payment address
     * @param adapterParams LayerZero adapter parameters
     */
    struct SendFromV1Params {
        address from;
        uint16 dstChainId;
        bytes toAddress;
        uint256 amount;
        address payable refundAddress;
        address zroPaymentAddress;
        bytes adapterParams;
    }

    /**
     * @notice OFT `sendTokens` parameters structure (OmnichainFungibleToken)
     * @param dstChainId Send tokens to this chainId
     * @param to Where to deliver the tokens on the destination chain
     * @param qty How many tokens to send
     * @param zroPaymentAddress ZRO payment address
     * @param adapterParam LayerZero adapter parameters
     */
    struct SendTokensParams {
        uint16 dstChainId;
        bytes to;
        uint256 qty;
        address zroPaymentAddress;
        bytes adapterParam;
    }

    /**
     * @notice OFT `estimateSendFee` parameters structure (OFT v2 and OFTWithFee)
     * @param dstChainId The destination chain identifier
     * @param toAddress Can be any size depending on the `dstChainId`
     * @param amount The quantity of tokens in wei
     * @param useZro The ZRO token payment flag
     * @param adapterParams LayerZero adapter parameters
     */
    struct EstimateSendFeeParams {
        uint16 dstChainId;
        bytes32 toAddress;
        uint256 amount;
        bool useZro;
        bytes adapterParams;
    }

    /**
     * @notice OFT `estimateSendFee` parameters structure (OFT v1)
     * @param dstChainId The destination chain identifier
     * @param toAddress Can be any size depending on the `dstChainId`
     * @param amount The quantity of tokens in wei
     * @param useZro The ZRO token payment flag
     * @param adapterParams LayerZero adapter parameters
     */
    struct EstimateSendFeeV1Params {
        uint16 dstChainId;
        bytes toAddress;
        uint256 amount;
        bool useZro;
        bytes adapterParams;
    }

    /**
     * @notice OFT `estimateSendTokensFee` parameters structure (OmnichainFungibleToken)
     * @param dstChainId The destination chain identifier
     * @param useZro The ZRO token payment flag
     * @param txParameters LayerZero tx parameters
     */
    struct EstimateSendTokensFeeParams {
        uint16 dstChainId;
        bool useZro;
        bytes txParameters;
    }

    uint16 private constant PT_SEND = 0;

    /**
     * @notice Initializes the OFTWrapper contract
     * @param _feeCollector The initial address of the fee collector
     * @param _owner The address of the initial owner of the contract
     */
    constructor(address _feeCollector, address _owner) OFTWrapperBase(_feeCollector) {
        _initOFTWrapperDiamond();

        if (_owner != msg.sender && _owner != address(0)) {
            _setOwner(_owner);
        }
    }

    /**
     * @notice Sends tokens to the destination chain (OFT v2)
     * @param _oft The address of the OFT
     * @param _underlyingToken The address of the underlying token
     * @param _params The `sendFrom` parameters
     * @param _processingFee The processing fee value
     */
    function oftSendFrom(
        IOFTV2 _oft,
        IERC20 _underlyingToken,
        SendFromParams calldata _params,
        uint256 _processingFee
    ) external payable whenNotPaused nonReentrant {
        bool useUnderlyingToken = _beforeSendFrom(
            address(_oft),
            address(_underlyingToken),
            _params.from,
            _params.amount
        );

        _oft.sendFrom{ value: msg.value - _processingFee }(
            useUnderlyingToken ? address(this) : _params.from,
            _params.dstChainId,
            _params.toAddress,
            _params.amount,
            _params.callParams
        );

        _afterSendFrom(
            useUnderlyingToken,
            address(_oft),
            address(_underlyingToken),
            _processingFee
        );
    }

    /**
     * @notice Sends tokens to the destination chain (OFTWithFee)
     * @param _oft The address of the OFT
     * @param _underlyingToken The address of the underlying token
     * @param _params The `sendFrom` parameters
     * @param _processingFee The processing fee value
     */
    function oftSendFromWithMinAmount(
        IOFTWithFee _oft,
        IERC20 _underlyingToken,
        SendFromWithMinAmountParams calldata _params,
        uint256 _processingFee
    ) external payable whenNotPaused nonReentrant {
        bool useUnderlyingToken = _beforeSendFrom(
            address(_oft),
            address(_underlyingToken),
            _params.from,
            _params.amount
        );

        _oft.sendFrom{ value: msg.value - _processingFee }(
            useUnderlyingToken ? address(this) : _params.from,
            _params.dstChainId,
            _params.toAddress,
            _params.amount,
            _params.minAmount,
            _params.callParams
        );

        _afterSendFrom(
            useUnderlyingToken,
            address(_oft),
            address(_underlyingToken),
            _processingFee
        );
    }

    /**
     * @notice Sends tokens to the destination chain (OFT v1)
     * @param _oft The address of the OFT
     * @param _underlyingToken The address of the underlying token
     * @param _params The `sendFrom` parameters
     * @param _processingFee The processing fee value
     */
    function oftSendFromV1(
        IOFTCore _oft,
        IERC20 _underlyingToken,
        SendFromV1Params calldata _params,
        uint256 _processingFee
    ) external payable whenNotPaused nonReentrant {
        bool useUnderlyingToken = _beforeSendFrom(
            address(_oft),
            address(_underlyingToken),
            _params.from,
            _params.amount
        );

        _oft.sendFrom{ value: msg.value - _processingFee }(
            useUnderlyingToken ? address(this) : _params.from,
            _params.dstChainId,
            _params.toAddress,
            _params.amount,
            _params.refundAddress,
            _params.zroPaymentAddress,
            _params.adapterParams
        );

        _afterSendFrom(
            useUnderlyingToken,
            address(_oft),
            address(_underlyingToken),
            _processingFee
        );
    }

    /**
     * @notice Sends tokens to the destination chain (OmnichainFungibleToken)
     * @param _oft The address of the OFT
     * @param _params The `sendTokens` parameters
     * @param _processingFee The processing fee value
     */
    function oftSendTokens(
        IOmnichainFungibleToken _oft,
        SendTokensParams calldata _params,
        uint256 _processingFee
    ) external payable whenNotPaused nonReentrant {
        uint256 initialBalance = address(this).balance - msg.value;

        TransferHelper.safeTransferFrom(address(_oft), msg.sender, address(this), _params.qty);

        _oft.sendTokens{ value: msg.value - _processingFee }(
            _params.dstChainId,
            _params.to,
            _params.qty,
            address(0),
            _params.adapterParam
        );

        TransferHelper.safeTransferNative(OFTWrapperStorage.layout().feeCollector, _processingFee);

        RefundHelper.refundExtraBalance(address(this), initialBalance, payable(msg.sender));

        emit OftSent();
    }

    /**
     * @notice Estimates the cross-chain transfer fees (OFT v2 and OFTWithFee)
     * @param _oft The address of the OFT
     * @param _params The `estimateSendFee` parameters
     * @param _processingFee The processing fee value
     * @return nativeFee Native fee amount
     * @return zroFee ZRO fee amount
     */
    function oftEstimateSendFee(
        ICommonOFT _oft,
        EstimateSendFeeParams calldata _params,
        uint256 _processingFee
    ) external view returns (uint256 nativeFee, uint256 zroFee) {
        (uint256 oftNativeFee, uint256 oftZroFee) = _oft.estimateSendFee(
            _params.dstChainId,
            _params.toAddress,
            _params.amount,
            _params.useZro,
            _params.adapterParams
        );

        return (oftNativeFee + _processingFee, oftZroFee);
    }

    /**
     * @notice Estimates the cross-chain transfer fees (OFT v1)
     * @param _oft The address of the OFT
     * @param _params The `estimateSendFee` parameters
     * @param _processingFee The processing fee value
     * @return nativeFee Native fee amount
     * @return zroFee ZRO fee amount
     */
    function oftEstimateSendV1Fee(
        IOFTCore _oft,
        EstimateSendFeeV1Params calldata _params,
        uint256 _processingFee
    ) external view returns (uint256 nativeFee, uint256 zroFee) {
        (uint256 oftNativeFee, uint256 oftZroFee) = _oft.estimateSendFee(
            _params.dstChainId,
            _params.toAddress,
            _params.amount,
            _params.useZro,
            _params.adapterParams
        );

        return (oftNativeFee + _processingFee, oftZroFee);
    }

    /**
     * @notice Estimates the cross-chain transfer fees (OmnichainFungibleToken)
     * @param _oft The address of the OFT
     * @param _to Where to deliver the tokens on the destination chain
     * @param _qty How many tokens to send
     * @param _params The `estimateFees` parameters
     * @param _processingFee The processing fee value
     * @return nativeFee Native fee amount
     * @return zroFee ZRO fee amount
     */
    function oftEstimateSendTokensFee(
        IOmnichainFungibleToken _oft,
        bytes calldata _to,
        uint256 _qty,
        EstimateSendTokensFeeParams calldata _params,
        uint256 _processingFee
    ) external view returns (uint256 nativeFee, uint256 zroFee) {
        bytes memory payload = abi.encode(_to, _qty);

        (uint256 oftNativeFee, uint256 oftZroFee) = _oft.endpoint().estimateFees(
            _params.dstChainId,
            address(_oft),
            payload,
            _params.useZro,
            _params.txParameters
        );

        return (oftNativeFee + _processingFee, oftZroFee);
    }

    /**
     * @notice Destination gas parameters lookup
     * @param _oftAddress The address of the OFT
     * @param _targetLzChainId The destination chain ID (LayerZero-specific)
     * @return useCustomParameters Custom parameters flag
     * @return minTargetGas Minimum destination gas
     */
    function oftTargetGasParameters(
        address _oftAddress,
        uint16 _targetLzChainId
    ) external view returns (bool useCustomParameters, uint256 minTargetGas) {
        if (ILzParametersConfig(_oftAddress).useCustomAdapterParams()) {
            return (
                true,
                ILzParametersConfig(_oftAddress).minDstGasLookup(_targetLzChainId, PT_SEND)
            );
        } else {
            return (false, 0);
        }
    }

    function _beforeSendFrom(
        address _oftAddress,
        address _underlyingTokenAddress,
        address _paramsFrom,
        uint256 _paramsAmount
    ) private returns (bool useUnderlyingToken) {
        if (_paramsFrom != msg.sender) {
            revert SenderError();
        }

        useUnderlyingToken = (_underlyingTokenAddress != address(0));

        if (useUnderlyingToken) {
            TransferHelper.safeTransferFrom(
                _underlyingTokenAddress,
                _paramsFrom,
                address(this),
                _paramsAmount
            );

            TransferHelper.safeApprove(_underlyingTokenAddress, _oftAddress, _paramsAmount);
        }
    }

    function _afterSendFrom(
        bool _useUnderlyingToken,
        address _oftAddress,
        address _underlyingTokenAddress,
        uint256 _processingFee
    ) private {
        if (_useUnderlyingToken) {
            TransferHelper.safeApprove(_underlyingTokenAddress, _oftAddress, 0);
        }

        TransferHelper.safeTransferNative(OFTWrapperStorage.layout().feeCollector, _processingFee);

        emit OftSent();
    }

    function _initOFTWrapperDiamond() private {
        bytes4[] memory selectors = new bytes4[](8);
        uint256 selectorIndex;

        // register OFT functions

        selectors[selectorIndex++] = OFTWrapper.oftSendFrom.selector;
        selectors[selectorIndex++] = OFTWrapper.oftSendFromWithMinAmount.selector;
        selectors[selectorIndex++] = OFTWrapper.oftSendFromV1.selector;
        selectors[selectorIndex++] = OFTWrapper.oftSendTokens.selector;

        selectors[selectorIndex++] = OFTWrapper.oftEstimateSendFee.selector;
        selectors[selectorIndex++] = OFTWrapper.oftEstimateSendV1Fee.selector;
        selectors[selectorIndex++] = OFTWrapper.oftEstimateSendTokensFee.selector;

        selectors[selectorIndex++] = OFTWrapper.oftTargetGasParameters.selector;

        // diamond cut

        FacetCut[] memory facetCuts = new FacetCut[](1);

        facetCuts[0] = FacetCut({
            target: address(this),
            action: FacetCutAction.ADD,
            selectors: selectors
        });

        _diamondCut(facetCuts, address(0), '');
    }
}

interface ILzParametersConfig {
    function useCustomAdapterParams() external view returns (bool);

    function minDstGasLookup(uint16 _dstChainId, uint16 _type) external view returns (uint256);
}

interface IOmnichainFungibleToken {
    function sendTokens(
        uint16 _dstChainId, // send tokens to this chainId
        bytes calldata _to, // where to deliver the tokens on the destination chain
        uint256 _qty, // how many tokens to send
        address zroPaymentAddress, // ZRO payment address
        bytes calldata adapterParam // LayerZero adapter parameters
    ) external payable;

    function endpoint() external view returns (ILayerZeroEndpoint);
}
