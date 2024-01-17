// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./IERC3156FlashBorrower.sol";
import "./IERC3156FlashLender.sol";
import "./IPool.sol";
import "./IStrategy.sol";
import "./CastU128I128.sol";
import "./CastU256U128.sol";
import "./IERC20.sol";
import "./TransferHelper.sol";
import "./ICauldron.sol";
import "./ILadle.sol";
import "./IFYToken.sol";
import "./Giver.sol";

error FlashLoanFailure();
error SlippageFailure();
error OnlyBorrow();
error OnlyRedeem();
error OnlyRepayOrClose();

/// @notice This contracts allows a user to 'lever up' their StrategyToken position.
///     Levering up happens as follows:
///     1. FlashBorrow fyToken
///     2. Sell fyToken to get base (USDC/DAI/ETH)
///     3. Mint LP token & deposit to strategy
///     4. Mint strategy token
///     5. Put strategy token as a collateral to borrow fyToken to repay flash loan
///
///     To get out of the levered position depending on whether we are past maturity the following happens:
///     1. Before maturity
///         A. Repay
///             i. FlashBorrow fyToken
///             ii. Payback the debt to get back the underlying
///             iii. Burn the strategy token to get LP
///             iv. Burn LP to get base & fyToken
///             v. Buy fyToken using the base to repay the flash loan
///         B. Close
///             i. FlashBorrow base
///             ii. Close the debt position using the base
///             iii. Burn the strategy token received from closing the position to get LP token
///             iv. Burn LP token to obtain base to repay the flash loan
///     2. After maturity
//          i. Payback debt to get back the underlying
//          ii. Burn Strategy Tokens and send LP token to the pool
//          iii. Burn LP token to obtain base to repay the flash loan, redeem the fyToken
/// @notice For leveringup we could flash borrow base instead of fyToken as well
/// @author iamsahu & alcueca
contract YieldStrategyLever is IERC3156FlashBorrower {
    using TransferHelper for IERC20;
    using TransferHelper for IFYToken;
    using CastU128I128 for uint128;
    using CastU256U128 for uint256;

    /// @notice The operation to execute in the flash loan.
    ///     - BORROW: Invest
    ///     - REPAY: Unwind before maturity, if pool rates are high
    ///     - CLOSE: Unwind before maturity, if pool rates are low
    ///     - REDEEM: Unwind after maturity
    enum Operation {
        BORROW,
        REPAY,
        CLOSE,
        REDEEM
    }

    /// @notice By IERC3156, the flash loan should return this constant.
    bytes32 public constant FLASH_LOAN_RETURN =
        keccak256("ERC3156FlashBorrower.onFlashLoan");

    bytes6 constant ASSET_ID_MASK = 0xFFFF00000000;

    /// @notice The Yield Cauldron, handles debt and collateral balances.
    ICauldron public constant CAULDRON =
        ICauldron(0xc88191F8cb8e6D4a668B047c1C8503432c3Ca867);

    /// @notice The Yield Ladle, the primary entry point for most high-level
    ///     operations.
    ILadle public constant LADLE =
        ILadle(0x6cB18fF2A33e981D1e38A663Ca056c0a5265066A);

    /// @notice The Giver contract can give vaults on behalf on a user who gave
    ///     permission.
    Giver public immutable giver;

    event Invested(
        bytes12 indexed vaultId,
        bytes6 seriesId,
        address indexed investor,
        uint256 investment,
        uint256 debt
    );

    event Divested(
        Operation indexed operation,
        bytes12 indexed vaultId,
        bytes6 seriesId,
        address indexed investor,
        uint256 profit,
        uint256 debt
    );

    constructor(Giver giver_) {
        giver = giver_;
    }

    /// @notice Invest by creating a levered vault. The basic structure is
    ///     always the same. We borrow FyToken for the series and convert it to
    ///     the yield-bearing token that is used as collateral.
    /// @param operation In can only be BORROW
    /// @param seriesId The series to invest in. This series doesn't usually
    ///     have the ilkId as base, but the asset the yield bearing token is
    ///     based on. For example: 0x303030370000 (WEth) instead of WStEth.
    /// @param strategyId The strategyId to invest in. This is often a yield-bearing
    ///     token, for example 0x303400000000 (WStEth).
    /// @param amountToInvest The amount of the base to invest. This is denoted
    ///     in terms of the base asset: USDC, DAI, etc.
    /// @param borrowAmount The amount to borrow. This is denoted in terms of
    ///     debt at maturity (and will thus be less before maturity).
    /// @param fyTokenToBuy The amount of fyToken to be bought from the base
    /// @param minCollateral Used for countering slippage. This is the minimum
    ///     amount of collateral that should be locked. The debt is always
    ///     equal to the borrowAmount plus flash loan fees.
    function invest(
        Operation operation,
        bytes6 seriesId,
        bytes6 strategyId,
        uint256 amountToInvest,
        uint256 borrowAmount,
        uint256 fyTokenToBuy,
        uint256 minCollateral
    ) external returns (bytes12 vaultId) {
        if (operation != Operation.BORROW) revert OnlyBorrow();
        IPool pool = IPool(LADLE.pools(seriesId));
        pool.base().safeTransferFrom(
            msg.sender,
            address(pool),
            amountToInvest
        );
        // Build the vault
        (vaultId, ) = LADLE.build(seriesId, strategyId, 0);

        bytes memory data = bytes.concat(
            bytes1(uint8(uint256(operation))), //[0]
            seriesId, //[1:7]
            vaultId, //[7:19]
            strategyId, //[19:25]
            bytes32(fyTokenToBuy), //[25:57]
            bytes20(msg.sender) //[57:77]
        );
        address fyToken = address(pool.fyToken());

        bool success = IERC3156FlashLender(fyToken).flashLoan(
            this, // Loan Receiver
            fyToken, // Loan Token
            borrowAmount, // Loan Amount
            data
        );

        if (!success) revert FlashLoanFailure();

        DataTypes.Balances memory balances = CAULDRON.balances(vaultId);

        // This is the amount to deposit, so we check for slippage here. As
        // long as we end up with the desired amount, it doesn't matter what
        // slippage occurred where.
        if (balances.ink < minCollateral)
            revert SlippageFailure();

        giver.give(vaultId, msg.sender);

        emit Invested(vaultId, seriesId, msg.sender, balances.ink, balances.art);
    }

    /// @notice Divest, either before or after maturity.
    /// @param operation REPAY, CLOSE or REDEEM
    /// @param vaultId The vault to divest from.
    /// @param seriesId The series to divest from.
    /// @param strategyId The strategyId to invest in. This is often a yield-bearing
    /// @param ink The amount of collateral to recover.
    /// @param art The amount of debt to repay.
    /// @param minBaseOut Used to minimize slippage. The transaction will revert
    ///     if we don't obtain at least this much of the base asset.
    function divest(
        Operation operation,
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 strategyId,
        uint256 ink,
        uint256 art,
        uint256 minBaseOut
    ) external {
        // Test that the caller is the owner of the vault.
        // This is important as we will take the vault from the user.
        require(CAULDRON.vaults(vaultId).owner == msg.sender);

        // Give the vault to the contract
        giver.seize(vaultId, address(this));

        IPool pool = IPool(LADLE.pools(seriesId));
        IERC20 baseAsset = IERC20(pool.base());

        bytes memory data = bytes.concat(
            bytes1(bytes1(uint8(uint256(operation)))), // [0:1]
            seriesId, // [1:7]
            vaultId, // [7:19]
            strategyId, // [19:25]
            bytes32(ink), // [25:57]
            bytes32(art) // [57:89]
        );

        // Check if we're pre or post maturity.
        bool success;
        if (uint32(block.timestamp) > CAULDRON.series(seriesId).maturity) {
            if (operation != Operation.REDEEM) revert OnlyRedeem();
            address join = address(LADLE.joins(seriesId & ASSET_ID_MASK));

            // Redeem:
            // Series is past maturity, borrow and move directly to collateral pool.
            // We have a debt in terms of fyToken, but should pay back in base.
            uint128 base = CAULDRON.debtToBase(seriesId, art.u128());
            success = IERC3156FlashLender(join).flashLoan(
                this, // Loan Receiver
                address(baseAsset), // Loan Token
                base, // Loan Amount
                data
            );
        } else {
            if (operation == Operation.REPAY) {
                IMaturingToken fyToken = pool.fyToken();

                // Repay:
                // Series is not past maturity.
                // Borrow to repay debt, move directly to the pool.
                success = IERC3156FlashLender(address(fyToken)).flashLoan(
                    this, // Loan Receiver
                    address(fyToken), // Loan Token
                    art, // Loan Amount: borrow exactly the debt to repay.
                    data
                );
                // Selling off leftover fyToken to get base in return
                if(fyToken.balanceOf(address(this)) > 0){
                    fyToken.transfer(address(pool), fyToken.balanceOf(address(this)));
                    pool.sellFYToken(address(this), 0);
                }
            } else if (operation == Operation.CLOSE) {
                address join = address(LADLE.joins(seriesId & ASSET_ID_MASK));

                // Close:
                // Series is not past maturity, borrow and move directly to collateral pool.
                // We have a debt in terms of fyToken, but should pay back in base.
                uint128 base = CAULDRON.debtToBase(seriesId, art.u128());
                success = IERC3156FlashLender(join).flashLoan(
                    this, // Loan Receiver
                    address(baseAsset), // Loan Token
                    base, // Loan Amount
                    data
                );                
            } else revert OnlyRepayOrClose();

        }
        if (!success) revert FlashLoanFailure();

        // Give the vault back to the sender, just in case there is anything left
        giver.give(vaultId, msg.sender);
        uint256 assetBalance = baseAsset.balanceOf(address(this));
        if (assetBalance < minBaseOut) revert SlippageFailure();
        // Transferring the leftover to the user
        if(assetBalance > 0)
            IERC20(baseAsset).safeTransfer(msg.sender, assetBalance);

        emit Divested(operation, vaultId, seriesId, msg.sender, assetBalance, art);
    }

    /// @notice Called by a flash lender. The primary purpose is to check
    ///     conditions and route to the correct internal function.
    ///
    ///     This function reverts if not called through a flashloan initiated
    ///     by this contract.
    /// @param initiator The initator of the flash loan, must be `address(this)`.
    /// @param borrowAmount The amount of fyTokens received.
    /// @param fee The fee that is subtracted in addition to the borrowed
    ///     amount when repaying.
    /// @param data The data we encoded for the functions. Here, we only check
    ///     the first byte for the router.
    function onFlashLoan(
        address initiator,
        address token,
        uint256 borrowAmount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32 returnValue) {
        returnValue = FLASH_LOAN_RETURN;
        Operation status = Operation(uint256(uint8(data[0])));
        bytes6 seriesId = bytes6(data[1:7]);
        bytes12 vaultId = bytes12(data[7:19]);
        bytes6 ilkId = bytes6(data[19:25]);

        // Test that the lender is either a fyToken contract or the join.
        if (
            msg.sender != address(IPool(LADLE.pools(seriesId)).fyToken()) &&
            msg.sender != address(LADLE.joins(seriesId & ASSET_ID_MASK))
        ) revert FlashLoanFailure();
        // We trust the lender, so now we can check that we were the initiator.
        if (initiator != address(this)) revert FlashLoanFailure();

        // Now that we trust the lender, we approve the flash loan repayment
        IERC20(token).safeApprove(msg.sender, borrowAmount + fee);

        // Decode the operation to execute and then call that function.
        if (status == Operation.BORROW) {
            uint256 fyTokenToBuy = uint256(bytes32(data[25:57]));
            address borrower = address(bytes20(data[57:77]));
            _borrow(vaultId, seriesId, ilkId, borrowAmount, fee, fyTokenToBuy,borrower);
        } else {
            uint256 ink = uint256(bytes32(data[25:57]));
            uint256 art = uint256(bytes32(data[57:89]));
            if (status == Operation.REPAY) {
                _repay(vaultId, seriesId, ilkId, (borrowAmount + fee), ink, art);
            } else if (status == Operation.CLOSE) {
                _close(IERC20(token), vaultId, seriesId, ilkId, borrowAmount, ink, art);
            } else if (status == Operation.REDEEM) {
                _redeem(IERC20(token), vaultId, seriesId, ilkId, borrowAmount, ink, art);
            }
        }
    }

    /// @notice The function does the following to create a leveraged position:
    ///         1. Sells the flash loaned fyToken to get base
    ///         2. Add the base as liquidity to obtain LP tokens
    ///         3. Deposit LP tokens in strategy to obtain strategy token
    ///         4. Finally use the Strategy tokens to borrow fyToken to repay the flash loan
    /// @param vaultId The vault id to put collateral into and borrow from.
    /// @param seriesId The pool (and thereby series) to borrow from.
    /// @param ilkId The id of the ilk being borrowed.
    /// @param borrowAmount The amount of FYTOKEN borrowed in the flash loan.
    /// @param fee The fee that will be issued by the flash loan.
    /// @param fyTokenToBuy the amount of fyTokenToBuy from the base.
    /// @param borrower the user who borrow.
    function _borrow(
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 ilkId,
        uint256 borrowAmount,
        uint256 fee,
        uint256 fyTokenToBuy,
        address borrower
    ) internal {
        // We have borrowed FyTokens, so sell those
        IPool pool = IPool(LADLE.pools(seriesId));
        IERC20 fyToken = IERC20(address(pool.fyToken()));
        fyToken.safeTransfer(address(pool), borrowAmount - fee);
        pool.sellFYToken(address(pool), 0); // Sell fyToken to get USDC/DAI/ETH
        address strategyAddress = CAULDRON.assets(ilkId);
        // Mint LP token & deposit to strategy
        pool.mintWithBase(
            strategyAddress,
            borrower,
            fyTokenToBuy,
            0,
            type(uint256).max
        );

        // Mint strategy token
        uint256 tokensMinted = IStrategy(strategyAddress).mint(
            address(LADLE.joins(ilkId))
        );

        // Borrow fyToken to repay the flash loan
        LADLE.pour(
            vaultId,
            address(this),
            tokensMinted.u128().i128(),
            borrowAmount.u128().i128()
        );
    }

    /// @notice Unwind position and repay using fyToken
    /// @param vaultId The vault to repay.
    /// @param seriesId The seriesId corresponding to the vault.
    /// @param strategyId The id of the strategy being invested.
    /// @param borrowAmountPlusFee The amount of fyToken that we have borrowed,
    ///     plus the fee. This should be our final balance.
    /// @param ink The amount of collateral to retake.
    /// @param art The debt to repay.
    ///     slippage.
    function _repay(
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 strategyId,
        uint256 borrowAmountPlusFee,
        uint256 ink,
        uint256 art
    ) internal {
        IPool pool = IPool(LADLE.pools(seriesId));
        address fyToken = address(pool.fyToken());
        address strategy = CAULDRON.assets(strategyId);

        // Payback debt to get back the underlying
        IERC20(fyToken).transfer(fyToken, art);
        LADLE.pour(vaultId, strategy, -ink.u128().i128(), -art.u128().i128());

        // Burn strat token to get LP
        IStrategy(strategy).burn(address(pool));

        // Burn LP to get base & fyToken
        (, , uint256 fyTokens) = pool.burn(
            address(this),
            address(this),
            0,
            type(uint256).max
        );

        // Buy fyToken to repay the flash loan
        if (borrowAmountPlusFee > fyTokens) {
            uint128 fyTokenToBuy = (borrowAmountPlusFee - fyTokens).u128();
            pool.base().transfer(address(pool), pool.buyFYTokenPreview(fyTokenToBuy));
            pool.buyFYToken(
                address(this),
                fyTokenToBuy,
                0
            );
        }
    }

    /// @notice Unwind position using the base asset and redeeming any fyToken
    /// @param baseAsset The base asset used for repayment
    /// @param vaultId The ID of the vault to close.
    /// @param seriesId The seriesId corresponding to the vault.
    /// @param strategyId The id of the strategy.
    /// @param debtInBase The amount of debt in base terms.
    /// @param ink The collateral to take from the vault.
    /// @param art The debt to repay. This is denominated in fyTokens
    function _close(
        IERC20 baseAsset,
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 strategyId,
        uint256 debtInBase,
        uint256 ink,
        uint256 art
    ) internal {
        address strategy = CAULDRON.assets(strategyId);
        address pool = LADLE.pools(seriesId);
        address baseJoin = address(LADLE.joins(CAULDRON.series(seriesId).baseId));

        // Payback debt to get back the underlying
        baseAsset.safeTransfer(baseJoin, debtInBase);
        LADLE.close(vaultId, strategy, -ink.u128().i128(), -art.u128().i128());

        // Burn Strategy Tokens and send LP token to the pool
        IStrategy(strategy).burn(address(pool));

        // Burn LP token to obtain base to repay the flash loan
        IPool(pool).burnForBase(address(this), 0, type(uint256).max);
    }


    /// @notice Unwind position using the base asset and redeeming any fyToken
    /// @param baseAsset The base asset used for repayment
    /// @param vaultId The ID of the vault to close.
    /// @param seriesId The seriesId corresponding to the vault.
    /// @param strategyId The id of the strategy.
    /// @param debtInBase The amount of debt in base terms.
    /// @param ink The collateral to take from the vault.
    /// @param art The debt to repay. This is denominated in fyTokens
    function _redeem(
        IERC20 baseAsset,
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 strategyId,
        uint256 debtInBase,
        uint256 ink,
        uint256 art
    ) internal {
        address strategy = CAULDRON.assets(strategyId);
        address pool = LADLE.pools(seriesId);
        address fyToken = address(IPool(pool).fyToken());
        address baseJoin = address(LADLE.joins(CAULDRON.series(seriesId).baseId));

        // Payback debt to get back the underlying
        baseAsset.safeTransfer(baseJoin, debtInBase);
        LADLE.close(vaultId, strategy, -ink.u128().i128(), -art.u128().i128());

        // Burn Strategy Tokens and send LP token to the pool
        IStrategy(strategy).burn(pool);

        // Burn LP token to obtain base to repay the flash loan, redeem the fyToken
        (,, uint256 fyTokens) = IPool(pool).burn(address(this), fyToken, 0, type(uint256).max);
        IFYToken(fyToken).redeem(address(this), fyTokens);
    }

    receive() external payable {}
}
