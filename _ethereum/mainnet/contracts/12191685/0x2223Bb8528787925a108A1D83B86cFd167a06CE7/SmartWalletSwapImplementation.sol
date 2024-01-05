pragma solidity 0.6.6;

import "./ISmartWalletSwapImplementation.sol";
import "./SmartWalletSwapStorage.sol";
import "./IERC20Ext.sol";
import "./SafeERC20.sol";


contract SmartWalletSwapImplementation is SmartWalletSwapStorage, ISmartWalletSwapImplementation {
    using SafeERC20 for IERC20Ext;
    using SafeMath for uint256;

    event UpdatedSupportedPlatformWallets(address[] wallets, bool isSupported);
    event UpdatedBurnGasHelper(IBurnGasHelper indexed gasHelper);
    event UpdatedLendingImplementation(ISmartWalletLending impl);
    event ApprovedAllowances(IERC20Ext[] tokens, address[] spenders, bool isReset);
    event ClaimedPlatformFees(address[] wallets, IERC20Ext[] tokens, address claimer);

    constructor(address _admin) public SmartWalletSwapStorage(_admin) {}

    receive() external payable {}

    function updateBurnGasHelper(IBurnGasHelper _burnGasHelper) external onlyAdmin {
        if (burnGasHelper != _burnGasHelper) {
            burnGasHelper = _burnGasHelper;
            emit UpdatedBurnGasHelper(_burnGasHelper);
        }
    }

    function updateLendingImplementation(ISmartWalletLending newImpl) external onlyAdmin {
        require(newImpl != ISmartWalletLending(0), "invalid lending impl");
        lendingImpl = newImpl;
        emit UpdatedLendingImplementation(newImpl);
    }

    /// @dev to prevent other integrations to call trade from this contract
    function updateSupportedPlatformWallets(address[] calldata wallets, bool isSupported)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < wallets.length; i++) {
            supportedPlatformWallets[wallets[i]] = isSupported;
        }
        emit UpdatedSupportedPlatformWallets(wallets, isSupported);
    }

    function claimPlatformFees(address[] calldata platformWallets, IERC20Ext[] calldata tokens)
        external
        override
        nonReentrant
    {
        for (uint256 i = 0; i < platformWallets.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                uint256 fee = platformWalletFees[platformWallets[i]][tokens[j]];
                if (fee > 1) {
                    platformWalletFees[platformWallets[i]][tokens[j]] = 1;
                    transferToken(payable(platformWallets[i]), tokens[j], fee - 1);
                }
            }
        }
        emit ClaimedPlatformFees(platformWallets, tokens, msg.sender);
    }

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

    /// ========== SWAP ========== ///

    /// @dev swap token via Kyber
    /// @notice for some tokens that are paying fee, for example: DGX
    /// contract will trade with received src token amount (after minus fee)
    /// for Kyber, fee will be taken in ETH as part of their feature
    function swapKyber(
        IERC20Ext src,
        IERC20Ext dest,
        uint256 srcAmount,
        uint256 minConversionRate,
        address payable recipient,
        uint256 platformFeeBps,
        address payable platformWallet,
        bytes calldata hint,
        bool useGasToken
    ) external payable override nonReentrant returns (uint256 destAmount) {
        uint256 gasBefore = useGasToken ? gasleft() : 0;
        destAmount = doKyberTrade(
            src,
            dest,
            srcAmount,
            minConversionRate,
            recipient,
            platformFeeBps,
            platformWallet,
            hint
        );
        uint256 numGasBurns = 0;
        // burn gas token if needed
        if (useGasToken) {
            numGasBurns = burnGasTokensAfter(gasBefore);
        }
        emit KyberTrade(
            msg.sender,
            src,
            dest,
            srcAmount,
            destAmount,
            recipient,
            platformFeeBps,
            platformWallet,
            hint,
            useGasToken,
            numGasBurns
        );
    }

    /// @dev swap token via a supported Uniswap router
    /// @notice for some tokens that are paying fee, for example: DGX
    /// contract will trade with received src token amount (after minus fee)
    /// for Uniswap, fee will be taken in src token
    function swapUniswap(
        IUniswapV2Router02 router,
        uint256 srcAmount,
        uint256 minDestAmount,
        address[] calldata tradePath,
        address payable recipient,
        uint256 platformFeeBps,
        address payable platformWallet,
        bool feeInSrc,
        bool useGasToken
    ) external payable override nonReentrant returns (uint256 destAmount) {
        uint256 numGasBurns;
        {
            // prevent stack too deep
            uint256 gasBefore = useGasToken ? gasleft() : 0;
            destAmount = swapUniswapInternal(
                router,
                srcAmount,
                minDestAmount,
                tradePath,
                recipient,
                platformFeeBps,
                platformWallet,
                feeInSrc
            );
            if (useGasToken) {
                numGasBurns = burnGasTokensAfter(gasBefore);
            }
        }

        emit UniswapTrade(
            msg.sender,
            address(router),
            tradePath,
            srcAmount,
            destAmount,
            recipient,
            platformFeeBps,
            platformWallet,
            feeInSrc,
            useGasToken,
            numGasBurns
        );
    }

    /// ========== SWAP & DEPOSIT ========== ///

    function swapKyberAndDeposit(
        ISmartWalletLending.LendingPlatform platform,
        IERC20Ext src,
        IERC20Ext dest,
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 platformFeeBps,
        address payable platformWallet,
        bytes calldata hint,
        bool useGasToken
    ) external payable override nonReentrant returns (uint256 destAmount) {
        require(lendingImpl != ISmartWalletLending(0));
        uint256 gasBefore = useGasToken ? gasleft() : 0;
        if (src == dest) {
            // just collect src token, no need to swap
            destAmount = safeForwardTokenToLending(
                src,
                msg.sender,
                payable(address(lendingImpl)),
                srcAmount
            );
        } else {
            destAmount = doKyberTrade(
                src,
                dest,
                srcAmount,
                minConversionRate,
                payable(address(lendingImpl)),
                platformFeeBps,
                platformWallet,
                hint
            );
        }

        // eth or token alr transferred to the address
        lendingImpl.depositTo(platform, msg.sender, dest, destAmount);

        uint256 numGasBurns = 0;
        if (useGasToken) {
            numGasBurns = burnGasTokensAfter(gasBefore);
        }

        emit KyberTradeAndDeposit(
            msg.sender,
            platform,
            src,
            dest,
            srcAmount,
            destAmount,
            platformFeeBps,
            platformWallet,
            hint,
            useGasToken,
            numGasBurns
        );
    }

    /// @dev swap Uniswap then deposit to platform
    ///     if tradePath has only 1 token, don't need to do swap
    /// @param platform platform to deposit
    /// @param router which Uni-clone to use for swapping
    /// @param srcAmount amount of src token
    /// @param minDestAmount minimal accepted dest amount
    /// @param tradePath path of the trade on Uniswap
    /// @param platformFeeBps fee if swapping
    /// @param platformWallet wallet to receive fee
    /// @param useGasToken whether to use gas token or not
    function swapUniswapAndDeposit(
        ISmartWalletLending.LendingPlatform platform,
        IUniswapV2Router02 router,
        uint256 srcAmount,
        uint256 minDestAmount,
        address[] calldata tradePath,
        uint256 platformFeeBps,
        address payable platformWallet,
        bool useGasToken
    ) external payable override nonReentrant returns (uint256 destAmount) {
        require(lendingImpl != ISmartWalletLending(0));
        uint256 gasBefore = useGasToken ? gasleft() : 0;
        {
            IERC20Ext dest = IERC20Ext(tradePath[tradePath.length - 1]);
            if (tradePath.length == 1) {
                // just collect src token, no need to swap
                destAmount = safeForwardTokenToLending(
                    dest,
                    msg.sender,
                    payable(address(lendingImpl)),
                    srcAmount
                );
            } else {
                destAmount = swapUniswapInternal(
                    router,
                    srcAmount,
                    minDestAmount,
                    tradePath,
                    payable(address(lendingImpl)),
                    platformFeeBps,
                    platformWallet,
                    false
                );
            }

            // eth or token alr transferred to the address
            lendingImpl.depositTo(platform, msg.sender, dest, destAmount);
        }

        uint256 numGasBurns = 0;
        if (useGasToken) {
            numGasBurns = burnGasTokensAfter(gasBefore);
        }

        emit UniswapTradeAndDeposit(
            msg.sender,
            platform,
            router,
            tradePath,
            srcAmount,
            destAmount,
            platformFeeBps,
            platformWallet,
            useGasToken,
            numGasBurns
        );
    }

    /// @dev withdraw token from Lending platforms (AAVE, COMPOUND)
    /// @param platform platform to withdraw token
    /// @param token underlying token to withdraw, e.g ETH, USDT, DAI
    /// @param amount amount of cToken (COMPOUND) or aToken (AAVE) to withdraw
    /// @param minReturn minimum amount of USDT tokens to return
    /// @param useGasToken whether to use gas token or not
    /// @return returnedAmount returns the amount withdrawn to the user
    function withdrawFromLendingPlatform(
        ISmartWalletLending.LendingPlatform platform,
        IERC20Ext token,
        uint256 amount,
        uint256 minReturn,
        bool useGasToken
    ) external override nonReentrant returns (uint256 returnedAmount) {
        require(lendingImpl != ISmartWalletLending(0));
        uint256 gasBefore = useGasToken ? gasleft() : 0;
        IERC20Ext lendingToken = IERC20Ext(lendingImpl.getLendingToken(platform, token));
        require(lendingToken != IERC20Ext(0), "unsupported token");
        // AAVE aToken's transfer logic could have rounding errors
        uint256 tokenBalanceBefore = lendingToken.balanceOf(address(lendingImpl));
        lendingToken.safeTransferFrom(msg.sender, address(lendingImpl), amount);
        uint256 tokenBalanceAfter = lendingToken.balanceOf(address(lendingImpl));

        returnedAmount = lendingImpl.withdrawFrom(
            platform,
            msg.sender,
            token,
            tokenBalanceAfter.sub(tokenBalanceBefore),
            minReturn
        );

        uint256 numGasBurns;
        if (useGasToken) {
            numGasBurns = burnGasTokensAfter(gasBefore);
        }
        emit WithdrawFromLending(
            platform,
            token,
            amount,
            minReturn,
            returnedAmount,
            useGasToken,
            numGasBurns
        );
    }

    /// @dev swap on Kyber and repay borrow for sender
    /// if src == dest, no need to swap, use src token to repay directly
    /// @param payAmount: amount that user wants to pay, if the dest amount (after swap) is higher,
    ///     the remain amount will be sent back to user's wallet
    /// @param feeAndRateMode: in case of aave v2, user needs to specify the rateMode to repay
    ///     to prevent stack too deep, combine fee and rateMode into a single value
    ///     platformFee: feeAndRateMode % BPS, rateMode: feeAndRateMode / BPS
    /// Other params are params for trade on Kyber
    function swapKyberAndRepay(
        ISmartWalletLending.LendingPlatform platform,
        IERC20Ext src,
        IERC20Ext dest,
        uint256 srcAmount,
        uint256 payAmount,
        uint256 feeAndRateMode,
        address payable platformWallet,
        bytes calldata hint,
        bool useGasToken
    ) external payable override nonReentrant returns (uint256 destAmount) {
        uint256 numGasBurns;
        {
            require(lendingImpl != ISmartWalletLending(0));
            uint256 gasBefore = useGasToken ? gasleft() : 0;

            {
                // use user debt value if debt is <= payAmount,
                // user can pay all debt by putting really high payAmount as param
                payAmount = checkUserDebt(platform, address(dest), payAmount);
                if (src == dest) {
                    if (src == ETH_TOKEN_ADDRESS) {
                        require(msg.value == srcAmount, "invalid msg value");
                        transferToken(payable(address(lendingImpl)), src, srcAmount);
                    } else {
                        destAmount = srcAmount > payAmount ? payAmount : srcAmount;
                        src.safeTransferFrom(msg.sender, address(lendingImpl), destAmount);
                    }
                } else {
                    // use user debt value if debt is <= payAmount
                    payAmount = checkUserDebt(platform, address(dest), payAmount);

                    // use min rate so it can return earlier if failed to swap
                    uint256 minRate =
                        calcRateFromQty(srcAmount, payAmount, src.decimals(), dest.decimals());

                    destAmount = doKyberTrade(
                        src,
                        dest,
                        srcAmount,
                        minRate,
                        payable(address(lendingImpl)),
                        feeAndRateMode % BPS,
                        platformWallet,
                        hint
                    );
                }
            }

            lendingImpl.repayBorrowTo(
                platform,
                msg.sender,
                dest,
                destAmount,
                payAmount,
                feeAndRateMode / BPS
            );

            if (useGasToken) {
                numGasBurns = burnGasTokensAfter(gasBefore);
            }
        }

        emit KyberTradeAndRepay(
            msg.sender,
            platform,
            src,
            dest,
            srcAmount,
            destAmount,
            payAmount,
            feeAndRateMode,
            platformWallet,
            hint,
            useGasToken,
            numGasBurns
        );
    }

    /// @dev swap on Uni-clone and repay borrow for sender
    /// if tradePath.length == 1, no need to swap, use tradePath[0] token to repay directly
    /// @param payAmount: amount that user wants to pay, if the dest amount (after swap) is higher,
    ///     the remain amount will be sent back to user's wallet
    /// @param feeAndRateMode: in case of aave v2, user needs to specify the rateMode to repay
    ///     to prevent stack too deep, combine fee and rateMode into a single value
    ///     platformFee: feeAndRateMode % BPS, rateMode: feeAndRateMode / BPS
    /// Other params are params for trade on Uni-clone
    function swapUniswapAndRepay(
        ISmartWalletLending.LendingPlatform platform,
        IUniswapV2Router02 router,
        uint256 srcAmount,
        uint256 payAmount,
        address[] calldata tradePath,
        uint256 feeAndRateMode,
        address payable platformWallet,
        bool useGasToken
    ) external payable override nonReentrant returns (uint256 destAmount) {
        uint256 numGasBurns;
        {
            // scope to prevent stack too deep
            require(lendingImpl != ISmartWalletLending(0));
            uint256 gasBefore = useGasToken ? gasleft() : 0;
            IERC20Ext dest = IERC20Ext(tradePath[tradePath.length - 1]);

            // use user debt value if debt is <= payAmount
            // user can pay all debt by putting really high payAmount as param
            payAmount = checkUserDebt(platform, address(dest), payAmount);
            if (tradePath.length == 1) {
                if (dest == ETH_TOKEN_ADDRESS) {
                    require(msg.value == srcAmount, "invalid msg value");
                    transferToken(payable(address(lendingImpl)), dest, srcAmount);
                } else {
                    destAmount = srcAmount > payAmount ? payAmount : srcAmount;
                    dest.safeTransferFrom(msg.sender, address(lendingImpl), destAmount);
                }
            } else {
                destAmount = swapUniswapInternal(
                    router,
                    srcAmount,
                    payAmount,
                    tradePath,
                    payable(address(lendingImpl)),
                    feeAndRateMode % BPS,
                    platformWallet,
                    false
                );
            }

            lendingImpl.repayBorrowTo(
                platform,
                msg.sender,
                dest,
                destAmount,
                payAmount,
                feeAndRateMode / BPS
            );

            if (useGasToken) {
                numGasBurns = burnGasTokensAfter(gasBefore);
            }
        }

        emit UniswapTradeAndRepay(
            msg.sender,
            platform,
            router,
            tradePath,
            srcAmount,
            destAmount,
            payAmount,
            feeAndRateMode,
            platformWallet,
            useGasToken,
            numGasBurns
        );
    }

    function claimComp(
        address[] calldata holders,
        ICompErc20[] calldata cTokens,
        bool borrowers,
        bool suppliers,
        bool useGasToken
    ) external override nonReentrant {
        uint256 gasBefore = useGasToken ? gasleft() : 0;
        lendingImpl.claimComp(holders, cTokens, borrowers, suppliers);
        if (useGasToken) {
            burnGasTokensAfter(gasBefore);
        }
    }

    /// @dev get expected return and conversion rate if using Kyber
    function getExpectedReturnKyber(
        IERC20Ext src,
        IERC20Ext dest,
        uint256 srcAmount,
        uint256 platformFee,
        bytes calldata hint
    ) external view override returns (uint256 destAmount, uint256 expectedRate) {
        try kyberProxy.getExpectedRateAfterFee(src, dest, srcAmount, platformFee, hint) returns (
            uint256 rate
        ) {
            expectedRate = rate;
        } catch {
            expectedRate = 0;
        }
        destAmount = calcDestAmount(src, dest, srcAmount, expectedRate);
    }

    /// @dev get expected return and conversion rate if using a Uniswap router
    function getExpectedReturnUniswap(
        IUniswapV2Router02 router,
        uint256 srcAmount,
        address[] calldata tradePath,
        uint256 platformFee
    ) external view override returns (uint256 destAmount, uint256 expectedRate) {
        if (platformFee >= BPS) return (0, 0); // platform fee is too high
        if (!isRouterSupported[router]) return (0, 0); // router is not supported
        uint256 srcAmountAfterFee = (srcAmount * (BPS - platformFee)) / BPS;
        if (srcAmountAfterFee == 0) return (0, 0);
        // in case pair is not supported
        try router.getAmountsOut(srcAmountAfterFee, tradePath) returns (uint256[] memory amounts) {
            destAmount = amounts[tradePath.length - 1];
        } catch {
            destAmount = 0;
        }
        expectedRate = calcRateFromQty(
            srcAmountAfterFee,
            destAmount,
            getDecimals(IERC20Ext(tradePath[0])),
            getDecimals(IERC20Ext(tradePath[tradePath.length - 1]))
        );
    }

    function checkUserDebt(
        ISmartWalletLending.LendingPlatform platform,
        address token,
        uint256 amount
    ) internal returns (uint256) {
        uint256 debt = lendingImpl.storeAndRetrieveUserDebtCurrent(platform, token, msg.sender);

        if (debt >= amount) {
            return amount;
        }

        return debt;
    }

    function doKyberTrade(
        IERC20Ext src,
        IERC20Ext dest,
        uint256 srcAmount,
        uint256 minConversionRate,
        address payable recipient,
        uint256 platformFeeBps,
        address payable platformWallet,
        bytes memory hint
    ) internal virtual returns (uint256 destAmount) {
        uint256 actualSrcAmount =
            validateAndPrepareSourceAmount(address(kyberProxy), src, srcAmount, platformWallet);
        uint256 callValue = src == ETH_TOKEN_ADDRESS ? actualSrcAmount : 0;
        destAmount = kyberProxy.tradeWithHintAndFee{value: callValue}(
            src,
            actualSrcAmount,
            dest,
            recipient,
            MAX_AMOUNT,
            minConversionRate,
            platformWallet,
            platformFeeBps,
            hint
        );
    }

    function swapUniswapInternal(
        IUniswapV2Router02 router,
        uint256 srcAmount,
        uint256 minDestAmount,
        address[] memory tradePath,
        address payable recipient,
        uint256 platformFeeBps,
        address payable platformWallet,
        bool feeInSrc
    ) internal returns (uint256 destAmount) {
        TradeInput memory input =
            TradeInput({
                srcAmount: srcAmount,
                minData: minDestAmount,
                recipient: recipient,
                platformFeeBps: platformFeeBps,
                platformWallet: platformWallet,
                hint: ""
            });

        // extra validation when swapping on Uniswap
        require(isRouterSupported[router], "unsupported router");
        require(platformFeeBps < BPS, "high platform fee");

        IERC20Ext src = IERC20Ext(tradePath[0]);

        input.srcAmount = validateAndPrepareSourceAmount(
            address(router),
            src,
            srcAmount,
            platformWallet
        );

        destAmount = doUniswapTrade(router, src, tradePath, input, feeInSrc);
    }

    function doUniswapTrade(
        IUniswapV2Router02 router,
        IERC20Ext src,
        address[] memory tradePath,
        TradeInput memory input,
        bool feeInSrc
    ) internal virtual returns (uint256 destAmount) {
        uint256 tradeLen = tradePath.length;
        IERC20Ext actualDest = IERC20Ext(tradePath[tradeLen - 1]);
        {
            // convert eth -> weth address to trade on Uniswap
            if (tradePath[0] == address(ETH_TOKEN_ADDRESS)) {
                tradePath[0] = router.WETH();
            }
            if (tradePath[tradeLen - 1] == address(ETH_TOKEN_ADDRESS)) {
                tradePath[tradeLen - 1] = router.WETH();
            }
        }

        uint256 srcAmountFee;
        uint256 srcAmountAfterFee;
        uint256 destBalanceBefore;
        address recipient;

        if (feeInSrc) {
            srcAmountFee = input.srcAmount.mul(input.platformFeeBps).div(BPS);
            srcAmountAfterFee = input.srcAmount.sub(srcAmountFee);
            recipient = input.recipient;
        } else {
            srcAmountAfterFee = input.srcAmount;
            destBalanceBefore = getBalance(actualDest, address(this));
            recipient = address(this);
        }

        uint256[] memory amounts;
        if (src == ETH_TOKEN_ADDRESS) {
            // swap eth -> token
            amounts = router.swapExactETHForTokens{value: srcAmountAfterFee}(
                input.minData,
                tradePath,
                recipient,
                MAX_AMOUNT
            );
        } else {
            if (actualDest == ETH_TOKEN_ADDRESS) {
                // swap token -> eth
                amounts = router.swapExactTokensForETH(
                    srcAmountAfterFee,
                    input.minData,
                    tradePath,
                    recipient,
                    MAX_AMOUNT
                );
            } else {
                // swap token -> token
                amounts = router.swapExactTokensForTokens(
                    srcAmountAfterFee,
                    input.minData,
                    tradePath,
                    recipient,
                    MAX_AMOUNT
                );
            }
        }

        if (!feeInSrc) {
            // fee in dest token, calculated received dest amount
            uint256 destBalanceAfter = getBalance(actualDest, address(this));
            destAmount = destBalanceAfter.sub(destBalanceBefore);
            uint256 destAmountFee = destAmount.mul(input.platformFeeBps).div(BPS);
            // charge fee in dest token
            addFeeToPlatform(input.platformWallet, actualDest, destAmountFee);
            // transfer back dest token to recipient
            destAmount = destAmount.sub(destAmountFee);
            transferToken(input.recipient, actualDest, destAmount);
        } else {
            // fee in src amount
            destAmount = amounts[amounts.length - 1];
            addFeeToPlatform(input.platformWallet, src, srcAmountFee);
        }
    }

    function validateAndPrepareSourceAmount(
        address protocol,
        IERC20Ext src,
        uint256 srcAmount,
        address platformWallet
    ) internal virtual returns (uint256 actualSrcAmount) {
        require(supportedPlatformWallets[platformWallet], "unsupported platform wallet");
        if (src == ETH_TOKEN_ADDRESS) {
            require(msg.value == srcAmount, "wrong msg value");
            actualSrcAmount = srcAmount;
        } else {
            require(msg.value == 0, "bad msg value");
            uint256 balanceBefore = src.balanceOf(address(this));
            src.safeTransferFrom(msg.sender, address(this), srcAmount);
            uint256 balanceAfter = src.balanceOf(address(this));
            actualSrcAmount = balanceAfter.sub(balanceBefore);
            require(actualSrcAmount > 0, "invalid src amount");

            safeApproveAllowance(protocol, src);
        }
    }

    function burnGasTokensAfter(uint256 gasBefore) internal virtual returns (uint256 numGasBurns) {
        if (burnGasHelper == IBurnGasHelper(0)) return 0;
        IGasToken gasToken;
        uint256 gasAfter = gasleft();

        try
            burnGasHelper.getAmountGasTokensToBurn(gasBefore.sub(gasAfter).add(msg.data.length))
        returns (uint256 _gasBurns, address _gasToken) {
            numGasBurns = _gasBurns;
            gasToken = IGasToken(_gasToken);
        } catch {
            numGasBurns = 0;
        }

        if (numGasBurns > 0 && gasToken != IGasToken(0)) {
            numGasBurns = gasToken.freeFromUpTo(msg.sender, numGasBurns);
        }
    }

    function safeForwardTokenToLending(
        IERC20Ext token,
        address from,
        address payable to,
        uint256 amount
    ) internal returns (uint256 destAmount) {
        if (token == ETH_TOKEN_ADDRESS) {
            require(msg.value >= amount, "low msg value");
            (bool success, ) = to.call{value: amount}("");
            require(success, "transfer eth failed");
            destAmount = amount;
        } else {
            uint256 balanceBefore = token.balanceOf(to);
            token.safeTransferFrom(from, to, amount);
            destAmount = token.balanceOf(to).sub(balanceBefore);
        }
    }

    function addFeeToPlatform(
        address wallet,
        IERC20Ext token,
        uint256 amount
    ) internal {
        if (amount > 0) {
            platformWalletFees[wallet][token] = platformWalletFees[wallet][token].add(amount);
        }
    }

    function transferToken(
        address payable recipient,
        IERC20Ext token,
        uint256 amount
    ) internal {
        if (amount == 0) return;
        if (token == ETH_TOKEN_ADDRESS) {
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "failed to transfer eth");
        } else {
            token.safeTransfer(recipient, amount);
        }
    }

    function safeApproveAllowance(address spender, IERC20Ext token) internal {
        if (token.allowance(address(this), spender) == 0) {
            getSetDecimals(token);
            token.safeApprove(spender, MAX_ALLOWANCE);
        }
    }
}
