// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./Owned.sol";
import "./ERC20.sol";
import "./SafeTransferLib.sol";
import "./IFeeCollector.sol";
import "./IPermit2.sol";

/// @notice The collector of protocol fees that will be used to swap and send to a fee recipient address.
contract FeeCollector is Owned, IFeeCollector {
    using SafeTransferLib for ERC20;

    error UniversalRouterCallFailed();

    address private immutable universalRouter;

    ERC20 private immutable feeToken;
    IPermit2 private immutable permit2;

    uint256 private constant MAX_APPROVAL_AMOUNT = type(uint256).max;
    uint160 private constant MAX_PERMIT2_APPROVAL_AMOUNT = type(uint160).max;
    uint48 private constant MAX_PERMIT2_DEADLINE = type(uint48).max;

    constructor(address _owner, address _universalRouter, address _permit2, address _feeToken) Owned(_owner) {
        universalRouter = _universalRouter;
        feeToken = ERC20(_feeToken);
        permit2 = IPermit2(_permit2);
    }

    /// @inheritdoc IFeeCollector
    function swapBalance(bytes calldata swapData, uint256 nativeValue) external onlyOwner {
        _execute(swapData, nativeValue);
    }

    /// @inheritdoc IFeeCollector
    function swapBalance(bytes calldata swapData, uint256 nativeValue, ERC20[] calldata tokensToApprove)
        external
        onlyOwner
    {
        unchecked {
            for (uint256 i = 0; i < tokensToApprove.length; i++) {
                tokensToApprove[i].safeApprove(address(permit2), MAX_APPROVAL_AMOUNT);
                permit2.approve(
                    address(tokensToApprove[i]), universalRouter, MAX_PERMIT2_APPROVAL_AMOUNT, MAX_PERMIT2_DEADLINE
                );
            }
        }

        _execute(swapData, nativeValue);
    }

    /// @notice Helper function to call UniversalRouter.
    /// @param swapData The bytes call data to be forwarded to UniversalRouter.
    /// @param nativeValue The amount of native currency to send to UniversalRouter.
    function _execute(bytes calldata swapData, uint256 nativeValue) internal {
        (bool success,) = universalRouter.call{value: nativeValue}(swapData);
        if (!success) revert UniversalRouterCallFailed();
    }

    /// @inheritdoc IFeeCollector
    function withdrawFeeToken(address feeRecipient, uint256 amount) external onlyOwner {
        feeToken.safeTransfer(feeRecipient, amount);
    }

    receive() external payable {}
}
