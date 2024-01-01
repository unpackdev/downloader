// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./Address.sol";
import "./SafeCast.sol";

import "./ErrorCodes.sol";
import "./IFlasher.sol";
import "./IPoolAddressesProvider.sol";
import "./IPool.sol";

contract Flasher is IFlasher, AccessControl {
    using SafeERC20 for IERC20;

    /// @dev Value is the Keccak-256 hash of "GATEKEEPER"
    bytes32 public constant GATEKEEPER = bytes32(0x20162831d2f54c3e11eebafebfeda495d4c52c67b1708251179ec91fb76dd3b2);

    IPoolAddressesProvider public aavePoolAddressesProvider;
    IV3SwapRouter public swapRouter;
    ILiquidation public liquidation;
    IPriceOracle public oracle;

    address public defaultSurplusAsset;
    address public treasuryAddress;

    /// @notice Whitelist for assets that can be used as surplus
    mapping(IERC20 => bool) public allowedSurplusAssets;

    /// @notice Whitelist for users who can be a withdrawal recipients
    mapping(address => bool) public allowedWithdrawReceivers;

    /// @dev The maximum deviation from the expected amountOut for a swap.
    uint256 public tokenOutDeviation = 99e16;

    uint256 private constant EXP_SCALE = 1e18;
    uint256 private constant SWAP_FEE_MULTIPLIER = 1e12;

    constructor(
        address _admin,
        address _aavePoolAddressesProvider,
        address _swapRouter,
        address _liquidation,
        address _oracle,
        address _defaultSurplusAsset,
        address _treasuryAddress
    ) {
        validateZeroAddress(_admin);
        validateZeroAddress(_swapRouter);
        validateZeroAddress(_liquidation);
        validateZeroAddress(_oracle);
        validateZeroAddress(_defaultSurplusAsset);
        validateZeroAddress(_treasuryAddress);

        aavePoolAddressesProvider = IPoolAddressesProvider(_aavePoolAddressesProvider);
        swapRouter = IV3SwapRouter(_swapRouter);
        liquidation = ILiquidation(_liquidation);
        oracle = IPriceOracle(_oracle);
        defaultSurplusAsset = _defaultSurplusAsset;
        treasuryAddress = _treasuryAddress;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(GATEKEEPER, _admin);
    }

    /************************************************************************/
    /*                   GATEKEEPER FUNCTIONS                               */
    /************************************************************************/

    /// @inheritdoc IFlasher
    function flashLiquidation(
        IMToken seizeMarket,
        IMToken repayMarket,
        address borrower,
        uint256 repayAmount,
        bytes calldata mainSwapData,
        bytes calldata surplusSwapData
    ) external onlyRole(GATEKEEPER) {
        bytes memory callbackData = abi.encode(
            AaveFlashCallbackData({
                seizeMarket: seizeMarket,
                repayMarket: repayMarket,
                borrower: borrower,
                repayAmount: repayAmount,
                mainSwapData: mainSwapData,
                surplusSwapData: surplusSwapData
            })
        );
        address repayAsset = address(repayMarket.underlying());

        getFreshPool().flashLoanSimple(
            address(this), // receiverAddress
            repayAsset, // asset
            repayAmount, // amount
            callbackData, // params
            0 // referralCode
        );
    }

    /// @inheritdoc IFlasher
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        IPool aavePoolProxy = getFreshPool();
        require(msg.sender == address(aavePoolProxy), ErrorCodes.FL_UNAUTHORIZED_CALLBACK);
        require(initiator == address(this), ErrorCodes.FL_UNAUTHORIZED_CALLBACK);

        uint256 flashBorrowWithFee = amount + premium;

        // Perform liquidation, swaps if required and transfer surplus to treasury
        liquidateAndSwap(flashBorrowWithFee, params);

        // Repay flash borrow amount plus fee
        IERC20(asset).approve(address(aavePoolProxy), flashBorrowWithFee);

        return true;
    }

    /************************************************************************/
    /*                        ADMIN FUNCTIONS                               */
    /************************************************************************/

    /* --- LOGIC --- */

    /// @inheritdoc IFlasher
    function withdraw(
        uint256 amount,
        IERC20 underlying,
        address to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) allowedReceiversOnly(to) {
        require(underlying.balanceOf(address(this)) >= amount, ErrorCodes.INSUFFICIENT_LIQUIDITY);

        emit Withdraw(address(underlying), to, amount);
        underlying.safeTransfer(to, amount);
    }

    /* --- SETTERS --- */

    /// @inheritdoc IFlasher
    function setTokenOutDeviation(uint256 newValue_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newValue_ > 0, ErrorCodes.FL_INCORRECT_TOKEN_OUT_DEVIATION);
        uint256 oldValue = tokenOutDeviation;
        tokenOutDeviation = newValue_;
        emit TokenOutDeviationChanged(oldValue, newValue_);
    }

    /// @inheritdoc IFlasher
    function setRouterAddress(IV3SwapRouter newSwapRouter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        validateZeroAddress(address(newSwapRouter));
        swapRouter = newSwapRouter;
        emit NewSwapRouter(newSwapRouter);
    }

    /// @inheritdoc IFlasher
    function setLiquidationAddress(ILiquidation newLiquidationContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        validateZeroAddress(address(newLiquidationContract));
        liquidation = newLiquidationContract;
        emit NewLiquidation(newLiquidationContract);
    }

    /// @inheritdoc IFlasher
    function setPoolAddressesProvider(IPoolAddressesProvider newAddressesProviderContract)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        validateZeroAddress(address(newAddressesProviderContract));
        aavePoolAddressesProvider = newAddressesProviderContract;
        emit NewPoolAddressesProvider(newAddressesProviderContract);
    }

    /// @inheritdoc IFlasher
    function setOracleAddress(IPriceOracle newOracleContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        validateZeroAddress(address(newOracleContract));
        oracle = newOracleContract;
        emit NewOracle(newOracleContract);
    }

    /// @inheritdoc IFlasher
    function setTreasuryAddress(address newTreasuryAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        validateZeroAddress(newTreasuryAddress);
        // slither-disable-next-line missing-zero-check
        treasuryAddress = newTreasuryAddress;
        emit NewTreasury(newTreasuryAddress);
    }

    /// @inheritdoc IFlasher
    function setDefaultSurplusAsset(address newDefaultSurplusAsset) external onlyRole(DEFAULT_ADMIN_ROLE) {
        validateZeroAddress(newDefaultSurplusAsset);
        // slither-disable-next-line missing-zero-check
        defaultSurplusAsset = newDefaultSurplusAsset;
        emit NewDefaultSurplusAsset(newDefaultSurplusAsset);
    }

    /// @inheritdoc IFlasher
    function addAllowedReceiver(address receiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        validateZeroAddress(receiver);
        allowedWithdrawReceivers[receiver] = true;
        emit NewAllowedWithdrawReceiver(receiver);
    }

    /// @inheritdoc IFlasher
    function addAllowedSurplusAsset(IERC20 newSurplusAsset) external onlyRole(DEFAULT_ADMIN_ROLE) {
        validateZeroAddress(address(newSurplusAsset));
        allowedSurplusAssets[newSurplusAsset] = true;
        emit NewAllowedSurplusAsset(newSurplusAsset);
    }

    /// @inheritdoc IFlasher
    function addAllowedGatekeeper(address newGatekeeper) external onlyRole(DEFAULT_ADMIN_ROLE) {
        validateZeroAddress(newGatekeeper);
        _grantRole(GATEKEEPER, newGatekeeper);
        emit NewAllowedGatekeeper(newGatekeeper);
    }

    /* --- REMOVERS --- */

    /// @inheritdoc IFlasher
    function removeAllowedSurplusAsset(IERC20 surplusAsset) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete allowedSurplusAssets[surplusAsset];
        emit AllowedSurplusAssetRemoved(surplusAsset);
    }

    /// @inheritdoc IFlasher
    function removeAllowedReceiver(address receiver)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        allowedReceiversOnly(receiver)
    {
        delete allowedWithdrawReceivers[receiver];
        emit AllowedWithdrawReceiverRemoved(receiver);
    }

    /// @inheritdoc IFlasher
    function removeAllowedGatekeeper(address gatekeeper) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(GATEKEEPER, gatekeeper);
        emit AllowedGatekeeperRemoved(gatekeeper);
    }

    /************************************************************************/
    /*                          INTERNAL FUNCTIONS                          */
    /************************************************************************/

    /**
     * @notice Executes unsafe loan liquidation, handles additional swap operations based on `swapData` and transfers
               surplus asset to the treasury
     * @param flashBorrowWithFee Amount of flash loan with fee
     * @param callbackParams The encoded data that contains all info for liquidation and swaps
     */
    function liquidateAndSwap(uint256 flashBorrowWithFee, bytes calldata callbackParams) internal {
        AaveFlashCallbackData memory flashCallbackData = abi.decode(callbackParams, (AaveFlashCallbackData));

        IERC20 seizeAsset = flashCallbackData.seizeMarket.underlying();
        IERC20 repayAsset = flashCallbackData.repayMarket.underlying();

        // Initially surplusAsset == seizeAsset.
        // If seizeAsset is not allowed surplus asset, the default surplus asset will be set.
        IERC20 surplusAsset = seizeAsset;
        uint256 surplusAmount = 0;

        // Perform liquidation in Minterest protocol and collect seize underlying amount
        uint256 remainingSeizeAmount = performLiquidation(
            flashCallbackData.seizeMarket,
            flashCallbackData.repayMarket,
            flashCallbackData.borrower,
            flashCallbackData.repayAmount
        );

        // Check if we need to swap seized asset to repay flash loan
        if (seizeAsset != repayAsset) {
            (bytes memory multicallData, uint256 maxAmountIn) = abi.decode(
                flashCallbackData.mainSwapData,
                (bytes, uint256)
            );

            (uint256 seizeTokenSpent, ) = multicallSwap(
                seizeAsset,
                repayAsset,
                maxAmountIn,
                flashBorrowWithFee,
                false,
                multicallData
            );

            // After ExactOut swap we update remaining seize amount
            remainingSeizeAmount -= seizeTokenSpent;
        } else {
            // In case seizeAsset == repayAsset, we don't need to swap seizeAsset to repayAsset,
            // we already can repay flash loan.
            // Substitute flash loan amount plus fee from remaining seize amount to manage further surplus swap.
            remainingSeizeAmount -= flashBorrowWithFee;
        }

        if (remainingSeizeAmount > 0) {
            // In case seize asset is not one of the allowed surplus asset, we need to swap it to default one.
            if (isSurplusSwapRequired(seizeAsset)) {
                surplusAsset = IERC20(defaultSurplusAsset);
                (, uint256 surplusAmountReceived) = exactInSingleSwap(
                    seizeAsset,
                    surplusAsset,
                    remainingSeizeAmount,
                    flashCallbackData.surplusSwapData
                );

                surplusAmount = surplusAmountReceived;
            } else {
                // In case seizeAsset is already allowed surplus asset:
                // surplusAsset = seizeAsset
                // surplusAmount = remainingSeizeAmount
                surplusAmount = remainingSeizeAmount;
            }
            // Transfer surplus to the treasury
            transferSurplus(surplusAsset, surplusAmount);
        }
    }

    /**
     * @notice Executes unsafe loan liquidation
     * @param seizeMarket Market from which the account's collateral will be seized
     * @param repayMarket Market from which the account's debt will be repaid
     * @param borrower The address of the borrower with the unsafe loan.
     * @param repayAmount Amount of debt to be repaid
     * @return actualSeizeAmount Actual seize underlying amount
     */
    function performLiquidation(
        IMToken seizeMarket,
        IMToken repayMarket,
        address borrower,
        uint256 repayAmount
    ) internal returns (uint256 actualSeizeAmount) {
        IERC20 repayAsset = repayMarket.underlying();
        repayAsset.safeApprove(address(repayMarket), repayAmount);

        (actualSeizeAmount, ) = liquidation.liquidateUnsafeLoan(seizeMarket, repayMarket, borrower, repayAmount);
    }

    /**
     * @notice Performs multicall swap on Uniswap V3 router and validates result
     * @param tokenIn Input token
     * @param tokenOut Output token
     * @param tokenInAmount Amount of input token
     * @param tokenOutAmount Amount of output token
     * @param isSwapTypeExactIn Marker of trade type
     * @return amountInDelta TokenIn delta after swap
     * @return amountOutDelta TokenOut delta after swap
     */
    function multicallSwap(
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 tokenInAmount,
        uint256 tokenOutAmount,
        bool isSwapTypeExactIn,
        bytes memory swapData
    ) internal returns (uint256 amountInDelta, uint256 amountOutDelta) {
        uint256 amountInBefore = tokenIn.balanceOf(address(this));
        uint256 amountOutBefore = tokenOut.balanceOf(address(this));

        tokenIn.safeApprove(address(swapRouter), tokenInAmount);
        Address.functionCall(address(swapRouter), swapData, ErrorCodes.FL_SWAP_CALL_FAILS);

        amountInDelta = amountInBefore - tokenIn.balanceOf(address(this));
        amountOutDelta = tokenOut.balanceOf(address(this)) - amountOutBefore;

        validateAmountsAndNullifyAllowance(
            isSwapTypeExactIn,
            amountInDelta,
            amountOutDelta,
            tokenIn,
            tokenInAmount,
            tokenOutAmount
        );

        emit MulticallSwap(tokenIn, tokenOut, amountInDelta, amountOutDelta);
    }

    /**
     * @notice Performs exactInSingle swap on Uniswap V3 router and validates result
     * @param tokenIn Input token
     * @param tokenOut Output token
     * @param tokenInAmount Amount of input token
     * @param swapData The encoded poolFee and slippage rates scaled by 1e18
     * @return amountInDelta TokenIn delta after swap
     * @return amountOutDelta TokenOut delta after swap
     */
    function exactInSingleSwap(
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 tokenInAmount,
        bytes memory swapData
    ) internal returns (uint256 amountInDelta, uint256 amountOutDelta) {
        SurplusSwapData memory decodedSwapData = abi.decode(swapData, (SurplusSwapData));

        uint256 amountOutMinimum = calculateAmountOutMinimum(
            tokenIn,
            tokenOut,
            tokenInAmount,
            decodedSwapData.slippage,
            decodedSwapData.poolFeeTick
        );

        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
            tokenIn: address(tokenIn),
            tokenOut: address(tokenOut),
            fee: SafeCast.toUint24(decodedSwapData.poolFeeTick / SWAP_FEE_MULTIPLIER), // convert fee to uniswap format
            recipient: address(this),
            amountIn: tokenInAmount,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: 0
        });

        uint256 amountInBefore = tokenIn.balanceOf(address(this));
        uint256 amountOutBefore = tokenOut.balanceOf(address(this));

        tokenIn.safeApprove(address(swapRouter), tokenInAmount);
        swapRouter.exactInputSingle(params);

        amountInDelta = amountInBefore - tokenIn.balanceOf(address(this));
        amountOutDelta = tokenOut.balanceOf(address(this)) - amountOutBefore;

        validateAmountsAndNullifyAllowance(
            true,
            amountInDelta,
            amountOutDelta,
            tokenIn,
            tokenInAmount,
            amountOutMinimum
        );

        emit ExactInputSingleSwap(
            tokenIn,
            tokenOut,
            amountInDelta,
            amountOutDelta,
            decodedSwapData.poolFeeTick,
            decodedSwapData.slippage
        );
    }

    /**
     * @notice Transfers surplus to the treasury
     * @param surplusAsset Token that was used as surplus during liquidation process
     * @param transferAmount Amount of surplus token to transfer
     */
    function transferSurplus(IERC20 surplusAsset, uint256 transferAmount) internal {
        address treasuryAddress_ = treasuryAddress;

        emit SurplusTransfer(surplusAsset, treasuryAddress_, transferAmount);
        surplusAsset.safeTransfer(treasuryAddress_, transferAmount);
    }

    /**
     * @notice Check if required to swap surplus asset to the default one
     * @param surplusAsset Token that was used as surplus during liquidation process
     * @return True if surplus asset is not in the allowedSurplusAssets list, False otherwise
     */
    function isSurplusSwapRequired(IERC20 surplusAsset) internal view returns (bool) {
        return !allowedSurplusAssets[surplusAsset];
    }

    /**
     * @notice Calculates minimal amount of tokenOut considering slippage and poolFee rates.
               The calculation is based on fresh prices from the oracle
     * @param tokenIn Input token
     * @param tokenOut Output token
     * @param amountIn Amount of input token
     * @param slippageRate Slippage rate scaled by 1e18
     * @param poolFee Pool fee rate scaled by 1e18
     * @return tokenOutMinimum Minimal allowed amount of output token
     */
    function calculateAmountOutMinimum(
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 amountIn,
        uint256 slippageRate,
        uint256 poolFee
    ) internal view returns (uint256 tokenOutMinimum) {
        uint256 tokenInPrice = oracle.getAssetPrice(address(tokenIn));
        uint256 tokenOutPrice = oracle.getAssetPrice(address(tokenOut));
        require(tokenInPrice > 0 && tokenOutPrice > 0, ErrorCodes.INVALID_PRICE);

        uint256 tokenInAmountUsd = (amountIn * tokenInPrice) / EXP_SCALE;
        uint256 tokenOutAmount = (tokenInAmountUsd * EXP_SCALE) / tokenOutPrice;
        tokenOutMinimum = (tokenOutAmount * (EXP_SCALE - slippageRate - poolFee)) / EXP_SCALE;
    }

    /**
     * @notice Verifies if amounts are correct after swap based on trade type and expected values.
               Nullify allowance for tokenIn in case of ExactOut trade type.
     * @param isSwapTypeExactIn Marker of trade type
     * @param amountInDelta The actual value of spent In tokens
     * @param amountOutDelta The actual value of received Out tokens
     * @param tokenIn Input token
     * @param tokenInAmount TokenIn swap amount in case of ExactIn trade type or `TokenInMaximum`
              in case of ExactOut trade type
     * @param tokenOutAmount TokenOut swap amount in case of ExactOut trade type or `TokenOutMinimum`
              in case of ExactIn trade type
     */
    function validateAmountsAndNullifyAllowance(
        bool isSwapTypeExactIn,
        uint256 amountInDelta,
        uint256 amountOutDelta,
        IERC20 tokenIn,
        uint256 tokenInAmount,
        uint256 tokenOutAmount
    ) internal {
        if (isSwapTypeExactIn) {
            require(amountInDelta == tokenInAmount, ErrorCodes.FL_INVALID_AMOUNT_TOKEN_IN_SPENT);
            require(amountOutDelta >= tokenOutAmount, ErrorCodes.FL_INVALID_AMOUNT_TOKEN_OUT_RECEIVED);
            require(
                tokenIn.allowance(address(this), address(swapRouter)) == 0,
                ErrorCodes.FL_EXACT_IN_INCORRECT_ALLOWANCE_AFTER
            );
        } else {
            require(amountInDelta <= tokenInAmount, ErrorCodes.FL_INVALID_AMOUNT_TOKEN_IN_SPENT);
            require(
                amountOutDelta >= (tokenOutAmount * tokenOutDeviation) / EXP_SCALE,
                ErrorCodes.FL_INVALID_AMOUNT_TOKEN_OUT_RECEIVED
            );
            tokenIn.safeApprove(address(swapRouter), 0);
        }
    }

    /**
     * @notice Verifies if the provided address is not a zero address, throw otherwise
     * @param addressToValidate Address to validate
     */
    function validateZeroAddress(address addressToValidate) internal pure {
        require(addressToValidate != address(0), ErrorCodes.ZERO_ADDRESS);
    }

    /**
     * @notice Fetches the AAVE pool addresses provider contract of latest pool address
     */
    function getFreshPool() internal view returns (IPool) {
        return IPool(aavePoolAddressesProvider.getPool());
    }

    /**
     * @notice Verifies if the provided address is in allowedWithdrawReceivers list, throw otherwise
     * @param receiver Address to validate
     */
    modifier allowedReceiversOnly(address receiver) {
        require(allowedWithdrawReceivers[receiver], ErrorCodes.FL_RECEIVER_NOT_FOUND);
        _;
    }
}
