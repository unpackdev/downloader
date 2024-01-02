// SPDX-License-Identifier: UNLICENSED
// Zaap.exchange Contracts (ZaapOut.sol)
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./Pausable.sol";

import "./NativeWrapper.sol";
import "./Swapper.sol";

import "./IStargateReceiver.sol";
import "./IWETH9.sol";
import "./IERC20.sol";

import "./TransferHelper.sol";

abstract contract ZaapOut is Ownable, Pausable, NativeWrapper, Swapper, IStargateReceiver {
    address public immutable stargateRouterAddress;

    event ZaapErrored(string reason);
    event ZaapedOut(
        uint16 srcChainId,
        bytes srcAddress,
        uint nonce,
        address bridgeTokenAddress,
        uint bridgeAmountIn,
        address dstTokenAddress,
        uint256 dstTokenAmountOut,
        address dstRecipientAddress
    );

    constructor(address stargateRouterAddress_) {
        stargateRouterAddress = stargateRouterAddress_;
    }

    function sgReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint nonce,
        address bridgeTokenAddress,
        uint bridgeAmountIn,
        bytes memory payload
    ) external whenNotPaused {
        require(msg.sender == address(stargateRouterAddress), "ZaapOut: `msg.sender` must be `stargateRouterAddress`");
        require(bridgeAmountIn > 0, "ZaapOut: `bridgeAmountIn` must be > 0");

        (SwapParams[] memory dstSwapsParams, address dstTokenAddress, address dstRecipientAddress) = abi.decode(payload, (SwapParams[], address, address));

        if (bridgeTokenAddress != dstTokenAddress) {
            bool dstTokenIsNative = dstTokenAddress == NATIVE_TOKEN_ADDRESS;

            if (dstSwapsParams.length > 0) {
                (uint256 totalAmountOut, bool errored) = _swapExact(
                    bridgeAmountIn,
                    dstSwapsParams,
                    bridgeTokenAddress,
                    dstTokenIsNative ? address(wETH9) : dstTokenAddress,
                    false
                );
                if (errored == false) {
                    // Unwrapping if needed
                    if (dstTokenIsNative) {
                        wETH9.withdraw(totalAmountOut);
                        TransferHelper.safeTransferETH(dstRecipientAddress, totalAmountOut);
                    } else {
                        TransferHelper.safeTransfer(dstTokenAddress, dstRecipientAddress, totalAmountOut);
                    }
                    emit ZaapedOut(srcChainId, srcAddress, nonce, bridgeTokenAddress, bridgeAmountIn, dstTokenAddress, totalAmountOut, dstRecipientAddress);
                } else {
                    if (totalAmountOut > 0) {
                        // Unwrapping if needed
                        if (dstTokenIsNative) {
                            wETH9.withdraw(totalAmountOut);
                            TransferHelper.safeTransferETH(dstRecipientAddress, totalAmountOut);
                        } else {
                            TransferHelper.safeTransfer(dstTokenAddress, dstRecipientAddress, totalAmountOut);
                        }
                    }
                    uint256 bridgeAmountInLeft = IERC20(bridgeTokenAddress).balanceOf(address(this));
                    if (bridgeAmountInLeft > 0) {
                        TransferHelper.safeTransfer(bridgeTokenAddress, dstRecipientAddress, bridgeAmountInLeft);
                    }
                    emit ZaapErrored("ZaapOut: `_swap` errored");
                }
            } else {
                TransferHelper.safeTransfer(bridgeTokenAddress, dstRecipientAddress, bridgeAmountIn);
                emit ZaapErrored("ZaapOut: `dstSwapsParams` must not be empty if `bridgeTokenAddress` != `dstTokenAddress`");
            }
        } else {
            TransferHelper.safeTransfer(bridgeTokenAddress, dstRecipientAddress, bridgeAmountIn);
            emit ZaapedOut(srcChainId, srcAddress, nonce, bridgeTokenAddress, bridgeAmountIn, dstTokenAddress, bridgeAmountIn, dstRecipientAddress);
        }
    }

    function pauseOut() external virtual onlyOwner {
        _pause();
    }

    function unpauseOut() external virtual onlyOwner {
        _unpause();
    }

    receive() external payable {}
}
