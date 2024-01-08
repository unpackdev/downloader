// SPDX-License-Identifier: BSD-3-Clause AND MIT
pragma solidity 0.8.6;

import "./IERC20.sol";
import "./IUSDC.sol";
import "./SafeERC20.sol";
import "./FixedPoint.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./LongShortPair.sol";
import "./Staking.sol";

/**
* @title Domination Finance vault
* @notice Provide and withdraw dominance pair liquidity in fewer transactions.
*/
contract Vault {
    using SafeERC20 for IERC20;
    using SafeERC20 for IUSDC;
    using FixedPoint for FixedPoint.Unsigned;
    using FixedPoint for FixedPoint.Signed;

    event VaultDeposited(address user, address lsp, uint amountUSDC);

    enum WithdrawMode { Basic, Redeem, Settle }

    /**
    * @notice Deposit USDC into the vault. Convert it all into LSP liquidity
    * @dev Keep params in usage order https://levelup.gitconnected.com/stack-too-deep-error-in-solidity-ca83326ff0f0
    * @param usdcForArb Portion of supplied USDC to use for arbitrage. Will be deposited along with profits.
    * @param tokensToBuyForArb If buying+redeeming to arb pools, amount of tokens. See arbitrage() for more detail.
    * @param router Address of Uniswap, Quickswap, etc. router.
    * @param priceDeviation_ FixedPoint.Unsigned fraction: maximum % difference between long+short and collateralPerPair
    * @param lsp LongShortPair for the target dominance pair.
    * @param amount How much USDC to supply.
    * @param longStaking Optional. Staking contract for long LP token. Must be during staking window.
    * @param shortStaking Optional. Staking contract for long LP token. Must be during staking window.
    * @param deadline timestamp beyond which tx will revert.
    */
    function deposit(
        uint usdcForArb,
        uint tokensToBuyForArb,
        IUniswapV2Router02 router,
        FixedPoint.Unsigned calldata priceDeviation_,
        LongShortPair lsp,
        Signature calldata usdcSignature,
        uint amount,
        Staking longStaking,
        Staking shortStaking,
        uint deadline
    ) public {
        require(deadline >= block.timestamp, "EXPIRED"); // save gas, fail early

        IUSDC USDC = IUSDC(address(lsp.collateralToken()));
        if (hasSignature(usdcSignature)) {
            USDC.permit(msg.sender, address(this), amount, deadline, usdcSignature.v, usdcSignature.r, usdcSignature.s);
        }
        USDC.safeTransferFrom(msg.sender, address(this), amount);

        if (usdcForArb > 0) {
            _arbitrage(usdcForArb, tokensToBuyForArb, lsp, router, deadline);
            amount = USDC.balanceOf(address(this));
        }

        (uint tokensToMint, uint mintUSDC, uint longValue, uint shortValue) = computeLPAmounts(
             router, priceDeviation_, lsp, amount
        );
        require(longValue + shortValue + mintUSDC <= amount, "BUG");

        USDC.approve(address(lsp), mintUSDC);
        lsp.create(tokensToMint);

        USDC.approve(address(router), shortValue + longValue);

        { // pool and stake the long tokens.

            // Avoid "stack to deep" error. Copy to top of stack.
            IUniswapV2Router02 router_ = router;

            IERC20 long = IERC20(lsp.longToken());
            long.approve(address(router_), tokensToMint);

            {
                // Avoid "stack to deep" error. Copy to top of stack.
                uint deadline_ = deadline;

                address recipient =
                    address(longStaking) == address(0)
                        ? msg.sender
                        : address(this);

                router_.addLiquidity(
                    address(long),
                    address(USDC),
                    tokensToMint,
                    longValue,
                    tokensToMint,
                    longValue,
                    recipient,
                    deadline_
                );
            }

            if (address(longStaking) != address(0)) {
                IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
                IERC20 longLP = IERC20(factory.getPair(address(long), address(USDC)));
                uint longLPAmount = longLP.balanceOf(address(this));
                longLP.approve(address(longStaking), longLPAmount);
                longStaking.stakeFor(msg.sender, longLPAmount);
            }
        }

        { // pool and stake short tokens

            // Avoid "stack to deep" error. Copy to top of stack.
            IUniswapV2Router02 router_ = router;

            IERC20 short = IERC20(lsp.shortToken());
            short.approve(address(router_), tokensToMint);

            {
                // Avoid "stack to deep" error. Copy to top of stack.
                uint deadline_ = deadline;

                address recipient =
                    address(shortStaking) == address(0)
                        ? msg.sender
                        : address(this);

                router_.addLiquidity(
                    address(short),
                    address(USDC),
                    tokensToMint,
                    shortValue,
                    tokensToMint,
                    shortValue,
                    recipient,
                    deadline_
                );
            }

            if (address(shortStaking) != address(0)) {
                IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
                IERC20 shortLP = IERC20(factory.getPair(address(short), address(USDC)));
                uint shortLPAmount = shortLP.balanceOf(address(this));
                shortLP.approve(address(shortStaking), shortLPAmount);
                shortStaking.stakeFor(msg.sender, shortLPAmount);
            }
        }
        emit VaultDeposited(msg.sender, address(lsp), amount);
    }

    /**
    * @notice Compute the percent difference between collateralPerPair and the sum of synth prices.
    *         A nonzero difference indicates an arbitrage opportunity.
    * @return [(long price + short price) - collateralPerPair] / collateralPerPair
    */
    function priceDeviation (
        FixedPoint.Unsigned memory long,
        FixedPoint.Unsigned memory short,
        FixedPoint.Unsigned memory collateralPerPair
    ) internal pure returns (FixedPoint.Unsigned memory) {
        FixedPoint.Signed memory max = FixedPoint.fromUnsigned(collateralPerPair);
        FixedPoint.Signed memory diff = FixedPoint.fromUnsigned(long.add(short)).sub(max);
        return abs(diff.div(max));
    }

    ///@notice absolute value for FixedPoint library
    function abs(FixedPoint.Signed memory x) internal pure returns (FixedPoint.Unsigned memory) {
        if (x.isLessThan(0)) {
            return FixedPoint.fromSigned(FixedPoint.Signed(0).sub(x));
        } else {
            return FixedPoint.fromSigned(x);
        }
    }

    ///@notice an EIP-712 signature for use with Uniswap/USDC permits
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    function hasSignature(Signature calldata s) pure internal returns (bool) {
        return s.v != 0 && s.r != 0 && s.s != 0;
    }

    /***
    * @notice Redeem both long and short LP tokens for USDC. LP tokens must be unstaked first.
    * @param priceDeviation_ FixedPoint.Unsigned fraction: maximum % difference between long+short and collateralPerPair
    * @param lsp LongShortPair for the target dominance pair
    * @param longLPAmount wei of long LP tokens to redeem
    * @param shortLPAmount wei of long LP tokens to redeem
    * @param router Address of Uniswap, Quickswap, etc. router.
    * @param USDC address of this network's USDC: denominator of pools and collateral for token.
    * @param deadline timestamp beyond which tx will revert.
    * @param longSignature optional EIP-712 (v,r,s) signature
    * @param shortSignature optional EIP-712 (v,r,s) signature
    * @param withdrawMode action to take with redeemed synths: 0 nothing, 1 redeem 50:50, 2 settle after expiry
    */
    function withdraw(
        FixedPoint.Unsigned calldata priceDeviation_,
        LongShortPair lsp,
        uint longLPAmount,
        uint shortLPAmount,
        IUniswapV2Router02 router,
        uint deadline,
        Signature calldata longSignature,
        Signature calldata shortSignature,
        WithdrawMode withdrawMode
    ) public {

        IERC20 long = IERC20(lsp.longToken());
        IERC20 short = IERC20(lsp.shortToken());

        { // LP tokens in scope

            { // factory in scope
                IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
                checkSlippage(long, short, priceDeviation_, lsp, factory);
            }

            IUniswapV2Pair longLP;
            IUniswapV2Pair shortLP;
            {
                IUniswapV2Factory factory = IUniswapV2Factory(router.factory());

                IERC20 USDC = lsp.collateralToken(); // need to cut down stack
                longLP = IUniswapV2Pair(factory.getPair(address(long), address(USDC)));
                shortLP = IUniswapV2Pair(factory.getPair(address(short), address(USDC)));
            }

            if (hasSignature(longSignature)) {
                longLP.permit(
                    msg.sender,
                    address(this),
                    longLPAmount,
                    deadline,
                    longSignature.v,
                    longSignature.r,
                    longSignature.s);
            }
            if (hasSignature(shortSignature)) {
                shortLP.permit(
                    msg.sender,
                    address(this),
                    shortLPAmount,
                    deadline,
                    shortSignature.v,
                    shortSignature.r,
                    shortSignature.s);
            }

            shortLP.approve(address(router), shortLPAmount);
            longLP.approve(address(router), longLPAmount);
            IERC20(address(longLP)).safeTransferFrom(msg.sender, address(this), longLPAmount);
            IERC20(address(shortLP)).safeTransferFrom(msg.sender, address(this), shortLPAmount);

        }

        {
            IERC20 USDC = lsp.collateralToken();
            address sender = withdrawMode == WithdrawMode.Basic ? msg.sender : address(this);

            router.removeLiquidity(
                address(long),
                address(USDC),
                longLPAmount,
                0,
                0,
                sender,
                deadline
            );
            router.removeLiquidity(
                address(short),
                address(USDC),
                shortLPAmount,
                0,
                0,
                sender,
                deadline
            );

            if (withdrawMode == WithdrawMode.Redeem) {
                uint synthToRedeem = long.balanceOf(address(this)) > short.balanceOf(address(this))
                    ? short.balanceOf(address(this))
                    : long.balanceOf(address(this));
                lsp.redeem(synthToRedeem);
                USDC.safeTransfer(msg.sender, USDC.balanceOf(address(this)));
                long.safeTransfer(msg.sender, long.balanceOf(address(this)));
                short.safeTransfer(msg.sender, short.balanceOf(address(this)));
            } else if (withdrawMode == WithdrawMode.Settle) {
                lsp.settle(long.balanceOf(address(this)), short.balanceOf(address(this)));
                USDC.safeTransfer(msg.sender, USDC.balanceOf(address(this)));
            }
        }
    }

    /**
    * @notice Arb a pair's pools: use supplied USDC to mint+sell or buy+redeem. Return USDC + profits to sender.
    * @dev compute optimal arb amount off-chain
    * @param amount USDC to use for arbitrage
    * @param tokensToBuy Number of tokens to buy and redeem. If 0, mint and sell with supplied USDC
    * @param lsp LongShortPair for the target dominance pair
    * @param router Address of Uniswap, Quickswap, etc. router.
    * @param deadline Timestamp beyond which tx will revert.
    * @param usdcSignature optional signature
    */
    function arbitrage(
        uint amount,
        uint tokensToBuy,
        LongShortPair lsp,
        IUniswapV2Router02 router,
        uint deadline,
        Signature calldata usdcSignature
    ) external {
        IUSDC USDC = IUSDC(address(lsp.collateralToken()));
        if (hasSignature(usdcSignature)) {
            USDC.permit(msg.sender, address(this), amount, deadline, usdcSignature.v, usdcSignature.r, usdcSignature.s);
        }
        USDC.safeTransferFrom(msg.sender, address(this), amount);

        _arbitrage(amount, tokensToBuy, lsp, router, deadline);

        USDC.safeTransfer(msg.sender, USDC.balanceOf(address(this)));
    }

    /**
    * @notice Arb a pair's pools: use supplied USDC to mint+sell or buy+redeem.
    * @dev compute optimal arb amount off-chain
    * @dev precondition: vault has USDC bal >= usdcToUse
    * @param usdcToUse USDC to use for arbitrage
    * @param tokensToBuy Number of tokens to buy and redeem. If 0, mint and sell with supplied USDC
    * @param lsp LongShortPair for the target dominance pair
    * @param router Address of Uniswap, Quickswap, etc. router.
    * @param deadline Timestamp beyond which tx will revert.
    */
    function _arbitrage(
        uint usdcToUse,
        uint tokensToBuy,
        LongShortPair lsp,
        IUniswapV2Router02 router,
        uint deadline
    ) internal {
        require(usdcToUse > 0, "INVALID ARGUMENTS"); // must have some amount of USDC to work with
        IUSDC USDC = IUSDC(address(lsp.collateralToken()));
        IERC20 long = lsp.longToken();
        IERC20 short = lsp.shortToken();

        uint startUSDCbal = USDC.balanceOf(address(this));

        if (tokensToBuy > 0) { // buy and redeem equal amounts of token with the supplied USDC
            USDC.approve(address(router), usdcToUse);

            address[] memory path = new address[](2); // can't cast static array to dynamic >:(
            path[0] = address(USDC);

            path[1] = address(long);
            router.swapTokensForExactTokens(
                tokensToBuy,
                usdcToUse,
                path,
                address(this),
                deadline
            );
            path[1] = address(short);
            router.swapTokensForExactTokens(
                tokensToBuy,
                usdcToUse,
                path,
                address(this),
                deadline
            );

            long.approve(address(lsp), tokensToBuy);
            short.approve(address(lsp), tokensToBuy);
            lsp.redeem(tokensToBuy);
        } else { // mint tokens with usdcToUse and sell them all
            USDC.approve(address(lsp), usdcToUse);
            uint tokensToMint = usdcToUse / (lsp.collateralPerPair() / FixedPoint.fromUnscaledUint(1).rawValue);
            lsp.create(tokensToMint);

            long.approve(address(router), tokensToMint);
            short.approve(address(router), tokensToMint);

            address[] memory path = new address[](2);
            path[1] = address(USDC);

            path[0] = address(long);
            router.swapExactTokensForTokens(
                tokensToMint,
                0,
                path,
                address(this),
                deadline
            );
            path[0] = address(short);
            router.swapExactTokensForTokens(
                tokensToMint,
                0,
                path,
                address(this),
                deadline
            );
        }

        // We could check price deviation, but that requires more complicated parameters and more gas. If you need to
        // arbitrage pools very precisely, increase gas for a fast transaction or write your own contract.
        uint USDCbal = USDC.balanceOf(address(this));
        require(USDCbal > startUSDCbal, "UNPROFITABLE"); // arbing in the right direction makes money
    }

    /**
     * @notice Check the market value of a user's LSP liquidity, in USDC.
     */
    function depositedFor(
        IUniswapV2Factory factory,
        LongShortPair lsp,
        Staking longStaking,
        Staking shortStaking,
        address user
    ) public view returns (uint) {
        IERC20 USDC = lsp.collateralToken();
        IERC20 longPool = IERC20(factory.getPair(address(lsp.longToken()), address(USDC)));
        IERC20 shortPool = IERC20(factory.getPair(address(lsp.shortToken()), address(USDC)));

        uint longUSDC = USDC.balanceOf(address(longPool));
        uint shortUSDC = USDC.balanceOf(address(shortPool));

        FixedPoint.Unsigned memory longShare =
            FixedPoint.fromUnscaledUint(longPool.balanceOf(user))
            .add(address(longStaking) != address(0)
                ? longStaking.totalStakedFor(user)
                : 0)
            .div(longPool.totalSupply());
        FixedPoint.Unsigned memory shortShare =
            FixedPoint.fromUnscaledUint(shortPool.balanceOf(user))
            .add(address(shortStaking) != address(0)
                ? shortStaking.totalStakedFor(user)
                : 0)
            .div(shortPool.totalSupply());

        return longShare.mul(FixedPoint.Unsigned(longUSDC))
            .add(shortShare.mul(FixedPoint.Unsigned(shortUSDC)))
            .mul(2)
            .rawValue;
    }

    function computeLPAmounts(
        IUniswapV2Router02 router,
        FixedPoint.Unsigned calldata priceDeviation_,
        LongShortPair lsp,
        uint amount
    ) internal view returns (
        uint tokensToMint,
        uint mintUSDC,
        uint longValue,
        uint shortValue
    ) {
        IERC20 long = IERC20(lsp.longToken());
        IERC20 short = IERC20(lsp.shortToken());

        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        (
            FixedPoint.Unsigned memory longPrice,
            FixedPoint.Unsigned memory shortPrice,
            FixedPoint.Unsigned memory collateralPerPair
        ) = checkSlippage(long, short, priceDeviation_, lsp, factory);

        tokensToMint = FixedPoint.Unsigned(amount)
            .div(
                collateralPerPair
                .add(longPrice)
                .add(shortPrice)).rawValue;
        mintUSDC = collateralPerPair.mul(FixedPoint.Unsigned(tokensToMint)).rawValue;
        longValue = longPrice.mul(FixedPoint.Unsigned(tokensToMint)).rawValue;
        shortValue = shortPrice.mul(FixedPoint.Unsigned(tokensToMint)).rawValue;
    }

    function checkSlippage(
        IERC20 long,
        IERC20 short,
        FixedPoint.Unsigned calldata priceDeviation_,
        LongShortPair lsp,
        IUniswapV2Factory factory
    ) internal view returns (
        FixedPoint.Unsigned memory longPrice,
        FixedPoint.Unsigned memory shortPrice,
        FixedPoint.Unsigned memory collateralPerPair
    ) {
        IERC20 USDC = IERC20(lsp.collateralToken());
        longPrice = getMarketPrice(long, USDC, factory);
        shortPrice = getMarketPrice(short, USDC, factory);
        collateralPerPair = FixedPoint.Unsigned(lsp.collateralPerPair());
        require(
            priceDeviation(longPrice, shortPrice, collateralPerPair).isLessThanOrEqual(priceDeviation_),
            "SLIPPAGE");
    }


    /**
    * @notice get USDC per synth market price. FixedPoint for fractional component
    * @return FixedPoint.Unsigned market price ($/synth)
    * @param synth token paired with USDC
    * @param USDC address of this network's USDC: denominator of pools and collateral for token.
    * @param factory query price for this DEX
    */
    function getMarketPrice(
        IERC20 synth,
        IERC20 USDC,
        IUniswapV2Factory factory
    ) internal view returns (FixedPoint.Unsigned memory) {
        address pool = factory.getPair(address(synth), address(USDC));
        FixedPoint.Unsigned memory USDCbal = FixedPoint.fromUnscaledUint(USDC.balanceOf(pool));
        uint synthbal = synth.balanceOf(pool);
        require(synthbal > 0, "No synth pooled");
        return USDCbal.div(synthbal);
    }

    /**
    * @notice The vault should never hold any tokens. This method allows anyone to withdraw a token's entire balance.
    *         It should be used if tokens are mistakenly sent to the contract, or if a bug causes leftover balances.
    * @param token address of a ERC20
    */
    function rescue(IERC20 token) external {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}
