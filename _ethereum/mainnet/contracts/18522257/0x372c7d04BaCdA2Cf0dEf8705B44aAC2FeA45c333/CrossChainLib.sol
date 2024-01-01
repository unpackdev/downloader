// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library CrossChainLib {
    /**
     * @notice Supported cross-chain operations
     */
    uint8 public constant LEVERAGE = 1;
    uint8 public constant FLASH_REPAY = 2;

    function getOperationType(bytes memory payload_) internal pure returns (uint8 _op) {
        (_op, ) = abi.decode(payload_, (uint8, bytes));
    }

    function encodeLeverageCallbackPayload(
        address srcSmartFarmingManager_,
        uint256 requestId_
    ) internal pure returns (bytes memory _payload) {
        return abi.encode(LEVERAGE, abi.encode(srcSmartFarmingManager_, requestId_));
    }

    function decodeLeverageCallbackPayload(
        bytes memory payload_
    ) internal pure returns (address _srcSmartFarmingManager, uint256 _requestId) {
        (, payload_) = abi.decode(payload_, (uint8, bytes));
        return abi.decode(payload_, (address, uint256));
    }

    function encodeFlashRepayCallbackPayload(
        address srcProxyOFT_,
        address srcSmartFarmingManager_,
        uint256 requestId_
    ) internal pure returns (bytes memory _payload) {
        return abi.encode(FLASH_REPAY, abi.encode(srcProxyOFT_, srcSmartFarmingManager_, requestId_));
    }

    function decodeFlashRepayCallbackPayload(
        bytes memory payload_
    ) internal pure returns (address srcProxyOFT_, address _srcSmartFarmingManager, uint256 _requestId) {
        (, payload_) = abi.decode(payload_, (uint8, bytes));
        return abi.decode(payload_, (address, address, uint256));
    }

    function encodeFlashRepaySwapPayload(
        address srcSmartFarmingManager_,
        address dstProxyOFT_,
        uint256 requestId_,
        address account_,
        uint256 amountOutMin_,
        uint256 callbackTxNativeFee_
    ) internal pure returns (bytes memory _payload) {
        return
            abi.encode(
                FLASH_REPAY,
                abi.encode(
                    srcSmartFarmingManager_,
                    dstProxyOFT_,
                    requestId_,
                    account_,
                    amountOutMin_,
                    callbackTxNativeFee_
                )
            );
    }

    function decodeFlashRepaySwapPayload(
        bytes memory payload_
    )
        internal
        pure
        returns (
            address _srcSmartFarmingManager,
            address _dstProxyOFT,
            uint256 _requestId,
            address _account,
            uint256 _amountOutMin,
            uint256 _callbackTxNativeFee
        )
    {
        (, payload_) = abi.decode(payload_, (uint8, bytes));
        return abi.decode(payload_, (address, address, uint256, address, uint256, uint256));
    }

    function encodeLeverageSwapPayload(
        address srcSmartFarmingManager_,
        address dstProxyOFT_,
        uint256 requestId_,
        uint256 sgPoolId_,
        address account_,
        uint256 amountOutMin_,
        uint256 callbackTxNativeFee_
    ) internal pure returns (bytes memory _payload) {
        return
            abi.encode(
                LEVERAGE,
                abi.encode(
                    srcSmartFarmingManager_,
                    dstProxyOFT_,
                    requestId_,
                    sgPoolId_,
                    account_,
                    amountOutMin_,
                    callbackTxNativeFee_
                )
            );
    }

    function decodeLeverageSwapPayload(
        bytes memory payload_
    )
        internal
        pure
        returns (
            address _srcSmartFarmingManager,
            address _dstProxyOFT,
            uint256 _requestId,
            uint256 _sgPoolId,
            address _account,
            uint256 _amountOutMin,
            uint256 _callbackTxNativeFee
        )
    {
        (, payload_) = abi.decode(payload_, (uint8, bytes));
        return abi.decode(payload_, (address, address, uint256, uint256, address, uint256, uint256));
    }

    function encodeLzArgs(
        uint16 dstChainId_,
        uint256 callbackNativeFee_,
        uint64 swapTxGasLimit_
    ) internal pure returns (bytes memory _lzArgs) {
        return abi.encode(dstChainId_, callbackNativeFee_, swapTxGasLimit_);
    }

    function decodeLzArgs(
        bytes memory lzArgs_
    ) internal pure returns (uint16 _dstChainId, uint256 _callbackNativeFee, uint64 _swapTxGasLimit) {
        return abi.decode(lzArgs_, (uint16, uint256, uint64));
    }
}
