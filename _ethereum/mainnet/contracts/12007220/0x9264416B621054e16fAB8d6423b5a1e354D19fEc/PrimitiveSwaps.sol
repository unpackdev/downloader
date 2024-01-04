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
 * @title   Primitive Router
 * @author  Primitive
 * @notice  Swap option tokens on Uniswap & Sushiswap venues.
 * @dev     @primitivefi/v1-connectors@v2.0.0
 */

// Open Zeppelin
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
// Uniswap
import "./IUniswapV2Callee.sol";
// Primitive
import "./IPrimitiveSwaps.sol";
import "./PrimitiveConnector.sol";
import "./SwapsLib.sol";

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

contract PrimitiveSwaps is
    PrimitiveConnector,
    IPrimitiveSwaps,
    IUniswapV2Callee,
    ReentrancyGuard
{
    using SafeERC20 for IERC20; // Reverts when `transfer` or `transferFrom` erc20 calls don't return proper data
    using SafeMath for uint256; // Reverts on math underflows/overflows

    event Initialized(address indexed from); // Emitted on deployment.
    event Buy(
        address indexed from,
        address indexed option,
        uint256 quantity,
        uint256 premium
    );
    event Sell(
        address indexed from,
        address indexed option,
        uint256 quantity,
        uint256 payout
    );

    IUniswapV2Factory private _factory; // The Uniswap V2 _factory contract to get pair addresses from
    IUniswapV2Router02 private _router; // The Uniswap contract used to interact with the protocol

    modifier onlySelf() {
        require(_msgSender() == address(this), "PrimitiveSwaps: NOT_SELF");
        _;
    }

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

    // ===== Swap Operations =====

    /**
     * @notice  IMPORTANT: amountOutMin parameter is the price to swap shortOptionTokens to underlyingTokens.
     *          IMPORTANT: If the ratio between shortOptionTokens and underlyingTokens is 1:1, then only the swap fee (0.30%) has to be paid.
     * @dev     Opens a longOptionToken position by minting long + short tokens, then selling the short tokens.
     * @param   optionToken The option address.
     * @param   amountOptions The quantity of longOptionTokens to purchase.
     * @param   maxPremium The maximum quantity of underlyingTokens to pay for the optionTokens.
     * @return  Whether or not the call succeeded.
     */
    function openFlashLong(
        IOption optionToken,
        uint256 amountOptions,
        uint256 maxPremium
    ) public override nonReentrant onlyRegistered(optionToken) returns (bool) {
        // Calls pair.swap(), and executes `flashMintShortOptionsThenSwap` in the `uniswapV2Callee` callback.
        (IUniswapV2Pair pair, address underlying, ) = getOptionPair(optionToken);
        SwapsLib._flashSwap(
            pair, // Pair to flash swap from.
            underlying, // Token to swap to, i.e. receive optimistically.
            amountOptions, // Amount of underlying to optimistically receive to mint options with.
            abi.encodeWithSelector( // Start: Function to call in the callback.
                bytes4(
                    keccak256(
                        bytes("flashMintShortOptionsThenSwap(address,uint256,uint256)")
                    )
                ),
                optionToken, // Option token to mint with flash loaned tokens.
                amountOptions, // Quantity of underlyingTokens from flash loan to use to mint options.
                maxPremium // Total price paid (in underlyingTokens) for selling shortOptionTokens.
            ) // End: Function to call in the callback.
        );
        return true;
    }

    /**
     * @notice  Executes the same as `openFlashLong`, but calls `permit` to pull underlying tokens.
     */
    function openFlashLongWithPermit(
        IOption optionToken,
        uint256 amountOptions,
        uint256 maxPremium,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override nonReentrant onlyRegistered(optionToken) returns (bool) {
        // Calls pair.swap(), and executes `flashMintShortOptionsThenSwap` in the `uniswapV2Callee` callback.
        (IUniswapV2Pair pair, address underlying, ) = getOptionPair(optionToken);
        IERC20Permit(underlying).permit(
            getCaller(),
            address(_primitiveRouter),
            maxPremium,
            deadline,
            v,
            r,
            s
        );
        SwapsLib._flashSwap(
            pair, // Pair to flash swap from.
            underlying, // Token to swap to, i.e. receive optimistically.
            amountOptions, // Amount of underlying to optimistically receive to mint options with.
            abi.encodeWithSelector( // Start: Function to call in the callback.
                bytes4(
                    keccak256(
                        bytes("flashMintShortOptionsThenSwap(address,uint256,uint256)")
                    )
                ),
                optionToken, // Option token to mint with flash loaned tokens.
                amountOptions, // Quantity of underlyingTokens from flash loan to use to mint options.
                maxPremium // Total price paid (in underlyingTokens) for selling shortOptionTokens.
            ) // End: Function to call in the callback.
        );
        return true;
    }

    /**
     * @notice  Executes the same as `openFlashLongWithPermit`, but for DAI.
     */
    function openFlashLongWithDAIPermit(
        IOption optionToken,
        uint256 amountOptions,
        uint256 maxPremium,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override nonReentrant onlyRegistered(optionToken) returns (bool) {
        // Calls pair.swap(), and executes `flashMintShortOptionsThenSwap` in the `uniswapV2Callee` callback.
        (IUniswapV2Pair pair, address underlying, ) = getOptionPair(optionToken);
        DaiPermit(underlying).permit(
            getCaller(),
            address(_primitiveRouter),
            IERC20Permit(underlying).nonces(getCaller()),
            deadline,
            true,
            v,
            r,
            s
        );
        SwapsLib._flashSwap(
            pair, // Pair to flash swap from.
            underlying, // Token to swap to, i.e. receive optimistically.
            amountOptions, // Amount of underlying to optimistically receive to mint options with.
            abi.encodeWithSelector( // Start: Function to call in the callback.
                bytes4(
                    keccak256(
                        bytes("flashMintShortOptionsThenSwap(address,uint256,uint256)")
                    )
                ),
                optionToken, // Option token to mint with flash loaned tokens.
                amountOptions, // Quantity of underlyingTokens from flash loan to use to mint options.
                maxPremium // Total price paid (in underlyingTokens) for selling shortOptionTokens.
            ) // End: Function to call in the callback.
        );
        return true;
    }

    /**
     * @notice  Uses Ether to pay to purchase the option tokens.
     *          IMPORTANT: amountOutMin parameter is the price to swap shortOptionTokens to underlyingTokens.
     *          IMPORTANT: If the ratio between shortOptionTokens and underlyingTokens is 1:1, then only the swap fee (0.30%) has to be paid.
     * @dev     Opens a longOptionToken position by minting long + short tokens, then selling the short tokens.
     * @param   optionToken The option address.
     * @param   amountOptions The quantity of longOptionTokens to purchase.
     */
    function openFlashLongWithETH(IOption optionToken, uint256 amountOptions)
        external
        payable
        override
        nonReentrant
        onlyRegistered(optionToken)
        returns (bool)
    {
        require(msg.value > 0, "PrimitiveSwaps: ZERO"); // Fail early if no Ether was sent.
        // Calls pair.swap(), and executes `flashMintShortOptionsThenSwap` in the `uniswapV2Callee` callback.
        (IUniswapV2Pair pair, address underlying, ) = getOptionPair(optionToken);
        SwapsLib._flashSwap(
            pair, // Pair to flash swap from.
            underlying, // Token to swap to, i.e. receive optimistically.
            amountOptions, // Amount of underlying to optimistically receive to mint options with.
            abi.encodeWithSelector( // Start: Function to call in the callback.
                bytes4(
                    keccak256(
                        bytes(
                            "flashMintShortOptionsThenSwapWithETH(address,uint256,uint256)"
                        )
                    )
                ),
                optionToken, // Option token to mint with flash loaned tokens
                amountOptions, // Quantity of underlyingTokens from flash loan to use to mint options.
                msg.value // total price paid (in underlyingTokens) for selling shortOptionTokens.
            ) // End: Function to call in the callback.
        );
        return true;
    }

    /**
     * @dev     Closes a longOptionToken position by flash swapping in redeemTokens,
     *          closing the option, and paying back in underlyingTokens.
     * @notice  IMPORTANT: If minPayout is 0, this function will cost the caller to close the option, for no gain.
     * @param   optionToken The address of the longOptionTokens to close.
     * @param   amountRedeems The quantity of redeemTokens to borrow to close the options.
     * @param   minPayout The minimum payout of underlyingTokens sent out to the user.
     */
    function closeFlashLong(
        IOption optionToken,
        uint256 amountRedeems,
        uint256 minPayout
    ) external override nonReentrant onlyRegistered(optionToken) returns (bool) {
        // Calls pair.swap(), and executes `flashCloseLongOptionsThenSwap` in the `uniswapV2Callee` callback.
        (IUniswapV2Pair pair, , address redeem) = getOptionPair(optionToken);
        SwapsLib._flashSwap(
            pair, // Pair to flash swap from.
            redeem, // Token to swap to, i.e. receive optimistically.
            amountRedeems, // Amount of underlying to optimistically receive to close options with.
            abi.encodeWithSelector( // Start: Function to call in the callback.
                bytes4(
                    keccak256(
                        bytes("flashCloseLongOptionsThenSwap(address,uint256,uint256)")
                    )
                ),
                optionToken, // Option token to close with flash loaned redeemTokens.
                amountRedeems, // Quantity of redeemTokens from flash loan to use to close options.
                minPayout // Total remaining underlyingTokens after flash loan is paid.
            ) // End: Function to call in the callback.
        );
        return true;
    }

    /**
     * @dev     Closes a longOptionToken position by flash swapping in redeemTokens,
     *          closing the option, and paying back in underlyingTokens.
     * @notice  IMPORTANT: If minPayout is 0, this function will cost the caller to close the option, for no gain.
     * @param   optionToken The address of the longOptionTokens to close.
     * @param   amountRedeems The quantity of redeemTokens to borrow to close the options.
     * @param   minPayout The minimum payout of underlyingTokens sent out to the user.
     */
    function closeFlashLongForETH(
        IOption optionToken,
        uint256 amountRedeems,
        uint256 minPayout
    ) external override nonReentrant onlyRegistered(optionToken) returns (bool) {
        // Calls pair.swap(), and executes `flashCloseLongOptionsThenSwapForETH` in the `uniswapV2Callee` callback.
        (IUniswapV2Pair pair, , address redeem) = getOptionPair(optionToken);
        SwapsLib._flashSwap(
            pair, // Pair to flash swap from.
            redeem, // Token to swap to, i.e. receive optimistically.
            amountRedeems, // Amount of underlying to optimistically receive to close options with.
            abi.encodeWithSelector( // Start: Function to call in the callback.
                bytes4(
                    keccak256(
                        bytes(
                            "flashCloseLongOptionsThenSwapForETH(address,uint256,uint256)"
                        )
                    )
                ),
                optionToken, // Option token to close with flash loaned redeemTokens.
                amountRedeems, // Quantity of redeemTokens from flash loan to use to close options.
                minPayout // Total remaining underlyingTokens after flash loan is paid.
            ) // End: Function to call in the callback.
        );
        return true;
    }

    // ===== Flash Callback Functions =====

    /**
     * @notice  Callback function executed in a UniswapV2Pair.swap() call for `openFlashLong`.
     * @dev     Pays underlying token `premium` for `quantity` of `optionAddress` tokens.
     * @param   optionAddress The address of the Option contract.
     * @param   quantity The quantity of options to mint using borrowed underlyingTokens.
     * @param   maxPremium The maximum quantity of underlyingTokens to pay for the optionTokens.
     * @return  Returns (amount, premium) of options purchased for total premium price.
     */
    function flashMintShortOptionsThenSwap(
        address optionAddress,
        uint256 quantity,
        uint256 maxPremium
    ) public onlySelf onlyRegistered(IOption(optionAddress)) returns (uint256, uint256) {
        IOption optionToken = IOption(optionAddress);
        (IUniswapV2Pair pair, address underlying, address redeem) =
            getOptionPair(optionToken);
        // Mint option and redeem tokens to this contract.
        _mintOptions(optionToken);
        // Get the repayment amounts.
        (uint256 premium, uint256 redeemPremium) =
            SwapsLib.repayOpen(_router, optionToken, quantity);
        // If premium is non-zero and non-negative (most cases), send underlyingTokens to the pair as payment (premium).
        if (premium > 0) {
            // Check for users to not pay over their max desired value.
            require(maxPremium >= premium, "PrimitiveSwaps: MAX_PREMIUM");
            // Pull underlyingTokens from the `getCaller()` to pay the remainder of the flash swap.
            // Push underlying tokens back to the pair as repayment.
            _transferFromCallerToReceiver(underlying, premium, address(pair));
        }
        // Pay pair in redeem tokens.
        if (redeemPremium > 0) {
            IERC20(redeem).safeTransfer(address(pair), redeemPremium);
        }
        // Return tokens to `getCaller()`.
        _transferToCaller(redeem);
        _transferToCaller(optionAddress);
        emit Buy(getCaller(), optionAddress, quantity, premium);
        return (quantity, premium);
    }

    /**
     * @notice  Callback function executed in a UniswapV2Pair.swap() call for `openFlashLongWithETH`.
     * @dev     Pays `premium` in ether for `quantity` of `optionAddress` tokens.
     * @param   optionAddress The address of the Option contract.
     * @param   quantity The quantity of options to mint using borrowed underlyingTokens.
     * @param   maxPremium The maximum quantity of underlyingTokens to pay for the optionTokens.
     * @return  Returns (amount, premium) of options purchased for total premium price.
     */
    function flashMintShortOptionsThenSwapWithETH(
        address optionAddress,
        uint256 quantity,
        uint256 maxPremium
    ) public onlySelf onlyRegistered(IOption(optionAddress)) returns (uint256, uint256) {
        IOption optionToken = IOption(optionAddress);
        (IUniswapV2Pair pair, address underlying, address redeem) =
            getOptionPair(optionToken);
        require(underlying == address(_weth), "PrimitiveSwaps: NOT_WETH"); // Ensure Weth Call.
        // Mint option and redeem tokens to this contract.
        _mintOptions(optionToken);
        // Get the repayment amounts.
        (uint256 premium, uint256 redeemPremium) =
            SwapsLib.repayOpen(_router, optionToken, quantity);
        // If premium is non-zero and non-negative (most cases), send underlyingTokens to the pair as payment (premium).
        if (premium > 0) {
            // Check for users to not pay over their max desired value.
            require(maxPremium >= premium, "PrimitiveSwaps: MAX_PREMIUM");
            // Wrap exact Ether amount of `premium`.
            _weth.deposit.value(premium)();
            // Transfer Weth to pair to pay for premium.
            IERC20(address(_weth)).safeTransfer(address(pair), premium);
            // Return remaining Ether to caller.
            _withdrawETH();
        }
        // Pay pair in redeem.
        if (redeemPremium > 0) {
            IERC20(redeem).safeTransfer(address(pair), redeemPremium);
        }
        // Return tokens to `getCaller()`.
        _transferToCaller(redeem);
        _transferToCaller(optionAddress);
        emit Buy(getCaller(), optionAddress, quantity, premium);
        return (quantity, premium);
    }

    /**
     * @dev     Sends shortOptionTokens to _msgSender(), and pays back the UniswapV2Pair in underlyingTokens.
     * @notice  IMPORTANT: If minPayout is 0, the `to` address is liable for negative payouts *if* that occurs.
     * @param   optionAddress The address of the longOptionTokes to close.
     * @param   flashLoanQuantity The quantity of shortOptionTokens borrowed to use to close longOptionTokens.
     * @param   minPayout The minimum payout of underlyingTokens sent to the `to` address.
     */
    function flashCloseLongOptionsThenSwap(
        address optionAddress,
        uint256 flashLoanQuantity,
        uint256 minPayout
    ) public onlySelf onlyRegistered(IOption(optionAddress)) returns (uint256, uint256) {
        IOption optionToken = IOption(optionAddress);
        (IUniswapV2Pair pair, address underlying, address redeem) =
            getOptionPair(optionToken);
        // Close the options, releasing underlying tokens to this contract.
        uint256 outputUnderlyings = _closeOptions(optionToken);
        // Get repay amounts.
        (uint256 payout, uint256 cost, uint256 outstanding) =
            SwapsLib.repayClose(_router, optionToken, flashLoanQuantity);
        if (payout > 0) {
            cost = outputUnderlyings.sub(payout);
        }
        // Pay back the pair in underlyingTokens.
        if (cost > 0) {
            IERC20(underlying).safeTransfer(address(pair), cost);
        }
        if (outstanding > 0) {
            // Pull underlyingTokens from the `getCaller()` to pay the remainder of the flash swap.
            // Revert if the minPayout is less than or equal to the underlyingPayment of 0.
            // There is 0 underlyingPayment in the case that outstanding > 0.
            // This code branch can be successful by setting `minPayout` to 0.
            // This means the user is willing to pay to close the position.
            require(minPayout <= payout, "PrimitiveSwaps: NEGATIVE_PAYOUT");
            _transferFromCallerToReceiver(underlying, outstanding, address(pair));
        }
        // If payout is non-zero and non-negative, send it to the `getCaller()` address.
        if (payout > 0) {
            // Revert if minPayout is greater than the actual payout.
            require(payout >= minPayout, "PrimitiveSwaps: MIN_PREMIUM");
            _transferToCaller(underlying);
        }
        emit Sell(getCaller(), optionAddress, flashLoanQuantity, payout);
        return (payout, cost);
    }

    /**
     * @dev     Sends shortOptionTokens to _msgSender(), and pays back the UniswapV2Pair in underlyingTokens.
     * @notice  IMPORTANT: If minPayout is 0, the `getCaller()` address is liable for negative payouts *if* that occurs.
     * @param   optionAddress The address of the longOptionTokes to close.
     * @param   flashLoanQuantity The quantity of shortOptionTokens borrowed to use to close longOptionTokens.
     * @param   minPayout The minimum payout of underlyingTokens sent to the `to` address.
     */
    function flashCloseLongOptionsThenSwapForETH(
        address optionAddress,
        uint256 flashLoanQuantity,
        uint256 minPayout
    ) public onlySelf onlyRegistered(IOption(optionAddress)) returns (uint256, uint256) {
        IOption optionToken = IOption(optionAddress);
        (IUniswapV2Pair pair, address underlying, address redeem) =
            getOptionPair(optionToken);
        require(underlying == address(_weth), "PrimitiveSwaps: NOT_WETH");
        // Close the options, releasing underlying tokens to this contract.
        _closeOptions(optionToken);
        // Get repay amounts.
        (uint256 payout, uint256 cost, uint256 outstanding) =
            SwapsLib.repayClose(_router, optionToken, flashLoanQuantity);
        // Pay back the pair in underlyingTokens.
        if (cost > 0) {
            IERC20(underlying).safeTransfer(address(pair), cost);
        }
        if (outstanding > 0) {
            // Pull underlyingTokens from the `getCaller()` to pay the remainder of the flash swap.
            // Revert if the minPayout is less than or equal to the underlyingPayment of 0.
            // There is 0 underlyingPayment in the case that outstanding > 0.
            // This code branch can be successful by setting `minPayout` to 0.
            // This means the user is willing to pay to close the position.
            require(minPayout <= payout, "PrimitiveSwaps: NEGATIVE_PAYOUT");
            _transferFromCallerToReceiver(underlying, outstanding, address(pair));
        }
        // If payout is non-zero and non-negative, send it to the `getCaller()` address.
        if (payout > 0) {
            // Revert if minPayout is greater than the actual payout.
            require(payout >= minPayout, "PrimitiveSwaps: MIN_PREMIUM");
            _withdrawETH(); // Unwrap's this contract's balance of Weth and sends Ether to `getCaller()`.
        }
        emit Sell(getCaller(), optionAddress, flashLoanQuantity, payout);
        return (payout, cost);
    }

    // ===== Flash Loans =====

    /**
     * @dev     The callback function triggered in a UniswapV2Pair.swap() call when the `data` parameter has data.
     * @param   sender The original _msgSender() of the UniswapV2Pair.swap() call.
     * @param   amount0 The quantity of token0 received to the `to` address in the swap() call.
     * @param   amount1 The quantity of token1 received to the `to` address in the swap() call.
     * @param   data The payload passed in the `data` parameter of the swap() call.
     */
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override(IPrimitiveSwaps, IUniswapV2Callee) {
        assert(
            _msgSender() ==
                _factory.getPair(
                    IUniswapV2Pair(_msgSender()).token0(),
                    IUniswapV2Pair(_msgSender()).token1()
                )
        ); // Ensure that _msgSender() is actually a V2 pair.
        require(sender == address(this), "PrimitiveSwaps: NOT_SENDER"); // Ensure called by this contract.
        (bool success, bytes memory returnData) = address(this).call(data); // Execute the callback.
        (uint256 amountA, uint256 amountB) = abi.decode(returnData, (uint256, uint256));
        require(
            success && (returnData.length == 0 || amountA > 0 || amountB > 0),
            "PrimitiveSwaps: CALLBACK"
        );
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

    /**
     * @dev     Calculates the effective premium, denominated in underlyingTokens, to buy `quantity` of `optionToken`s.
     * @notice  UniswapV2 adds a 0.3009027% fee which is applied to the premium as 0.301%.
     *          IMPORTANT: If the pair's reserve ratio is incorrect, there could be a 'negative' premium.
     *          Buying negative premium options will pay out redeemTokens.
     *          An 'incorrect' ratio occurs when the (reserves of redeemTokens / strike ratio) >= reserves of underlyingTokens.
     *          Implicitly uses the `optionToken`'s underlying and redeem tokens for the pair.
     * @param   optionToken The optionToken to get the premium cost of purchasing.
     * @param   quantity The quantity of long option tokens that will be purchased.
     * @return  (uint, uint) Returns the `premium` to buy `quantity` of `optionToken` and the `negativePremium`.
     */
    function getOpenPremium(IOption optionToken, uint256 quantity)
        public
        view
        override
        returns (uint256, uint256)
    {
        return SwapsLib.getOpenPremium(_router, optionToken, quantity);
    }

    /**
     * @dev     Calculates the effective premium, denominated in underlyingTokens, to sell `optionToken`s.
     * @param   optionToken The optionToken to get the premium cost of purchasing.
     * @param   quantity The quantity of short option tokens that will be closed.
     * @return  (uint, uint) Returns the `premium` to sell `quantity` of `optionToken` and the `negativePremium`.
     */
    function getClosePremium(IOption optionToken, uint256 quantity)
        public
        view
        override
        returns (uint256, uint256)
    {
        return SwapsLib.getClosePremium(_router, optionToken, quantity);
    }
}
