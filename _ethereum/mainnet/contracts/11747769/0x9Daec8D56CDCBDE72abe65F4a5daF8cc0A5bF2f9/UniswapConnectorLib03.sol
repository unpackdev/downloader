pragma solidity 0.6.2;

///
/// @title   Library for business logic for connecting Uniswap V2 Protocol functions with Primitive V1.
/// @notice  Primitive V1 UniswapConnectorLib03 - @primitivefi/v1-connectors@v1.2.2
/// @author  Primitive
///

// Uniswap
import "./IUniswapV2Callee.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
// Primitive
import "./ITrader.sol";
import "./TraderLib.sol";
import "./IWethConnector01.sol";
import "./WethConnectorLib01.sol";
// Open Zeppelin
import "./SafeMath.sol";
import "./SafeERC20.sol";

library UniswapConnectorLib03 {
    using SafeERC20 for IERC20; // Reverts when `transfer` or `transferFrom` erc20 calls don't return proper data
    using SafeMath for uint256; // Reverts on math underflows/overflows

    /// ==== Combo Operations ====

    ///
    /// @dev    Mints long + short option tokens, then swaps the shortOptionTokens (redeem) for tokens.
    /// @notice If the first address in the path is not the shortOptionToken address, the tx will fail.
    ///         underlyingToken -> shortOptionToken -> quoteToken.
    ///         IMPORTANT: redeemTokens = shortOptionTokens
    /// @param optionToken The address of the Option contract.
    /// @param amountIn The quantity of options to mint.
    /// @param amountOutMin The minimum quantity of tokens to receive in exchange for the shortOptionTokens.
    /// @param path The token addresses to trade through using their Uniswap V2 pools. Assumes path[0] = shortOptionToken.
    /// @param to The address to send the shortOptionToken proceeds and longOptionTokens to.
    /// @param deadline The timestamp for a trade to fail at if not successful.
    /// @return bool Whether the transaction was successful or not.
    ///
    function mintShortOptionsThenSwapToTokens(
        IUniswapV2Router02 router,
        IOption optionToken,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) internal returns (bool) {
        // Pulls underlyingTokens from msg.sender, then pushes underlyingTokens to option contract.
        // Mints long + short tokens to this contract.
        (uint256 outputOptions, uint256 outputRedeems) =
            mintOptionsKeepShortOptions(optionToken, amountIn);

        // Swaps shortOptionTokens to the token specified at the end of the path, then sends to msg.sender.
        // Reverts if the first address in the path is not the shortOptionToken address.
        address redeemToken = optionToken.redeemToken();
        (, bool success) =
            swapExactOptionsForTokens(
                router,
                redeemToken,
                outputRedeems, // shortOptionTokens = redeemTokens
                amountOutMin,
                path,
                to,
                deadline
            );
        // Fail early if the swap failed.
        require(success, "ERR_SWAP_FAILED");
        return success;
    }

    // ==== Flash Functions ====

    ///
    /// @dev    Receives underlyingTokens from a UniswapV2Pair.swap() call from a pair with
    ///         shortOptionTokens and underlyingTokens.
    ///         Uses underlyingTokens to mint long (option) + short (redeem) tokens.
    ///         Sends longOptionTokens to msg.sender, and pays back the UniswapV2Pair with shortOptionTokens,
    ///         AND any remainder quantity of underlyingTokens (paid by msg.sender).
    /// @notice If the first address in the path is not the shortOptionToken address, the tx will fail.
    ///         IMPORTANT: UniswapV2 adds a fee of 0.301% to the option premium cost.
    /// @param router The address of the UniswapV2Router02 contract.
    /// @param pairAddress The address of the redeemToken<>underlyingToken UniswapV2Pair contract.
    /// @param optionAddress The address of the Option contract.
    /// @param flashLoanQuantity The quantity of options to mint using borrowed underlyingTokens.
    /// @param maxPremium The maximum quantity of underlyingTokens to pay for the optionTokens.
    /// @param path The token addresses to trade through using their Uniswap V2 pools. Assumes path[0] = shortOptionToken.
    /// @param to The address to send the shortOptionToken proceeds and longOptionTokens to.
    /// @return success bool Whether the transaction was successful or not.
    ///
    function flashMintShortOptionsThenSwap(
        IUniswapV2Router02 router,
        address pairAddress,
        address optionAddress,
        uint256 flashLoanQuantity,
        uint256 maxPremium,
        address[] memory path,
        address to
    ) internal returns (uint256, uint256) {
        require(msg.sender == address(this), "ERR_NOT_SELF");
        require(to != address(0x0), "ERR_TO_ADDRESS_ZERO");
        require(to != msg.sender, "ERR_TO_MSG_SENDER");
        require(
            pairFor(router.factory(), path[0], path[1]) == pairAddress,
            "ERR_INVALID_PAIR"
        );
        // IMPORTANT: Assume this contract has already received `flashLoanQuantity` of underlyingTokens.
        address underlyingToken =
            IOption(optionAddress).getUnderlyingTokenAddress();
        address redeemToken = IOption(optionAddress).redeemToken();
        require(path[1] == underlyingToken, "ERR_END_PATH_NOT_UNDERLYING");

        // Mint longOptionTokens using the underlyingTokens received from UniswapV2 flash swap to this contract.
        // Send underlyingTokens from this contract to the optionToken contract, then call mintOptions.
        (uint256 mintedOptions, uint256 mintedRedeems) =
            mintOptionsWithUnderlyingBalance(
                IOption(optionAddress),
                flashLoanQuantity
            );

        // The loanRemainder will be the amount of underlyingTokens that are needed from the original
        // transaction caller in order to pay the flash swap.
        // IMPORTANT: THIS IS EFFECTIVELY THE PREMIUM PAID IN UNDERLYINGTOKENS TO PURCHASE THE OPTIONTOKEN.
        uint256 loanRemainder;

        // Economically, negativePremiumPaymentInRedeems value should always be 0.
        // In the case that we minted more redeemTokens than are needed to pay back the flash swap,
        // (short -> underlying is a positive trade), there is an effective negative premium.
        // In that case, this function will send out `negativePremiumAmount` of redeemTokens to the original caller.
        // This means the user gets to keep the extra redeemTokens for free.
        // Negative premium amount is the opposite difference of the loan remainder: (paid - flash loan amount)
        uint256 negativePremiumPaymentInRedeems;
        (loanRemainder, negativePremiumPaymentInRedeems) = getOpenPremium(
            router,
            IOption(optionAddress),
            flashLoanQuantity
        );

        // In the case that more redeemTokens were minted than need to be sent back as payment,
        // calculate the new mintedRedeems value to send to the pair
        // (don't send all the minted redeemTokens).
        if (negativePremiumPaymentInRedeems > 0) {
            mintedRedeems = mintedRedeems.sub(negativePremiumPaymentInRedeems);
        }

        // In most cases, all of the minted redeemTokens will be sent to the pair as payment for the flash swap.
        if (mintedRedeems > 0) {
            IERC20(redeemToken).safeTransfer(pairAddress, mintedRedeems);
        }

        // If loanRemainder is non-zero and non-negative (most cases), send underlyingTokens to the pair as payment (premium).
        if (loanRemainder > 0) {
            // Pull underlyingTokens from the original msg.sender to pay the remainder of the flash swap.
            require(maxPremium >= loanRemainder, "ERR_PREMIUM_OVER_MAX"); // check for users to not pay over their max desired value.
            IERC20(underlyingToken).safeTransferFrom(
                to,
                pairAddress,
                loanRemainder
            );
        }

        // If negativePremiumAmount is non-zero and non-negative, send redeemTokens to the `to` address.
        if (negativePremiumPaymentInRedeems > 0) {
            IERC20(redeemToken).safeTransfer(
                to,
                negativePremiumPaymentInRedeems
            );
        }

        // Send minted longOptionTokens (option) to the original msg.sender.
        IERC20(optionAddress).safeTransfer(to, mintedOptions);
        return (mintedOptions, loanRemainder);
    }

    /// @dev    Sends shortOptionTokens to msg.sender, and pays back the UniswapV2Pair in underlyingTokens.
    /// @notice IMPORTANT: If minPayout is 0, the `to` address is liable for negative payouts *if* that occurs.
    /// @param router The UniswapV2Router02 contract.
    /// @param pairAddress The address of the redeemToken<>underlyingToken UniswapV2Pair contract.
    /// @param optionAddress The address of the longOptionTokes to close.
    /// @param flashLoanQuantity The quantity of shortOptionTokens borrowed to use to close longOptionTokens.
    /// @param minPayout The minimum payout of underlyingTokens sent to the `to` address.
    /// @param path underlyingTokens -> shortOptionTokens, because we are paying the input of underlyingTokens.
    /// @param to The address which is sent the underlyingToken payout, or liable to pay for a negative payout.
    function flashCloseLongOptionsThenSwap(
        IUniswapV2Router02 router,
        address pairAddress,
        address optionAddress,
        uint256 flashLoanQuantity,
        uint256 minPayout,
        address[] memory path,
        address to
    ) internal returns (uint256, uint256) {
        require(msg.sender == address(this), "ERR_NOT_SELF");
        require(to != address(0x0), "ERR_TO_ADDRESS_ZERO");
        require(to != msg.sender, "ERR_TO_MSG_SENDER");
        require(
            pairFor(router.factory(), path[0], path[1]) == pairAddress,
            "ERR_INVALID_PAIR"
        );

        // IMPORTANT: Assume this contract has already received `flashLoanQuantity` of redeemTokens.
        // We are flash swapping from an underlying <> shortOptionToken pair,
        // paying back a portion using underlyingTokens received from closing options.
        // In the flash open, we did redeemTokens to underlyingTokens.
        // In the flash close, we are doing underlyingTokens to redeemTokens and keeping the remainder.
        address underlyingToken =
            IOption(optionAddress).getUnderlyingTokenAddress();
        address redeemToken = IOption(optionAddress).redeemToken();
        require(path[1] == redeemToken, "ERR_END_PATH_NOT_REDEEM");

        // Quantity of underlyingTokens this contract receives from burning option + redeem tokens.
        uint256 outputUnderlyings =
            closeOptionsWithShortBalance(
                to,
                IOption(optionAddress),
                flashLoanQuantity
            );

        // Loan Remainder is the cost to pay out, should be 0 in most cases.
        // Underlying Payout is the `premium` that the original caller receives in underlyingTokens.
        // It's the remainder of underlyingTokens after the pair has been paid back underlyingTokens for the
        // flash swapped shortOptionTokens.
        (uint256 underlyingPayout, uint256 loanRemainder) =
            getClosePremium(router, IOption(optionAddress), flashLoanQuantity);

        // In most cases there will be an underlying payout, which is subtracted from the outputUnderlyings.
        if (underlyingPayout > 0) {
            outputUnderlyings = outputUnderlyings.sub(underlyingPayout);
        }

        // Pay back the pair in underlyingTokens.
        if (outputUnderlyings > 0) {
            IERC20(underlyingToken).safeTransfer(
                pairAddress,
                outputUnderlyings
            );
        }

        // If loanRemainder is non-zero and non-negative, send underlyingTokens to the pair as payment (premium).
        if (loanRemainder > 0) {
            // Pull underlyingTokens from the original msg.sender to pay the remainder of the flash swap.
            // Revert if the minPayout is less than or equal to the underlyingPayment of 0.
            // There is 0 underlyingPayment in the case that loanRemainder > 0.
            // This code branch can be successful by setting `minPayout` to 0.
            // This means the user is willing to pay to close the position.
            require(minPayout <= underlyingPayout, "ERR_NEGATIVE_PAYOUT");
            IERC20(underlyingToken).safeTransferFrom(
                to,
                pairAddress,
                loanRemainder
            );
        }

        // If underlyingPayout is non-zero and non-negative, send it to the `to` address.
        if (underlyingPayout > 0) {
            // Revert if minPayout is greater than the actual payout.
            require(underlyingPayout >= minPayout, "ERR_PREMIUM_UNDER_MIN");
            IERC20(underlyingToken).safeTransfer(to, underlyingPayout);
        }

        return (outputUnderlyings, underlyingPayout);
    }

    // ==== Liquidity Functions ====

    ///
    /// @dev    Adds redeemToken liquidity to a redeem<>underlyingToken pair by minting shortOptionTokens with underlyingTokens.
    /// @notice Pulls underlying tokens from msg.sender and pushes UNI-V2 liquidity tokens to the "to" address.
    ///         underlyingToken -> redeemToken -> UNI-V2.
    /// @param optionAddress The address of the optionToken to get the redeemToken to mint then provide liquidity for.
    /// @param quantityOptions The quantity of underlyingTokens to use to mint option + redeem tokens.
    /// @param amountBMax The quantity of underlyingTokens to add with shortOptionTokens to the Uniswap V2 Pair.
    /// @param amountBMin The minimum quantity of underlyingTokens expected to provide liquidity with.
    /// @param to The address that receives UNI-V2 shares.
    /// @param deadline The timestamp to expire a pending transaction.
    ///
    function addShortLiquidityWithUnderlying(
        IUniswapV2Router02 router,
        address optionAddress,
        uint256 quantityOptions,
        uint256 amountBMax,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 amountA;
        uint256 amountB;
        uint256 liquidity;
        (, uint256 outputRedeems) =
            mintOptionsKeepShortOptions(
                IOption(optionAddress),
                quantityOptions
            );

        {
            // scope for adding exact liquidity, avoids stack too deep errors
            IOption optionToken = IOption(optionAddress);
            IUniswapV2Router02 router_ = router;
            address underlyingToken = optionToken.getUnderlyingTokenAddress();
            uint256 outputRedeems_ = outputRedeems;
            uint256 amountBMax_ = amountBMax;
            uint256 amountBMin_ = amountBMin;
            address to_ = to;
            uint256 deadline_ = deadline;

            // Adds liquidity to Uniswap V2 Pair and returns liquidity shares to the "to" address.
            (amountA, amountB, liquidity) = addExactShortLiquidity(
                router_,
                optionToken.redeemToken(),
                underlyingToken,
                outputRedeems_,
                amountBMax_,
                amountBMin_,
                to_,
                deadline_
            );
            // check for exact liquidity provided
            assert(amountA == outputRedeems);

            uint256 remainder =
                amountBMax_ > amountB ? amountBMax_.sub(amountB) : 0;
            if (remainder > 0) {
                IERC20(underlyingToken).safeTransfer(msg.sender, remainder);
            }
        }
        return (amountA, amountB, liquidity);
    }

    ///
    /// @dev    Calls the "swapExactTokensForTokens" function on the Uniswap V2 Router 02 Contract.
    /// @notice Fails early if the address in the beginning of the path is not the token address.
    /// @param tokenAddress The address of the token to swap from.
    /// @param amountIn The quantity of longOptionTokens to swap with.
    /// @param amountOutMin The minimum quantity of tokens to receive in exchange for the tokens swapped.
    /// @param path The token addresses to trade through using their Uniswap V2 pairs.
    /// @param to The address to send the token proceeds to.
    /// @param deadline The timestamp for a trade to fail at if not successful.
    ///
    function swapExactOptionsForTokens(
        IUniswapV2Router02 router,
        address tokenAddress,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) internal returns (uint256[] memory amounts, bool success) {
        // Fails early if the token being swapped from is not the optionToken.
        require(path[0] == tokenAddress, "ERR_PATH_OPTION_START");

        // Approve the uniswap router to be able to transfer longOptionTokens from this contract.
        IERC20(tokenAddress).approve(address(router), uint256(-1));
        // Call the Uniswap V2 function to swap longOptionTokens to quoteTokens.
        (amounts) = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
        success = true;
    }

    /// @dev Calls UniswapV2Router02 function addLiquidity, provides exact amount of `tokenA`.
    /// @notice Assumes this contract has a current balance of `tokenA`, pulls required underlyingTokens from `msg.sender`.
    function addExactShortLiquidity(
        IUniswapV2Router02 router,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Pull `tokenB` from msg.sender to add to Uniswap V2 Pair.
        // Warning: calls into msg.sender using `safeTransferFrom`. Msg.sender is not trusted.
        IERC20(tokenB).safeTransferFrom(
            msg.sender,
            address(this),
            amountBDesired
        );
        // Approves Uniswap V2 Pair pull tokens from this contract.
        IERC20(tokenA).approve(address(router), uint256(-1));
        IERC20(tokenB).approve(address(router), uint256(-1));

        // Adds liquidity to Uniswap V2 Pair and returns liquidity shares to the "to" address.
        return
            router.addLiquidity(
                tokenA,
                tokenB,
                amountADesired,
                amountBDesired,
                amountADesired, // notice how amountAMin === amountADesired
                amountBMin,
                to,
                deadline
            );
    }

    /// @dev    Mints long + short option tokens by pulling underlyingTokens from `msg.sender`.
    /// @notice Pushes minted longOptionTokens to `msg.sender`. Keeps shortOptionTokens in this contract.
    ///         IMPORTANT: Must be used in conjuction with a function that uses the shortOptionTokens blanace.
    /// @param optionToken The option token to mint.
    /// @param quantity The amount of longOptionTokens to mint.
    function mintOptionsKeepShortOptions(IOption optionToken, uint256 quantity)
        internal
        returns (uint256, uint256)
    {
        // Pulls underlyingTokens from msg.sender to this contract.
        // Pushes underlyingTokens to option contract and mints option + redeem tokens to this contract.
        // Warning: calls into msg.sender using `safeTransferFrom`. Msg.sender is not trusted.
        (uint256 outputOptions, uint256 outputRedeems) =
            TraderLib.safeMint(optionToken, quantity, address(this));
        // Send longOptionTokens from minting option operation to msg.sender.
        IERC20(address(optionToken)).safeTransfer(msg.sender, quantity);
        return (outputOptions, outputRedeems);
    }

    /// @dev    Mints long + short option tokens using this contract's underlyingToken balance.
    /// @notice Keeps minted tokens in this contract.
    /// @param optionToken The option token to mint.
    /// @param quantity The amount of longOptionTokens to mint.
    function mintOptionsWithUnderlyingBalance(
        IOption optionToken,
        uint256 quantity
    ) internal returns (uint256, uint256) {
        address underlyingToken = optionToken.getUnderlyingTokenAddress();
        // Mint longOptionTokens using the underlyingTokens received from UniswapV2 flash swap to this contract.
        // Send underlyingTokens from this contract to the optionToken contract, then call mintOptions.
        IERC20(underlyingToken).safeTransfer(address(optionToken), quantity);
        return optionToken.mintOptions(address(this));
    }

    /// @dev    Closes options using this contract's balance of shortOptionTokens (redeem), and pulls optionTokens from `from`.
    /// @notice IMPORTANT: pulls optionTokens from `from`, an untrusted address.
    /// @param from The address to pull optionTokens from which will be burned to release underlyingTokens.
    /// @param optionToken The options that will be closed.
    /// @param quantity The quantity of optionTokens to burn.
    /// @return The quantity of underlyingTokens released.
    function closeOptionsWithShortBalance(
        address from,
        IOption optionToken,
        uint256 quantity
    ) internal returns (uint256) {
        // Close longOptionTokens using the redeemToken balance of this contract.
        IERC20(optionToken.redeemToken()).safeTransfer(
            address(optionToken),
            quantity
        );
        uint256 requiredLongOptions =
            getProportionalLongOptions(optionToken, quantity);

        // Send out the required amount of options from the `from` address.
        // WARNING: CALLS TO UNTRUSTED ADDRESS.
        IERC20(address(optionToken)).safeTransferFrom(
            from,
            address(optionToken),
            requiredLongOptions
        );

        // Close the options.
        (, , uint256 outputUnderlyings) =
            optionToken.closeOptions(address(this));
        return outputUnderlyings;
    }

    /// @dev    Removes liquidity from a uniswap pair, using this contract's balance of LP tokens.
    ///         Withdrawn tokens are sent to this contract.
    /// @notice `tokenA` is the redeemToken and `tokenB` is the underlyingToken.
    function removeLiquidity(
        IUniswapV2Router02 router,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    ) internal returns (uint256, uint256) {
        // Gets the Uniswap V2 Pair address for shortOptionToken (redeem) and underlyingTokens.
        // Transfers the LP tokens of the pair to this contract.
        address pair =
            IUniswapV2Factory(router.factory()).getPair(tokenA, tokenB);
        // Warning: internal call to a non-trusted address `msg.sender`.
        IERC20(pair).safeTransferFrom(msg.sender, address(this), liquidity);
        IERC20(pair).approve(address(router), uint256(-1));

        // Remove liquidity from Uniswap V2 pool to receive the reserve tokens (shortOptionTokens + UnderlyingTokens).
        (uint256 amountShortOptions, uint256 amountUnderlyingTokens) =
            router.removeLiquidity(
                tokenA,
                tokenB,
                liquidity,
                amountAMin,
                amountBMin,
                address(this),
                deadline
            );
        return (amountShortOptions, amountUnderlyingTokens);
    }

    /// @dev    Closes option tokens by buring option and redeem tokens.
    /// @notice Pulls option tokens from `msg.sender`, uses this contract's balance of redeemTokens.
    /// @param trader The Primitive V1 trader contract to handle the option closing operation.
    /// @param optionToken The option to close.
    /// @param amountShortOptions The quantity of short option tokens that will be burned to close the options.
    /// @param receiver The address that will be sent the underlyingTokens from closed options.
    function closeOptionsWithShortTokens(
        ITrader trader,
        IOption optionToken,
        uint256 amountShortOptions,
        address receiver
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Approves trader to pull longOptionTokens and shortOptionTokens from this contract to close options.
        IERC20(address(optionToken)).approve(address(trader), uint256(-1));
        IERC20(optionToken.redeemToken()).approve(address(trader), uint256(-1));
        // Calculate equivalent quantity of redeem (short option) tokens to close the long option position.
        // longOptions = shortOptions / strikeRatio
        uint256 requiredLongOptions =
            getProportionalLongOptions(optionToken, amountShortOptions);

        // Pull the required longOptionTokens from `msg.sender` to this contract.
        IERC20(address(optionToken)).safeTransferFrom(
            msg.sender,
            address(this),
            requiredLongOptions
        );

        // Trader pulls option and redeem tokens from this contract and sends them to the option contract.
        // Option and redeem tokens are then burned to release underlyingTokens.
        // UnderlyingTokens are sent to the "receiver" address.
        return trader.safeClose(optionToken, requiredLongOptions, receiver);
    }

    // ====== View ======

    /// @dev    Calculates the effective premium, denominated in underlyingTokens, to "buy" `quantity` of optionTokens.
    /// @notice UniswapV2 adds a 0.3009027% fee which is applied to the premium as 0.301%.
    ///         IMPORTANT: If the pair's reserve ratio is incorrect, there could be a 'negative' premium.
    ///         Buying negative premium options will pay out redeemTokens.
    ///         An 'incorrect' ratio occurs when the (reserves of redeemTokens / strike ratio) >= reserves of underlyingTokens.
    ///         Implicitly uses the `optionToken`'s underlying and redeem tokens for the pair.
    /// @param  router The UniswapV2Router02 contract.
    /// @param  optionToken The optionToken to get the premium cost of purchasing.
    /// @param  quantity The quantity of long option tokens that will be purchased.
    function getOpenPremium(
        IUniswapV2Router02 router,
        IOption optionToken,
        uint256 quantity
    ) internal view returns (uint256, uint256) {
        // longOptionTokens are opened by doing a swap from redeemTokens to underlyingTokens effectively.
        address[] memory path = new address[](2);
        path[0] = optionToken.redeemToken();
        path[1] = optionToken.getUnderlyingTokenAddress();

        // `quantity` of underlyingTokens are output from the swap.
        // They are used to mint options, which will mint `quantity` * quoteValue / baseValue amount of redeemTokens.
        uint256 redeemsMinted =
            getProportionalShortOptions(optionToken, quantity);

        // The loanRemainderInUnderlyings will be the amount of underlyingTokens that are needed from the original
        // transaction caller in order to pay the flash swap.
        // IMPORTANT: THIS IS EFFECTIVELY THE PREMIUM PAID IN UNDERLYINGTOKENS TO PURCHASE THE OPTIONTOKEN.
        uint256 loanRemainderInUnderlyings;

        // Economically, negativePremiumPaymentInRedeems value should always be 0.
        // In the case that we minted more redeemTokens than are needed to pay back the flash swap,
        // (short -> underlying is a positive trade), there is an effective negative premium.
        // In that case, this function will send out `negativePremiumAmount` of redeemTokens to the original caller.
        // This means the user gets to keep the extra redeemTokens for free.
        // Negative premium amount is the opposite difference of the loan remainder: (paid - flash loan amount)
        uint256 negativePremiumPaymentInRedeems;

        // Need to return tokens from the flash swap by returning shortOptionTokens and any remainder of underlyingTokens.

        // Since the borrowed amount is underlyingTokens, and we are paying back in redeemTokens,
        // we need to see how much redeemTokens must be returned for the borrowed amount.
        // We can find that value by doing the normal swap math, getAmountsIn will give us the amount
        // of redeemTokens are needed for the output amount of the flash loan.
        // IMPORTANT: amountsIn[0] is how many short tokens we need to pay back.
        // This value is most likely greater than the amount of redeemTokens minted.
        uint256[] memory amountsIn = router.getAmountsIn(quantity, path);

        uint256 redeemsRequired = amountsIn[0]; // the amountIn of redeemTokens based on the amountOut of `quantity`.
        // If redeemsMinted is greater than redeems required, there is a cost of 0, implying a negative premium.
        uint256 redeemCostRemaining =
            redeemsRequired > redeemsMinted
                ? redeemsRequired.sub(redeemsMinted)
                : 0;
        // If there is a negative premium, calculate the quantity of remaining redeemTokens after the `redeemsMinted` is spent.
        negativePremiumPaymentInRedeems = redeemsMinted > redeemsRequired
            ? redeemsMinted.sub(redeemsRequired)
            : 0;

        // In most cases, there will be an outstanding cost (assuming we minted less redeemTokens than the
        // required amountIn of redeemTokens for the swap).
        if (redeemCostRemaining > 0) {
            // The user won't want to pay back the remaining cost in redeemTokens,
            // because they borrowed underlyingTokens to mint them in the first place.
            // So instead, we get the quantity of underlyingTokens that could be paid instead.
            // We can calculate this using normal swap math.
            // getAmountsOut will return the quantity of underlyingTokens that are output,
            // based on some input of redeemTokens.
            // The input redeemTokens is the remaining redeemToken cost, and the output
            // underlyingTokens is the proportional amount of underlyingTokens.
            // amountsOut[1] is then the outstanding flash loan value denominated in underlyingTokens.
            uint256[] memory amountsOut =
                router.getAmountsOut(redeemCostRemaining, path);

            // Returning withdrawn tokens to the pair has a fee of .003 / .997 = 0.3009027% which must be applied.
            loanRemainderInUnderlyings = (
                amountsOut[1].mul(100000).add(amountsOut[1].mul(301))
            )
                .div(100000);
        }
        return (loanRemainderInUnderlyings, negativePremiumPaymentInRedeems);
    }

    /// @dev    Calculates the effective premium, denominated in underlyingTokens, to "sell" option tokens.
    /// @param  router The UniswapV2Router02 contract.
    /// @param  optionToken The optionToken to get the premium cost of purchasing.
    /// @param  quantity The quantity of short option tokens that will be closed.
    function getClosePremium(
        IUniswapV2Router02 router,
        IOption optionToken,
        uint256 quantity
    ) internal view returns (uint256, uint256) {
        // longOptionTokens are closed by doing a swap from underlyingTokens to redeemTokens.
        address[] memory path = new address[](2);
        path[0] = optionToken.getUnderlyingTokenAddress();
        path[1] = optionToken.redeemToken();
        uint256 outputUnderlyings =
            getProportionalLongOptions(optionToken, quantity);
        // The loanRemainder will be the amount of underlyingTokens that are needed from the original
        // transaction caller in order to pay the flash swap.
        uint256 loanRemainder;

        // Economically, underlyingPayout value should always be greater than 0, or this trade shouldn't be made.
        // If an underlyingPayout is greater than 0, it means that the redeemTokens borrowed are worth less than the
        // underlyingTokens received from closing the redeemToken<>optionTokens.
        // If the redeemTokens are worth more than the underlyingTokens they are entitled to,
        // then closing the redeemTokens will cost additional underlyingTokens. In this case,
        // the transaction should be reverted. Or else, the user is paying extra at the expense of
        // rebalancing the pool.
        uint256 underlyingPayout;

        // Need to return tokens from the flash swap by returning underlyingTokens.

        // Since the borrowed amount is redeemTokens, and we are paying back in underlyingTokens,
        // we need to see how much underlyingTokens must be returned for the borrowed amount.
        // We can find that value by doing the normal swap math, getAmountsIn will give us the amount
        // of underlyingTokens are needed for the output amount of the flash loan.
        // IMPORTANT: amountsIn 0 is how many underlyingTokens we need to pay back.
        // This value is most likely greater than the amount of underlyingTokens received from closing.
        uint256[] memory amountsIn = router.getAmountsIn(quantity, path);

        uint256 underlyingsRequired = amountsIn[0]; // the amountIn required of underlyingTokens based on the amountOut of flashloanQuantity
        // If outputUnderlyings (received from closing) is greater than underlyings required,
        // there is a positive payout.
        underlyingPayout = outputUnderlyings > underlyingsRequired
            ? outputUnderlyings.sub(underlyingsRequired)
            : 0;

        // If there is a negative payout, calculate the remaining cost of underlyingTokens.
        uint256 underlyingCostRemaining =
            underlyingsRequired > outputUnderlyings
                ? underlyingsRequired.sub(outputUnderlyings)
                : 0;

        // In the case that there is a negative payout (additional underlyingTokens are required),
        // get the remaining cost into the `loanRemainder` variable and also check to see
        // if a user is willing to pay the negative cost. There is no rational economic incentive for this.
        if (underlyingCostRemaining > 0) {
            loanRemainder = underlyingCostRemaining;
        }

        return (underlyingPayout, loanRemainder);
    }

    // ==== Primitive V1 =====

    /// @dev    Calculates the proportional quantity of long option tokens per short option token.
    /// @notice For each long option token, there is quoteValue / baseValue quantity of short option tokens.
    function getProportionalLongOptions(
        IOption optionToken,
        uint256 quantityShort
    ) internal view returns (uint256) {
        uint256 quantityLong =
            quantityShort.mul(optionToken.getBaseValue()).div(
                optionToken.getQuoteValue()
            );

        return quantityLong;
    }

    /// @dev    Calculates the proportional quantity of short option tokens per long option token.
    /// @notice For each short option token, there is baseValue / quoteValue quantity of long option tokens.
    function getProportionalShortOptions(
        IOption optionToken,
        uint256 quantityLong
    ) internal view returns (uint256) {
        uint256 quantityShort =
            quantityLong.mul(optionToken.getQuoteValue()).div(
                optionToken.getBaseValue()
            );

        return quantityShort;
    }

    // ==== Uniswap V2 Library =====

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303" // init code hash
                    )
                )
            )
        );
    }
}
