// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./IDeBridgeGateExtended.sol";

import "./ICrossChainForwarder.sol";
import "./IDlnDestination.sol";
import "./SignatureUtil.sol";
import "./Permit.sol";
import "./ForwarderBase.sol";

contract CrosschainForwarder is ForwarderBase, ICrossChainForwarder {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SignatureUtil for bytes;

    address public constant NATIVE_TOKEN = address(0);

    IDeBridgeGate public deBridgeGate;

    mapping(address => bool) public supportedRouters;

    /* ========== Events ========== */

    event SupportedRouter(address srcSwapRouter, bool isSupported);
    event SwapExecuted(
        address router,
        address tokenIn,
        uint amountIn,
        address tokenOut,
        uint amountOut
    );

    event Refund(
        address token,
        uint256 amount,
        address recipient
    );

    /* ========== ERRORS ========== */

    // swap router didn't put target tokens on this (forwarder's) address
    error SwapEmptyResult(address srcTokenOut);

    error SwapFailed(address srcRouter);

    error NotEnoughSrcFundsIn(uint256 amount);
    error NotSupportedRouter();
    error CallFailed(address target, bytes data);
    error CallCausedBalanceDiscrepancy(address target, address token, uint expectedBalance, uint actualBalance);

    /* ========== STRUCTS ========== */

    struct SwapDetails {
        /// @dev address of a router to call to swap token
        address swapRouter;
        /// @dev calldata for the router
        bytes swapCalldata;

        /// @dev address of an outcome token of a swap described in swapCalladata
        address tokenOut;

        /// @dev expected outcome of a swap
        uint tokenOutExpectedAmount;

        /// @dev remainder of swap outcome (which lefts after subtracting tokenOutExpectedAmount and tokenOutMaxExcessiveAmount
        ///         from the swap outcome)
        address tokenOutRefundRecipient;
    }

    /* ========== INITIALIZERS ========== */

    function initialize(IDeBridgeGate _deBridgeGate) external initializer {
        ForwarderBase.initializeBase();
        deBridgeGate = _deBridgeGate;
    }

    /* ========== PUBLIC METHODS ========== */

    function sendV2(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        bytes memory _srcTokenInPermitEnvelope,
        GateParams memory _gateParams
    ) external payable override {
        _obtainSrcTokenIn(_srcTokenIn, _srcAmountIn, _srcTokenInPermitEnvelope);
        _sendToBridge(_srcTokenIn, _srcAmountIn, msg.value, _gateParams);
    }

    function sendV3(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        bytes memory _srcTokenInPermitEnvelope,
        uint256 _affiliateFeeAmount,
        address _affiliateFeeRecipient,
        GateParams memory _gateParams
    ) external payable override {
        _obtainSrcTokenIn(_srcTokenIn, _srcAmountIn, _srcTokenInPermitEnvelope);
        (uint256 srcAmountInAfterFee, uint256 msgValueAfterFee) = _distributeAffiliateFee(
            _srcTokenIn,
            _srcAmountIn,
            _affiliateFeeAmount,
            _affiliateFeeRecipient
        );

        _sendToBridge(_srcTokenIn, srcAmountInAfterFee, msgValueAfterFee, _gateParams);
    }

    function swapAndSendV3(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        bytes memory _srcTokenInPermitEnvelope,
        uint256 _affiliateFeeAmount,
        address _affiliateFeeRecipient,
        address _srcSwapRouter,
        bytes calldata _srcSwapCalldata,
        address _srcTokenOut,
        GateParams memory _gateParams
    ) external payable override {
        _obtainSrcTokenIn(_srcTokenIn, _srcAmountIn, _srcTokenInPermitEnvelope);
        (uint256 srcAmountInAfterFee, uint256 msgValueAfterFee) = _distributeAffiliateFee(
            _srcTokenIn,
            _srcAmountIn,
            _affiliateFeeAmount,
            _affiliateFeeRecipient
        );

        (uint256 srcAmountOut, uint256 msgValueAfterSwap) = _performSwap(
            _srcTokenIn,
            srcAmountInAfterFee,
            msgValueAfterFee,
            _srcSwapRouter,
            _srcSwapCalldata,
            _srcTokenOut
        );

        _sendToBridge(_srcTokenOut, srcAmountOut, msgValueAfterSwap, _gateParams);
    }

    function swapAndSendV2(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        bytes memory _srcTokenInPermitEnvelope,
        address _srcSwapRouter,
        bytes calldata _srcSwapCalldata,
        address _srcTokenOut,
        GateParams memory _gateParams
    ) external payable override {
        _obtainSrcTokenIn(_srcTokenIn, _srcAmountIn, _srcTokenInPermitEnvelope);

        (uint256 srcAmountOut, uint256 msgValueAfterSwap) = _performSwap(
            _srcTokenIn,
            _srcAmountIn,
            msg.value,
            _srcSwapRouter,
            _srcSwapCalldata,
            _srcTokenOut
        );

        _sendToBridge(_srcTokenOut, srcAmountOut, msgValueAfterSwap, _gateParams);
    }


    /// @dev Performs swap against arbitrary input token, refunds excessive outcome of such swap (if any),
    ///      and calls the specified receiver supplying the outcome of the swap
    /// @param _srcTokenIn arbitrary input token to swap from
    /// @param _srcAmountIn amount of input token to swap
    /// @param _srcTokenInPermitEnvelope optional permit envelope to grab the token from the caller. bytes (amount + deadline + signature)
    /// @param _swapDetails details on how to deal with swap outcome
    /// @param _target DLN contract to call after successful swap
    /// @param _targetData calldata to call against _target
    /// @param _orderId Id of an order to be fulfilled
    function strictlySwapAndCallDln(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        bytes memory _srcTokenInPermitEnvelope,

        SwapDetails calldata _swapDetails,

        address _target,
        bytes calldata _targetData,
        bytes32 _orderId
    ) external payable {
        // check order status as early as possible to safe gas: DLN market is highly concurrent, and txns attempting
        // to fulfill the same order may occur in the same block
        // _target is checked later when invoking _callCustom()
        {
            (
                uint8 status,
                /*address takerAddress*/,
                /*uint256 giveChainId*/
            ) = IDlnDestination(_target).takeOrders(_orderId);
            // use require() instead of custom error because string error gives more clarity:
            // it is shown on Etherscan as well as on Tenderly
            require(status == 0, "ORDER_FULFILLED_OR_CANCELLED");
        }
        _strictlySwapAndCall(
            _srcTokenIn,
            _srcAmountIn,
            _srcTokenInPermitEnvelope,
            _swapDetails.swapRouter,
            _swapDetails.swapCalldata,
            _swapDetails.tokenOut,
            _swapDetails.tokenOutExpectedAmount,
            _swapDetails.tokenOutRefundRecipient,

            _target,
            _targetData
        );
    }


    /// @dev Performs swap against arbitrary input token, refunds excessive outcome of such swap (if any),
    ///      and calls the specified receiver supplying the outcome of the swap
    /// @param _srcTokenIn arbitrary input token to swap from
    /// @param _srcAmountIn amount of input token to swap
    /// @param _srcTokenInPermitEnvelope optional permit envelope to grab the token from the caller. bytes (amount + deadline + signature)
    /// @param _srcSwapRouter contract to call that performs swap from the input token to the output token
    /// @param _srcSwapCalldata calldata to call against _srcSwapRouter
    /// @param _srcTokenOut arbitrary output token to swap to
    /// @param _srcTokenExpectedAmountOut minimum acceptable outcome of the swap to provide to _target
    /// @param _srcTokenRefundRecipient address to send excessive outcome of the swap
    /// @param _target contract to call after successful swap
    /// @param _targetData calldata to call against _target
    function strictlySwapAndCall(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        bytes memory _srcTokenInPermitEnvelope,
        address _srcSwapRouter,
        bytes calldata _srcSwapCalldata,

        address _srcTokenOut,
        uint _srcTokenExpectedAmountOut,
        address _srcTokenRefundRecipient,

        address _target,
        bytes calldata _targetData
    ) external payable {
       _strictlySwapAndCall(
            _srcTokenIn,
            _srcAmountIn,
            _srcTokenInPermitEnvelope,
            _srcSwapRouter,
            _srcSwapCalldata,

            _srcTokenOut,
            _srcTokenExpectedAmountOut,
            _srcTokenRefundRecipient,

            _target,
            _targetData
        );
    }

    /* ========== INTERNAL METHODS ========== */

    function _strictlySwapAndCall(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        bytes memory _srcTokenInPermitEnvelope,
        address _srcSwapRouter,
        bytes calldata _srcSwapCalldata,

        address _srcTokenOut,
        uint _srcTokenExpectedAmountOut,
        address _srcTokenRefundRecipient,

        address _target,
        bytes calldata _targetData
    ) internal {
         //
        // pull the srcInToken from msg.sender
        //
        _obtainSrcTokenIn(_srcTokenIn, _srcAmountIn, _srcTokenInPermitEnvelope);

        //
        // swap srcInToken to srcOutToken
        //
        (uint256 srcAmountOut, uint256 msgValueAfterSwap) = _performSwap(
            _srcTokenIn,
            _srcAmountIn,
            msg.value,
            _srcSwapRouter,
            _srcSwapCalldata,
            _srcTokenOut
        );

        //
        // refund excessive srcTokenOut
        //
        if (_srcTokenExpectedAmountOut > srcAmountOut) {
            // swap returned less than expected - revert the whole txn
            revert NotEnoughSrcFundsIn(_srcTokenExpectedAmountOut);
        }
        else if (_srcTokenExpectedAmountOut < srcAmountOut) {
            // swap returned more than expected - refund
            uint refundAmount = srcAmountOut - _srcTokenExpectedAmountOut;

            // for native token - don't forget to decrease msg.value
            if (_srcTokenOut == NATIVE_TOKEN) {
                payable(_srcTokenRefundRecipient).transfer(refundAmount);
                msgValueAfterSwap -= refundAmount;
            }
            else {
                IERC20Upgradeable(_srcTokenOut).safeTransfer(_srcTokenRefundRecipient, refundAmount);
            }
            emit Refund(_srcTokenOut, refundAmount, _srcTokenRefundRecipient);
        }

        //
        // do the target call
        //
        _performTargetCall(_target, _targetData, msgValueAfterSwap, _srcTokenOut, _srcTokenExpectedAmountOut);
    }

    function _performTargetCall(address _target, bytes calldata _targetData, uint _targetValue, address _srcTokenOut, uint _srcAmountOut) internal {
        // we check both native and erc-20 balance before the call
        // For sure, we can use only one call of _getBalance, but we still must be
        // sure that native currency has the correct accounting after the call
        // where erc-20 was used
        uint tokenBalanceBeforeCall = _getBalance(_srcTokenOut);
        uint balanceBeforeCall = _getBalance(address(0));

        // do the call
        if (_srcTokenOut != NATIVE_TOKEN) {
            _lazyApprove(_srcTokenOut, _target, _srcAmountOut);
        }
        _callCustom(_target, _targetData, _targetValue);

        // check balances
        uint tokenBalanceAfterCall = _getBalance(_srcTokenOut);
        uint balanceAfterCall = _getBalance(address(0));

        // ensure _target has pulled all tokens from this contract
        if ((tokenBalanceBeforeCall - tokenBalanceAfterCall) < _srcAmountOut) {
            revert CallCausedBalanceDiscrepancy(_target, _srcTokenOut, tokenBalanceBeforeCall - _srcAmountOut, tokenBalanceBeforeCall - tokenBalanceAfterCall);
        }

        if ((balanceBeforeCall - balanceAfterCall) < _targetValue) {
            revert CallCausedBalanceDiscrepancy(_target, address(0), tokenBalanceBeforeCall - _targetValue, balanceBeforeCall - balanceAfterCall);
        }
    }

    function _getBalance(address _token) internal view returns (uint) {
        if (_token == NATIVE_TOKEN) {
            return payable(this).balance;
        }
        else {
            return IERC20Upgradeable(_token).balanceOf(address(this));
        }
    }

    function _distributeAffiliateFee(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        uint256 _affiliateFeeAmount,
        address _affiliateFeeRecipient
    ) internal returns (uint256 srcAmountInCleared, uint256 msgValueInCleared) {
        srcAmountInCleared = _srcAmountIn;
        msgValueInCleared = msg.value;

        if (_affiliateFeeAmount > 0 && _affiliateFeeRecipient != address(0)) {
            // cut off fee from srcAmountInCleared
            srcAmountInCleared -= _affiliateFeeAmount;

            if (_srcTokenIn == NATIVE_TOKEN) {
                // reduce value as well!
                msgValueInCleared -= _affiliateFeeAmount;

                (bool success, ) = _affiliateFeeRecipient.call{
                    value: _affiliateFeeAmount
                }("");
                if (!success) {
                    revert AffiliateFeeDistributionFailed(
                        _affiliateFeeRecipient,
                        NATIVE_TOKEN,
                        _affiliateFeeAmount
                    );
                }
            } else {
                IERC20Upgradeable(_srcTokenIn).safeTransfer(
                    _affiliateFeeRecipient,
                    _affiliateFeeAmount
                );
            }
        }
    }

    function _obtainSrcTokenIn(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        bytes memory _srcTokenInPermitEnvelope
    ) internal {
        if (_srcTokenIn == NATIVE_TOKEN) {
            // TODO check that msg.value = srcAmountIn + globalFixedNativeFee,
            if (address(this).balance < _srcAmountIn)
                revert NotEnoughSrcFundsIn(_srcAmountIn);
        } else {
            uint256 srcAmountCleared = _collectSrcERC20In(
                IERC20Upgradeable(_srcTokenIn),
                _srcAmountIn,
                _srcTokenInPermitEnvelope
            );
            if (srcAmountCleared < _srcAmountIn)
                revert NotEnoughSrcFundsIn(_srcAmountIn);
        }
    }

    function _performSwap(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        uint256 _msgValue,
        address _srcSwapRouter,
        bytes calldata _srcSwapCalldata,
        address _srcTokenOut
    ) internal returns (uint256 srcAmountOut, uint256 msgValueAfterSwap) {
        if (!supportedRouters[_srcSwapRouter]) revert NotSupportedRouter();

        uint256 ethBalanceBefore = address(this).balance - _msgValue;

        if (_srcTokenIn == NATIVE_TOKEN) {
            srcAmountOut = _swapToERC20Via(
                _srcSwapRouter,
                _srcSwapCalldata,
                _srcAmountIn,
                IERC20Upgradeable(_srcTokenOut)
            );
        } else {
            _lazyApprove(_srcTokenIn, _srcSwapRouter, _srcAmountIn);
            if (_srcTokenOut == NATIVE_TOKEN) {
                srcAmountOut = _swapToETHVia(_srcSwapRouter, _srcSwapCalldata);
            } else {
                srcAmountOut = _swapToERC20Via(
                    _srcSwapRouter,
                    _srcSwapCalldata,
                    0, /*value*/
                    IERC20Upgradeable(_srcTokenOut)
                );
            }
        }

        emit SwapExecuted(_srcSwapRouter, _srcTokenIn, _srcAmountIn, _srcTokenOut, srcAmountOut);

        msgValueAfterSwap = address(this).balance - ethBalanceBefore;
    }

    function _collectSrcERC20In(
        IERC20Upgradeable _token,
        uint256 _amount,
        bytes memory _permitEnvelope
    ) internal returns (uint256) {
        // call permit before transferring token
        Permit.executePermit(address(_token), _permitEnvelope);

        uint256 balanceBefore = _token.balanceOf(address(this));
        _token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 balanceAfter = _token.balanceOf(address(this));

        if (!(balanceAfter > balanceBefore))
            revert NotEnoughSrcFundsIn(_amount);

        return (balanceAfter - balanceBefore);
    }

    function _swapToETHVia(address _router, bytes calldata _calldata)
        internal
        returns (uint256)
    {
        uint256 balanceBefore = address(this).balance;

        _callCustom(_router, _calldata, 0);

        uint256 balanceAfter = address(this).balance;

        if (balanceBefore >= balanceAfter) revert SwapEmptyResult(address(0));

        uint256 swapDstTokenBalance = balanceAfter - balanceBefore;
        return swapDstTokenBalance;
    }

    function _swapToERC20Via(
        address _router,
        bytes calldata _calldata,
        uint256 _msgValue,
        IERC20Upgradeable _targetToken
    ) internal returns (uint256) {
        uint256 balanceBefore = _targetToken.balanceOf(address(this));

        _callCustom(_router, _calldata, _msgValue);

        uint256 balanceAfter = _targetToken.balanceOf(address(this));
        if (balanceBefore >= balanceAfter)
            revert SwapEmptyResult(address(_targetToken));

        uint256 swapDstTokenBalance = balanceAfter - balanceBefore;
        return swapDstTokenBalance;
    }

    function _sendToBridge(
        address token,
        uint256 amount,
        uint256 _msgValue,
        GateParams memory _gateParams
    ) internal {
        // remember balance to correctly calc the change
        uint256 ethBalanceBefore = address(this).balance - _msgValue;

        if (token != NATIVE_TOKEN) {
            // allow deBridge gate to take all these wrapped tokens
            _lazyApprove(token, address(deBridgeGate), amount);
        }

        // send to deBridge gate
        // TODO: re-calc value
        deBridgeGate.send{value: _msgValue}(
            token, // _tokenAddress
            amount, // _amount
            _gateParams.chainId, // _chainIdTo
            abi.encodePacked(_gateParams.receiver), // _receiver
            "", // _permit
            _gateParams.useAssetFee, // _useAssetFee
            _gateParams.referralCode, // _referralCode
            _gateParams.autoParams // _autoParams
        );

        // return change, if any
        if (address(this).balance > ethBalanceBefore) {
            _safeTransferETH(
                msg.sender,
                address(this).balance - ethBalanceBefore
            );
        }
    }

    function _lazyApprove(address _tokenAddress, address _spender, uint256 _amount) internal {
        IERC20Upgradeable token = IERC20Upgradeable(_tokenAddress);
        uint256 currentAllowance = token.allowance(address(this), _spender);

        if (currentAllowance < _amount) {
            // if an approval was issued before
            token.safeApprove(_spender, 0);
            // create permanent approve
            token.safeApprove(_spender, type(uint256).max);
        }
    }

    function _callCustom(address _to, bytes calldata _data, uint _msgValue) internal {
        if (!supportedRouters[_to]) revert NotSupportedRouter();
        (bool success, bytes memory returnData) = _to.call{value: _msgValue}(_data);
        if (!success) {
            revert CallFailed(_to, returnData);
        }
    }

    // ============ ADM ============

    function updateSupportedRouter(address _srcSwapRouter, bool _isSupported)
        external
        onlyAdmin
    {
        supportedRouters[_srcSwapRouter] = _isSupported;
        emit SupportedRouter(_srcSwapRouter, _isSupported);
    }

    function rescueFunds(address token, address recipient, uint256 amount) external onlyAdmin {
        if (token == NATIVE_TOKEN) {
            _safeTransferETH(recipient, amount);
        }
        else {
            IERC20Upgradeable(token).safeTransfer(recipient, amount);
        }
    }

    // ============ Version Control ============

    /// @dev Get this contract's version
    function version() external pure returns (uint256) {
        return 210; // 2.1.0
    }
}
