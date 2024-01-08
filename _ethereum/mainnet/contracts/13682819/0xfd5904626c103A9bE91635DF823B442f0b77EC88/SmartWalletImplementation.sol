// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./IERC20Ext.sol";
import "./ISmartWalletImplementation.sol";
import "./SmartWalletStorage.sol";
import "./ISwap.sol";
import "./ILending.sol";

contract SmartWalletImplementation is SmartWalletStorageV2, ISmartWalletImplementation {
    using SafeERC20 for IERC20Ext;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    event ApprovedAllowances(IERC20Ext[] tokens, address[] spenders, bool isReset);
    event ClaimedPlatformFees(address[] wallets, IERC20Ext[] tokens, address claimer);

    constructor(address _admin) SmartWalletStorage(_admin) {}

    receive() external payable {}

    /// Claim fee, must be done by platform address itself to avoid confusion
    function claimPlatformFee(IERC20Ext[] calldata tokens)
        external
        override
        nonReentrant
    {
        address platformWallet = msg.sender;
        for (uint256 j = 0; j < tokens.length; j++) {
            uint256 fee = platformWalletFees[platformWallet][tokens[j]];
            if (fee > 1) {
                // fee set to 1 to avoid the SSTORE initial gas cost
                platformWalletFees[platformWallet][tokens[j]] = 1;
                transferToken(payable(platformWallet), tokens[j], fee - 1);
            }
        }
        address[] memory arr = new address[](1);
        arr[0] = platformWallet;
        emit ClaimedPlatformFees(arr, tokens, msg.sender);
    }

    /// Claim fee using admin right
    function adminClaimPlatformFees(address[] calldata platformWallets, IERC20Ext[] calldata tokens)
        external
        override
        nonReentrant
        onlyAdmin
    {
        require(adminFeeCollector != address(0), "require admin fee collector");

        for (uint256 i = 0; i < platformWallets.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                uint256 fee = platformWalletFees[platformWallets[i]][tokens[j]];
                if (fee > 1) {
                    // fee set to 1 to avoid the SSTORE initial gas cost
                    platformWalletFees[platformWallets[i]][tokens[j]] = 1;
                    transferToken(payable(adminFeeCollector), tokens[j], fee - 1);
                }
            }
        }
        emit ClaimedPlatformFees(platformWallets, tokens, msg.sender);
    }

    function setAdminFeeCollector(address feeCollector) external override onlyAdmin {
        adminFeeCollector = feeCollector;
    }

    /// @dev approve/unapprove LPs usage on the particular tokens
    function approveAllowances(
        IERC20Ext[] calldata tokens,
        address[] calldata spenders,
        bool isReset
    ) external onlyAdmin {
        uint256 allowance = isReset ? 0 : MAX_ALLOWANCE;
        for (uint256 i = 0; i < tokens.length; i++) {
            for (uint256 j = 0; j < spenders.length; j++) {
                tokens[i].safeApprove(spenders[j], allowance);
            }
            getSetDecimals(tokens[i]);
        }

        emit ApprovedAllowances(tokens, spenders, isReset);
    }

    /// @dev get expected return including the fee
    /// @return destAmount expected dest amount
    /// @return expectedRate expected swap rate
    function getExpectedReturn(ISmartWalletImplementation.GetExpectedReturnParams calldata params)
        external
        view
        override
        returns (uint256 destAmount, uint256 expectedRate)
    {
        (destAmount, expectedRate,) = getExpectedReturnInternal(params, false);
    }

    function getExpectedReturnWithImpact(
        ISmartWalletImplementation.GetExpectedReturnParams calldata params
    )
        external
        view
        override
        returns (
            uint256 destAmount,
            uint256 expectedRate,
            uint256 priceImpact
        )
    {
        return getExpectedReturnInternal(params, true);
    }

    function getExpectedReturnInternal(
        ISmartWalletImplementation.GetExpectedReturnParams memory params, bool withImpact
    ) private view returns (uint256 destAmount, uint256 expectedRate, uint256 priceImpact) {
        if (params.feeBps >= BPS) return (0, 0, 0); // platform fee is too high

        uint256 actualSrc = (params.feeMode == FeeMode.FROM_SOURCE)
            ? (params.srcAmount * (BPS - params.feeBps)) / BPS
            : params.srcAmount;

        if (withImpact) {
            (destAmount, priceImpact) = ISwap(params.swapContract).getExpectedReturnWithImpact(
                ISwap.GetExpectedReturnParams({
                    srcAmount: actualSrc,
                    tradePath: params.tradePath,
                    feeBps: params.feeMode == FeeMode.BY_PROTOCOL ? params.feeBps : 0,
                    extraArgs: params.extraArgs
                })
            );
        } else {
            destAmount = ISwap(params.swapContract).getExpectedReturn(
                ISwap.GetExpectedReturnParams({
                    srcAmount: actualSrc,
                    tradePath: params.tradePath,
                    feeBps: params.feeMode == FeeMode.BY_PROTOCOL ? params.feeBps : 0,
                    extraArgs: params.extraArgs
                })
            );
        }

        if (params.feeMode == FeeMode.FROM_DEST) {
            destAmount = (destAmount * (BPS - params.feeBps)) / BPS;
        }

        expectedRate = calcRateFromQty(
            params.srcAmount,
            destAmount,
            getDecimals(IERC20Ext(params.tradePath[0])),
            getDecimals(IERC20Ext(params.tradePath[params.tradePath.length - 1]))
        );
    }

    /// @dev get expected in amount including the fee
    /// @return srcAmount expected aource amount
    /// @return expectedRate expected swap rate
    function getExpectedIn(ISmartWalletImplementation.GetExpectedInParams calldata params)
        external
        view
        override
        returns (uint256 srcAmount, uint256 expectedRate)
    {
        (srcAmount, expectedRate, ) = getExpectedInInternal(params, false);
    }

    function getExpectedInWithImpact(ISmartWalletImplementation.GetExpectedInParams calldata params)
        external
        view
        override
        returns (uint256 srcAmount, uint256 expectedRate, uint256 priceImpact)
    {
        return getExpectedInInternal(params, true);
    }

    /// @dev get expected in amount including the fee
    /// @return srcAmount expected aource amount
    /// @return expectedRate expected swap rate
    function getExpectedInInternal(ISmartWalletImplementation.GetExpectedInParams memory params, bool withImpact)
        private
        view
        returns (uint256 srcAmount, uint256 expectedRate, uint256 priceImpact)
    {
        if (params.feeBps >= BPS) return (0, 0, 0); // platform fee is too high

        uint256 actualDest = (params.feeMode == FeeMode.FROM_DEST)
            ? (params.destAmount * (BPS + params.feeBps)) / BPS
            : params.destAmount;

        if (withImpact) {
            try
                ISwap(params.swapContract).getExpectedInWithImpact(
                    ISwap.GetExpectedInParams({
                        destAmount: actualDest,
                        tradePath: params.tradePath,
                        feeBps: params.feeMode == FeeMode.BY_PROTOCOL ? params.feeBps : 0,
                        extraArgs: params.extraArgs
                    })
                )
            returns (uint256 newSrcAmount, uint256 newPriceImpact) {
                srcAmount = newSrcAmount;
                priceImpact = newPriceImpact;
            } catch Error(string memory reason) {
                require(compareStrings(reason, "getExpectedIn_notSupported"), reason);
                (srcAmount, priceImpact) = defaultGetExpectedIn(
                    params.swapContract,
                    ISwap.GetExpectedInParams({
                        destAmount: actualDest,
                        tradePath: params.tradePath,
                        feeBps: params.feeMode == FeeMode.BY_PROTOCOL ? params.feeBps : 0,
                        extraArgs: params.extraArgs
                    }),
                    withImpact
                );
            }
        } else {
            try
                ISwap(params.swapContract).getExpectedIn(
                    ISwap.GetExpectedInParams({
                        destAmount: actualDest,
                        tradePath: params.tradePath,
                        feeBps: params.feeMode == FeeMode.BY_PROTOCOL ? params.feeBps : 0,
                        extraArgs: params.extraArgs
                    })
                )
            returns (uint256 newSrcAmount) {
                srcAmount = newSrcAmount;
            } catch Error(string memory reason) {
                require(compareStrings(reason, "getExpectedReturnWithImpact_notSupported"), reason);
                (srcAmount, priceImpact) = defaultGetExpectedIn(
                    params.swapContract,
                    ISwap.GetExpectedInParams({
                        destAmount: actualDest,
                        tradePath: params.tradePath,
                        feeBps: params.feeMode == FeeMode.BY_PROTOCOL ? params.feeBps : 0,
                        extraArgs: params.extraArgs
                    }),
                    withImpact
                );
            }
        }

        if (params.feeMode == FeeMode.FROM_SOURCE) {
            srcAmount = (srcAmount * (BPS + params.feeBps)) / BPS;
        }

        expectedRate = calcRateFromQty(
            srcAmount,
            params.destAmount,
            getDecimals(IERC20Ext(params.tradePath[0])),
            getDecimals(IERC20Ext(params.tradePath[params.tradePath.length - 1]))
        );
    }

    function defaultGetExpectedIn(address swapContract, ISwap.GetExpectedInParams memory params, bool withImpact)
        private
        view
        returns (uint256 srcAmount, uint256 priceImpact)
    {
        uint8 srcDecimal = 18;
        if (params.tradePath[0] != address(ETH_TOKEN_ADDRESS)) {
            srcDecimal = IERC20Ext(params.tradePath[0]).decimals();
        }
        if (srcDecimal > 3) {
            srcDecimal = srcDecimal - 3;
        }
        srcAmount = 1 * (10**srcDecimal); // Use a 0.001 as base
        uint256 lastGoodSrcAmount = 0;
        for (uint256 i = 0; i < 10; i++) {
            try
                ISwap(swapContract).getExpectedReturn(
                    ISwap.GetExpectedReturnParams({
                        srcAmount: srcAmount,
                        tradePath: params.tradePath,
                        feeBps: params.feeBps,
                        extraArgs: params.extraArgs
                    })
                )
            returns (uint256 newDestAmount) {
                if (newDestAmount != 0) {
                    (lastGoodSrcAmount, srcAmount) = (
                        srcAmount,
                        (srcAmount * params.destAmount) / newDestAmount
                    );
                    continue;
                }
            } catch {}
            // If there's an error or newDestAmount == 0, try something closer to lastGoodSrcAmount
            srcAmount = (srcAmount + lastGoodSrcAmount) / 2;
        }

        // Precision check
        uint256 destAmount;
        if (withImpact) {
            (destAmount, priceImpact) = ISwap(swapContract).getExpectedReturnWithImpact(
                ISwap.GetExpectedReturnParams({
                    srcAmount: srcAmount,
                    tradePath: params.tradePath,
                    feeBps: params.feeBps,
                    extraArgs: params.extraArgs
                })
            );
        } else {
            destAmount = ISwap(swapContract).getExpectedReturn(
                ISwap.GetExpectedReturnParams({
                    srcAmount: srcAmount,
                    tradePath: params.tradePath,
                    feeBps: params.feeBps,
                    extraArgs: params.extraArgs
                })
            );
        }
        uint256 diff;
        if (destAmount > params.destAmount) {
            diff = destAmount - params.destAmount;
        } else {
            diff = params.destAmount - destAmount;
        }
    }

    /// @dev swap using particular swap contract
    /// @return destAmount actual dest amount
    function swap(ISmartWalletImplementation.SwapParams calldata params)
        external
        payable
        override
        nonReentrant
        returns (uint256 destAmount)
    {
        destAmount = swapInternal(
            params.swapContract,
            params.srcAmount,
            params.minDestAmount,
            params.tradePath,
            msg.sender,
            params.feeMode,
            params.feeBps,
            params.platformWallet,
            params.extraArgs
        );

        emit Swap(
            msg.sender,
            params.swapContract,
            params.tradePath,
            params.srcAmount,
            destAmount,
            params.feeMode,
            params.feeBps,
            params.platformWallet
        );
    }

    /// @dev swap then deposit to platform
    ///     if tradePath has only 1 token, don't need to do swap
    /// @return destAmount actual dest amount
    function swapAndDeposit(ISmartWalletImplementation.SwapAndDepositParams calldata params)
        external
        payable
        override
        nonReentrant
        returns (uint256 destAmount)
    {
        require(params.tradePath.length >= 1, "invalid tradePath");
        require(supportedLendings.contains(params.lendingContract), "unsupported lending");

        if (params.tradePath.length == 1) {
            // just collect src token, no need to swap
            validateSourceAmount(params.tradePath[0], params.srcAmount);
            destAmount = safeTransferWithFee(
                msg.sender,
                params.lendingContract,
                params.tradePath[0],
                params.srcAmount,
                // Not taking lending fee
                0,
                params.platformWallet
            );
        } else {
            destAmount = swapInternal(
                params.swapContract,
                params.srcAmount,
                params.minDestAmount,
                params.tradePath,
                params.lendingContract,
                params.feeMode,
                params.feeBps,
                params.platformWallet,
                params.extraArgs
            );
        }

        // eth or token already transferred to the address
        ILending(params.lendingContract).depositTo(
            msg.sender,
            IERC20Ext(params.tradePath[params.tradePath.length - 1]),
            destAmount
        );

        emit SwapAndDeposit(
            msg.sender,
            params.swapContract,
            params.lendingContract,
            params.tradePath,
            params.srcAmount,
            destAmount,
            params.feeMode,
            params.feeBps,
            params.platformWallet
        );
    }

    /// @dev withdraw token from Lending platforms (AAVE, COMPOUND)
    /// @return returnedAmount returns the amount withdrawn to the user
    function withdrawFromLendingPlatform(
        ISmartWalletImplementation.WithdrawFromLendingPlatformParams calldata params
    ) external override nonReentrant returns (uint256 returnedAmount) {
        require(supportedLendings.contains(params.lendingContract), "unsupported lending");

        IERC20Ext lendingToken = IERC20Ext(
            ILending(params.lendingContract).getLendingToken(params.token)
        );
        require(lendingToken != IERC20Ext(0), "unsupported token");

        // AAVE aToken's transfer logic could have rounding errors
        uint256 tokenBalanceBefore = lendingToken.balanceOf(params.lendingContract);
        lendingToken.safeTransferFrom(msg.sender, params.lendingContract, params.amount);
        uint256 tokenBalanceAfter = lendingToken.balanceOf(params.lendingContract);

        returnedAmount = ILending(params.lendingContract).withdrawFrom(
            msg.sender,
            params.token,
            tokenBalanceAfter.sub(tokenBalanceBefore),
            params.minReturn
        );

        require(returnedAmount >= params.minReturn, "low returned amount");

        emit WithdrawFromLending(
            msg.sender,
            params.lendingContract,
            params.token,
            params.amount,
            params.minReturn,
            returnedAmount
        );
    }

    /// @dev swap and repay borrow for sender
    function swapAndRepay(ISmartWalletImplementation.SwapAndRepayParams calldata params)
        external
        payable
        override
        nonReentrant
        returns (uint256 destAmount)
    {
        require(params.tradePath.length >= 1, "invalid tradePath");
        require(supportedLendings.contains(params.lendingContract), "unsupported lending");

        // use user debt value if debt is <= payAmount
        // user can pay all debt by putting really high payAmount as param
        uint256 debt = ILending(params.lendingContract).getUserDebtCurrent(
            params.tradePath[params.tradePath.length - 1],
            msg.sender
        );
        uint256 actualPayAmount = debt >= params.payAmount ? params.payAmount : debt;

        if (params.tradePath.length == 1) {
            // just collect src token, no need to swap
            validateSourceAmount(params.tradePath[0], params.srcAmount);
            destAmount = safeTransferWithFee(
                msg.sender,
                params.lendingContract,
                params.tradePath[0],
                params.srcAmount,
                // Not taking repay fee
                0,
                params.platformWallet
            );
        } else {
            destAmount = swapInternal(
                params.swapContract,
                params.srcAmount,
                actualPayAmount,
                params.tradePath,
                params.lendingContract,
                params.feeMode,
                params.feeBps,
                params.platformWallet,
                params.extraArgs
            );
        }
        ILending(params.lendingContract).repayBorrowTo(
            msg.sender,
            IERC20Ext(params.tradePath[params.tradePath.length - 1]),
            destAmount,
            actualPayAmount,
            abi.encodePacked(params.rateMode)
        );

        uint256 actualDebtPaid = debt.sub(
            ILending(params.lendingContract).getUserDebtCurrent(
                params.tradePath[params.tradePath.length - 1],
                msg.sender
            )
        );
        require(actualDebtPaid >= actualPayAmount, "low paid amount");

        emit SwapAndRepay(
            msg.sender,
            params.swapContract,
            params.lendingContract,
            params.tradePath,
            params.srcAmount,
            destAmount,
            actualPayAmount,
            params.feeMode,
            params.feeBps,
            params.platformWallet
        );
    }

    function swapInternal(
        address payable swapContract,
        uint256 srcAmount,
        uint256 minDestAmount,
        address[] calldata tradePath,
        address payable recipient,
        FeeMode feeMode,
        uint256 platformFee,
        address payable platformWallet,
        bytes calldata extraArgs
    ) internal returns (uint256 destAmount) {
        require(supportedSwaps.contains(swapContract), "unsupported swap");
        require(tradePath.length >= 2, "invalid tradePath");
        require(platformFee < BPS, "high platform fee");

        validateSourceAmount(tradePath[0], srcAmount);

        uint256 actualSrcAmount = safeTransferWithFee(
            msg.sender,
            swapContract,
            tradePath[0],
            srcAmount,
            feeMode == FeeMode.FROM_SOURCE ? platformFee : 0,
            platformWallet
        );

        {
            // to avoid stack too deep
            // who will receive the swapped token
            address _recipient = feeMode == FeeMode.FROM_DEST ? address(this) : recipient;
            destAmount = ISwap(swapContract).swap(
                ISwap.SwapParams({
                    srcAmount: actualSrcAmount,
                    minDestAmount: minDestAmount,
                    tradePath: tradePath,
                    recipient: _recipient,
                    feeBps: feeMode == FeeMode.BY_PROTOCOL ? platformFee : 0,
                    feeReceiver: platformWallet,
                    extraArgs: extraArgs
                })
            );
        }

        if (feeMode == FeeMode.FROM_DEST) {
            destAmount = safeTransferWithFee(
                address(this),
                recipient,
                tradePath[tradePath.length - 1],
                destAmount,
                platformFee,
                platformWallet
            );
        }

        require(destAmount >= minDestAmount, "low return");
    }

    function validateSourceAmount(address srcToken, uint256 srcAmount) internal {
        if (srcToken == address(ETH_TOKEN_ADDRESS)) {
            require(msg.value == srcAmount, "wrong msg value");
        } else {
            require(msg.value == 0, "bad msg value");
        }
    }

    function transferToken(
        address payable to,
        IERC20Ext token,
        uint256 amount
    ) internal {
        if (amount == 0) return;
        if (token == ETH_TOKEN_ADDRESS) {
            (bool success, ) = to.call{value: amount}("");
            require(success, "transfer failed");
        } else {
            token.safeTransfer(to, amount);
        }
    }

    function safeTransferWithFee(
        address payable from,
        address payable to,
        address token,
        uint256 amount,
        uint256 platformFeeBps,
        address payable platformWallet
    ) internal returns (uint256 amountTransferred) {
        uint256 fee = amount.mul(platformFeeBps).div(BPS);
        uint256 amountAfterFee = amount.sub(fee);
        IERC20Ext tokenErc = IERC20Ext(token);

        if (tokenErc == ETH_TOKEN_ADDRESS) {
            (bool success, ) = to.call{value: amountAfterFee}("");
            require(success, "transfer failed");
            amountTransferred = amountAfterFee;
        } else {
            uint256 balanceBefore = tokenErc.balanceOf(to);
            if (from != address(this)) {
                // case transfer from another address, need to transfer fee to this proxy contract
                tokenErc.safeTransferFrom(from, to, amountAfterFee);
                if (fee > 0) {
                    tokenErc.safeTransferFrom(from, address(this), fee);
                }
            } else {
                tokenErc.safeTransfer(to, amountAfterFee);
            }
            amountTransferred = tokenErc.balanceOf(to).sub(balanceBefore);
        }

        addFeeToPlatform(platformWallet, tokenErc, fee);
    }

    function addFeeToPlatform(
        address payable platformWallet,
        IERC20Ext token,
        uint256 amount
    ) internal {
        if (amount > 0) {
            require(supportedPlatformWallets.contains(platformWallet), "unsupported platform");
            platformWalletFees[platformWallet][token] = platformWalletFees[platformWallet][token]
            .add(amount);
        }
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}
