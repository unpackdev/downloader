// SPDX-License-Identifier: MIT
// Copyright 2021 Primitive Finance
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.2;

/**
 * @title   Primitive Liquidity
 * @author  Primitive
 * @notice  Manage liquidity on Uniswap & Sushiswap Venues.
 * @dev     @primitivefi/v1-connectors@v2.0.0
 */

// Open Zeppelin
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
// Interfaces
import "./IPrimitiveLiquidity.sol";
// Primitive
import "./PrimitiveConnector.sol";
import "./CoreLib.sol";

interface DaiPermit {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract PrimitiveLiquidity is PrimitiveConnector, IPrimitiveLiquidity, ReentrancyGuard {
    using SafeERC20 for IERC20; // Reverts when `transfer` or `transferFrom` erc20 calls don't return proper data
    using SafeMath for uint256; // Reverts on math underflows/overflows

    event Initialized(address indexed from); // Emitted on deployment.
    event AddLiquidity(address indexed from, address indexed option, uint256 sum);
    event RemoveLiquidity(address indexed from, address indexed option, uint256 sum);

    IUniswapV2Factory private _factory; // The Uniswap V2 factory contract to get pair addresses from.
    IUniswapV2Router02 private _router; // The Uniswap Router contract used to interact with the protocol.

    // ===== Constructor =====
    constructor(
        address weth_,
        address primitiveRouter_,
        address factory_,
        address router_
    ) public PrimitiveConnector(weth_, primitiveRouter_) {
        _factory = IUniswapV2Factory(factory_);
        _router = IUniswapV2Router02(router_);
        emit Initialized(_msgSender());
    }

    // ===== Liquidity Operations =====

    /**
     * @dev     Adds redeemToken liquidity to a redeem<>underlyingToken pair by minting redeemTokens with underlyingTokens.
     * @notice  Pulls underlying tokens from `getCaller()` and pushes UNI-V2 liquidity tokens to the "getCaller()" address.
     *          underlyingToken -> redeemToken -> UNI-V2.
     * @param   optionAddress The address of the optionToken to get the redeemToken to mint then provide liquidity for.
     * @param   quantityOptions The quantity of underlyingTokens to use to mint option + redeem tokens.
     * @param   amountBMax The quantity of underlyingTokens to add with redeemTokens to the Uniswap V2 Pair.
     * @param   amountBMin The minimum quantity of underlyingTokens expected to provide liquidity with.
     * @param   deadline The timestamp to expire a pending transaction.
     * @return  Returns (amountA, amountB, liquidity) amounts.
     */
    function addShortLiquidityWithUnderlying(
        address optionAddress,
        uint256 quantityOptions,
        uint256 amountBMax,
        uint256 amountBMin,
        uint256 deadline
    )
        public
        override
        nonReentrant
        onlyRegistered(IOption(optionAddress))
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 amountA;
        uint256 amountB;
        uint256 liquidity;
        address underlying = IOption(optionAddress).getUnderlyingTokenAddress();
        // Pulls total = (quantityOptions + amountBMax) of underlyingTokens from `getCaller()` to this contract.
        {
            uint256 sum = quantityOptions.add(amountBMax);
            _transferFromCaller(underlying, sum);
        }
        // Pushes underlyingTokens to option contract and mints option + redeem tokens to this contract.
        IERC20(underlying).safeTransfer(optionAddress, quantityOptions);
        (, uint256 outputRedeems) = IOption(optionAddress).mintOptions(address(this));

        {
            // scope for adding exact liquidity, avoids stack too deep errors
            IOption optionToken = IOption(optionAddress);
            address redeem = optionToken.redeemToken();
            AddAmounts memory params;
            params.amountAMax = outputRedeems;
            params.amountBMax = amountBMax;
            params.amountAMin = outputRedeems;
            params.amountBMin = amountBMin;
            params.deadline = deadline;
            // Approves Uniswap V2 Pair pull tokens from this contract.
            checkApproval(redeem, address(_router));
            checkApproval(underlying, address(_router));
            // Adds liquidity to Uniswap V2 Pair and returns liquidity shares to the "getCaller()" address.
            (amountA, amountB, liquidity) = _addLiquidity(redeem, underlying, params);
            // Check for exact liquidity provided.
            assert(amountA == outputRedeems);
            // Return remaining tokens
            _transferToCaller(underlying);
            _transferToCaller(redeem);
            _transferToCaller(address(optionToken));
        }
        {
            // scope for event, avoids stack too deep errors
            address a0 = optionAddress;
            uint256 q0 = quantityOptions;
            uint256 q1 = amountBMax;
            emit AddLiquidity(getCaller(), a0, q0.add(q1));
        }
        return (amountA, amountB, liquidity);
    }

    /**
     * @dev     Adds redeemToken liquidity to a redeem<>underlyingToken pair by minting shortOptionTokens with underlyingTokens.
     *          Doesn't check for registered optionAddress because the returned function does.
     * @notice  Pulls underlying tokens from `getCaller()` and pushes UNI-V2 liquidity tokens to the "getCaller()" address.
     *          underlyingToken -> redeemToken -> UNI-V2. Uses permit so user does not need to `approve()` our contracts.
     * @param   optionAddress The address of the optionToken to get the redeemToken to mint then provide liquidity for.
     * @param   quantityOptions The quantity of underlyingTokens to use to mint option + redeem tokens.
     * @param   amountBMax The quantity of underlyingTokens to add with shortOptionTokens to the Uniswap V2 Pair.
     * @param   amountBMin The minimum quantity of underlyingTokens expected to provide liquidity with.
     * @param   deadline The timestamp to expire a pending transaction.
     * @return  Returns (amountA, amountB, liquidity) amounts.
     */
    function addShortLiquidityWithUnderlyingWithPermit(
        address optionAddress,
        uint256 quantityOptions,
        uint256 amountBMax,
        uint256 amountBMin,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        IERC20Permit underlying =
            IERC20Permit(IOption(optionAddress).getUnderlyingTokenAddress());
        uint256 sum = quantityOptions.add(amountBMax);
        underlying.permit(getCaller(), address(_primitiveRouter), sum, deadline, v, r, s);
        return
            addShortLiquidityWithUnderlying(
                optionAddress,
                quantityOptions,
                amountBMax,
                amountBMin,
                deadline
            );
    }

    /**
     * @dev     Doesn't check for registered optionAddress because the returned function does.
     * @notice  Specialized function for `permit` calling on Put options (DAI).
     */
    function addShortLiquidityDAIWithPermit(
        address optionAddress,
        uint256 quantityOptions,
        uint256 amountBMax,
        uint256 amountBMin,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        DaiPermit dai = DaiPermit(IOption(optionAddress).getUnderlyingTokenAddress());
        address caller = getCaller();
        dai.permit(
            caller,
            address(_primitiveRouter),
            IERC20Permit(address(dai)).nonces(caller),
            deadline,
            true,
            v,
            r,
            s
        );
        return
            addShortLiquidityWithUnderlying(
                optionAddress,
                quantityOptions,
                amountBMax,
                amountBMin,
                deadline
            );
    }

    /**
     * @dev     Adds redeemToken liquidity to a redeem<>underlyingToken pair by minting shortOptionTokens with underlyingTokens.
     * @notice  Pulls underlying tokens from `getCaller()` and pushes UNI-V2 liquidity tokens to the `getCaller()` address.
     *          underlyingToken -> redeemToken -> UNI-V2.
     * @param   optionAddress The address of the optionToken to get the redeemToken to mint then provide liquidity for.
     * @param   quantityOptions The quantity of underlyingTokens to use to mint option + redeem tokens.
     * @param   amountBMax The quantity of underlyingTokens to add with shortOptionTokens to the Uniswap V2 Pair.
     * @param   amountBMin The minimum quantity of underlyingTokens expected to provide liquidity with.
     * @param   deadline The timestamp to expire a pending transaction.
     * @return  Returns (amountA, amountB, liquidity) amounts.
     */
    function addShortLiquidityWithETH(
        address optionAddress,
        uint256 quantityOptions,
        uint256 amountBMax,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        payable
        override
        nonReentrant
        onlyRegistered(IOption(optionAddress))
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(
            msg.value >= quantityOptions.add(amountBMax),
            "PrimitiveLiquidity: INSUFFICIENT"
        );

        uint256 amountA;
        uint256 amountB;
        uint256 liquidity;
        address underlying = IOption(optionAddress).getUnderlyingTokenAddress();
        require(underlying == address(_weth), "PrimitiveLiquidity: NOT_WETH");

        _depositETH(); // Wraps `msg.value` to Weth.
        // Pushes Weth to option contract and mints option + redeem tokens to this contract.
        IERC20(underlying).safeTransfer(optionAddress, quantityOptions);
        (, uint256 outputRedeems) = IOption(optionAddress).mintOptions(address(this));

        {
            // scope for adding exact liquidity, avoids stack too deep errors
            IOption optionToken = IOption(optionAddress);
            address redeem = optionToken.redeemToken();
            AddAmounts memory params;
            params.amountAMax = outputRedeems;
            params.amountBMax = amountBMax;
            params.amountAMin = outputRedeems;
            params.amountBMin = amountBMin;
            params.deadline = deadline;

            // Approves Uniswap V2 Pair pull tokens from this contract.
            checkApproval(redeem, address(_router));
            checkApproval(underlying, address(_router));
            // Adds liquidity to Uniswap V2 Pair.
            (amountA, amountB, liquidity) = _addLiquidity(redeem, underlying, params);
            assert(amountA == outputRedeems); // Check for exact liquidity provided.
            // Return remaining tokens and ether.
            _withdrawETH();
            _transferToCaller(redeem);
            _transferToCaller(address(optionToken));
        }
        {
            // scope for event, avoids stack too deep errors
            address a0 = optionAddress;
            uint256 q0 = quantityOptions;
            uint256 q1 = amountBMax;
            emit AddLiquidity(getCaller(), a0, q0.add(q1));
        }
        return (amountA, amountB, liquidity);
    }

    struct AddAmounts {
        uint256 amountAMax;
        uint256 amountBMax;
        uint256 amountAMin;
        uint256 amountBMin;
        uint256 deadline;
    }

    /**
     * @notice  Calls UniswapV2Router02.addLiquidity() function using this contract's tokens.
     * @param   tokenA The first token of the Uniswap Pair to add as liquidity.
     * @param   tokenB The second token of the Uniswap Pair to add as liquidity.
     * @param   params The amounts specified to be added as liquidity. Adds exact short options.
     * @return  Returns (amountTokenA, amountTokenB, liquidity) amounts.
     */
    function _addLiquidity(
        address tokenA,
        address tokenB,
        AddAmounts memory params
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return
            _router.addLiquidity(
                tokenA,
                tokenB,
                params.amountAMax,
                params.amountBMax,
                params.amountAMin,
                params.amountBMin,
                getCaller(),
                params.deadline
            );
    }

    /**
     * @dev     Combines Uniswap V2 Router "removeLiquidity" function with Primitive "closeOptions" function.
     * @notice  Pulls UNI-V2 liquidity shares with shortOption<>underlying token, and optionTokens from `getCaller()`.
     *          Then closes the longOptionTokens and withdraws underlyingTokens to the `getCaller()` address.
     *          Sends underlyingTokens from the burned UNI-V2 liquidity shares to the `getCaller()` address.
     *          UNI-V2 -> optionToken -> underlyingToken.
     * @param   optionAddress The address of the option that will be closed from burned UNI-V2 liquidity shares.
     * @param   liquidity The quantity of liquidity tokens to pull from `getCaller()` and burn.
     * @param   amountAMin The minimum quantity of shortOptionTokens to receive from removing liquidity.
     * @param   amountBMin The minimum quantity of underlyingTokens to receive from removing liquidity.
     * @return  Returns the sum of the removed underlying tokens.
     */
    function removeShortLiquidityThenCloseOptions(
        address optionAddress,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin
    )
        public
        override
        nonReentrant
        onlyRegistered(IOption(optionAddress))
        returns (uint256)
    {
        IOption optionToken = IOption(optionAddress);
        (IUniswapV2Pair pair, address underlying, address redeem) =
            getOptionPair(optionToken);
        // Gets amounts struct.
        RemoveAmounts memory params;
        params.liquidity = liquidity;
        params.amountAMin = amountAMin;
        params.amountBMin = amountBMin;
        // Pulls lp tokens from `getCaller()` and pushes them to the pair in preparation to invoke `burn()`.
        _transferFromCallerToReceiver(address(pair), liquidity, address(pair));
        // Calls `burn` on the `pair`, returning amounts to this contract.
        (, uint256 underlyingAmount) = _removeLiquidity(pair, redeem, underlying, params);
        uint256 underlyingProceeds = _closeOptions(optionToken); // Returns amount of underlying tokens released.
        // Return remaining tokens/ether.
        _withdrawETH(); // Unwraps Weth and sends ether to `getCaller()`.
        _transferToCaller(redeem); // Push any remaining redeemTokens from removing liquidity (dust).
        _transferToCaller(underlying); // Pushes underlying token to `getCaller()`.
        uint256 sum = underlyingProceeds.add(underlyingAmount); // Total underlyings sent to `getCaller()`.
        emit RemoveLiquidity(getCaller(), address(optionToken), sum);
        return sum;
    }

    /**
     * @notice  Pulls LP tokens, burns them, removes liquidity, pull option token, burns then, pushes all underlying tokens.
     * @dev     Uses permit to pull LP tokens.
     * @param   optionAddress The address of the option that will be closed from burned UNI-V2 liquidity shares.
     * @param   liquidity The quantity of liquidity tokens to pull from _msgSender() and burn.
     * @param   amountAMin The minimum quantity of shortOptionTokens to receive from removing liquidity.
     * @param   amountBMin The minimum quantity of underlyingTokens to receive from removing liquidity.
     * @param   deadline The timestamp to expire a pending transaction and `permit` call.
     * @return  Returns the sum of the removed underlying tokens.
     */
    function removeShortLiquidityThenCloseOptionsWithPermit(
        address optionAddress,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint256) {
        IOption optionToken = IOption(optionAddress);
        (IUniswapV2Pair pair, , ) = getOptionPair(optionToken);
        pair.permit(getCaller(), address(_primitiveRouter), liquidity, deadline, v, r, s);
        return
            removeShortLiquidityThenCloseOptions(
                address(optionToken),
                liquidity,
                amountAMin,
                amountBMin
            );
    }

    struct RemoveAmounts {
        uint256 liquidity;
        uint256 amountAMin;
        uint256 amountBMin;
    }

    /**
     * @notice  Calls `UniswapV2Pair.burn(address(this))` to burn LP tokens for pair tokens.
     * @param   pair The UniswapV2Pair contract to burn LP tokens of.
     * @param   tokenA The first token of the pair.
     * @param   tokenB The second token of the pair.
     * @param   params The amounts to specify the amount to remove and minAmounts to withdraw.
     * @return  Returns (amountTokenA, amountTokenB) which is (redeem, underlying) amounts.
     */
    function _removeLiquidity(
        IUniswapV2Pair pair,
        address tokenA,
        address tokenB,
        RemoveAmounts memory params
    ) internal returns (uint256, uint256) {
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        (address token0, ) = CoreLib.sortTokens(tokenA, tokenB);
        (uint256 amountA, uint256 amountB) =
            tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= params.amountAMin, "PrimitiveLiquidity: INSUFFICIENT_A");
        require(amountB >= params.amountBMin, "PrimitiveLiquidity: INSUFFICIENT_B");
        return (amountA, amountB);
    }

    // ===== View =====

    /**
     * @notice  Gets the UniswapV2Router02 contract address.
     */
    function getRouter() public view override returns (IUniswapV2Router02) {
        return _router;
    }

    /**
     * @notice  Gets the UniswapV2Factory contract address.
     */
    function getFactory() public view override returns (IUniswapV2Factory) {
        return _factory;
    }

    /**
     * @notice  Fetchs the Uniswap Pair for an option's redeemToken and underlyingToken params.
     * @param   option The option token to get the corresponding UniswapV2Pair market.
     * @return  The pair address, as well as the tokens of the pair.
     */
    function getOptionPair(IOption option)
        public
        view
        override
        returns (
            IUniswapV2Pair,
            address,
            address
        )
    {
        address redeem = option.redeemToken();
        address underlying = option.getUnderlyingTokenAddress();
        IUniswapV2Pair pair = IUniswapV2Pair(_factory.getPair(redeem, underlying));
        return (pair, underlying, redeem);
    }
}
