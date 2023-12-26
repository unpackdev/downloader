// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./SafeERC20.sol";
import "./ContractOnlyEthRecipient.sol";
import "./ISwapFacade.sol";
import "./TokenLibrary.sol";
import "./Errors.sol";
import "./Ownable2Step.sol";

/**
 * @title SwapFacade
 * @notice This facade performs minReturn safety checks and holds all approves to ensure safety of all arbitrary calls
 */
contract SwapFacade is ISwapFacade, Ownable2Step {
    using SafeERC20 for IERC20;
    using TokenLibrary for IERC20;

    address public feeCollector;

    constructor(address feeCollector_) {
        if (feeCollector_ == address(0)) {
            revert AddressCannotBeZero();
        }

        feeCollector = feeCollector_;
    }

    /// @notice Performs tokens swap
    /// @param executor Address of low level executor used to make actual swaps
    /// @param amount Amount of source tokens user is willing to swap
    /// @param minReturns Minimal amount of targetToken that user is willing to receive. If not reached transaction reverts
    /// @param targetTokenTransferInfos instructions on how to transfer tokens to target addresses
    /// @param deadline Safety parameter against stalled transactions. If deadline reached swap reverts unconditionally
    /// @param swapDescriptions Descriptions that describe how exactly swaps should be performed
    /// @param permit Signed permit for spending `amount` of tokens. Optional. May be used instead of manually approving tokens before calling `swap`
    function swap(
        ISwapExecutor executor,
        uint256 amount,
        MinReturnInfo[] calldata minReturns,
        ISwapExecutor.TokenTransferInfo[] calldata targetTokenTransferInfos,
        uint256 deadline,
        ISwapExecutor.SwapDescription[] calldata swapDescriptions,
        bytes calldata permit
    ) external payable override returns (uint256[] memory swappedAmounts) {
        {
            // solhint-disable-next-line not-rely-on-time
            if (deadline < block.timestamp) {
                // solhint-disable-next-line not-rely-on-time
                revert TransactionExpired(deadline, block.timestamp);
            }
        }
        if (amount == 0) {
            revert ZeroInput();
        }
        for (uint256 i = 0; i < targetTokenTransferInfos.length; i++) {
            if (targetTokenTransferInfos[i].recipient == address(0)) {
                revert ZeroRecipient();
            }
        }
        if (swapDescriptions.length == 0) {
            revert EmptySwap();
        }

        uint256 collectedFees;
        if (msg.value > 0) {
            if (msg.value != amount) {
                revert EthValueAmountMismatch();
            } else if (permit.length > 0) {
                revert PermitNotAllowedForEthSwap();
            } else if (!TokenLibrary.isEth(swapDescriptions[0].sourceToken)) {
                revert EthValueSourceTokenMismatch();
            }

            collectedFees = address(feeCollector).balance;
        } else {
            if (
                swapDescriptions[0].sourceToken.balanceOf(address(executor)) <
                amount
            ) {
                if (permit.length > 0) {
                    SafeERC20.tryPermit(
                        swapDescriptions[0].sourceToken,
                        permit
                    );
                }
                swapDescriptions[0].sourceToken.safeTransferFrom(
                    msg.sender,
                    address(executor),
                    amount
                );
            }

            collectedFees = swapDescriptions[0].sourceToken.balanceOf(
                feeCollector
            );
        }

        swappedAmounts = _swap(
            executor,
            minReturns,
            targetTokenTransferInfos,
            swapDescriptions
        );

        if (msg.value > 0) {
            collectedFees = address(feeCollector).balance - collectedFees;
        } else {
            collectedFees =
                swapDescriptions[0].sourceToken.balanceOf(feeCollector) -
                collectedFees;
        }

        if (swappedAmounts.length != 1) {
            revert MultiSwapNotAllowed();
        }

        emit Trade(
            msg.sender,
            address(swapDescriptions[0].sourceToken),
            address(minReturns[0].token),
            amount,
            swappedAmounts[0],
            collectedFees
        );

        return swappedAmounts;
    }

    /// @notice Performs tokens swap and validates swap success against minReturn value
    function _swap(
        ISwapExecutor executor,
        MinReturnInfo[] calldata minReturns,
        ISwapExecutor.TokenTransferInfo[] calldata targetTokenTransferInfos,
        ISwapExecutor.SwapDescription[] calldata swapDescriptions
    ) private returns (uint256[] memory) {
        uint256[] memory balancesBeforeSwap = new uint256[](minReturns.length);
        for (uint256 i = 0; i < minReturns.length; i++) {
            balancesBeforeSwap[i] = minReturns[i].token.universalBalanceOf(
                minReturns[i].recipient
            );
        }
        executor.executeSwap{value: msg.value}(
            targetTokenTransferInfos,
            swapDescriptions
        );
        uint256[] memory swappedAmounts = new uint256[](minReturns.length);
        for (uint256 i = 0; i < minReturns.length; i++) {
            uint256 balanceBeforeSwap = balancesBeforeSwap[i];
            uint256 balanceAfterSwap = minReturns[i].token.universalBalanceOf(
                minReturns[i].recipient
            );
            uint256 totalSwappedAmount = balanceAfterSwap - balanceBeforeSwap;
            if (totalSwappedAmount < minReturns[i].amount) {
                revert MinReturnError(totalSwappedAmount, minReturns[i].amount);
            }
            swappedAmounts[i] = totalSwappedAmount;
        }
        return swappedAmounts;
    }

    function sweep(IERC20 token, address destination) external onlyOwner {
        token.safeTransfer(destination, IERC20(token).balanceOf(address(this)));
    }

    function updateFeeCollector(address newFeeCollector) external onlyOwner {
        if (newFeeCollector == address(0)) {
            revert AddressCannotBeZero();
        }

        feeCollector = newFeeCollector;
    }
}
