pragma solidity 0.8.23;

import "./OwnableUpgradeable.sol";
import "./IERC3156FlashLender.sol";
import "./IERC1155UniswapV3Wrapper.sol";
import "./IPool.sol";
import "./IUniswapV3Pool.sol";
import "./IUniswapV3Factory.sol";
import "./INonfungiblePositionManager.sol";
import "./IPoolAddressesProvider.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IYLDROracle.sol";
import "./TickMath.sol";
import "./LiquidityAmounts.sol";
import "./IAssetConverter.sol";
import "./SafeERC20.sol";
import "./ERC1155Holder.sol";
import "./ERC721Holder.sol";
import "./Math.sol";

/// @author YLDR <admin@apyflow.com>
/// @notice This contract represents single leveraged position linked to a specific user
/// This contract's funds mainly stored in yldr protocol and consist of wrapped into ERC1155 Uniswap LP Position
/// and debt.
contract UniswapV3LeveragedPosition is OwnableUpgradeable, ERC1155Holder, ERC721Holder, IERC3156FlashBorrower {
    using SafeERC20 for IERC20;

    event Deleverage();

    /// @notice Id of leveraged position. The safe Id is used in Uniswap V3 position manager and yldr's ERC1155 Uniswap wrapper
    uint256 public positionTokenId;

    IUniswapV3Pool public uniswapV3Pool;
    address public token0;
    address public token1;
    /// @notice Address of token which was borrowed to leverage position
    address public borrowedToken;
    uint24 public fee;
    int24 public tickLower;
    int24 public tickUpper;

    /// @dev Temproary variable used only to store flash loan provider address during flashloans
    /// Different providers may be used for deposits and withdrawals
    IERC3156FlashLender private flashLoanProvider;

    INonfungiblePositionManager public immutable positionManager;
    IUniswapV3Factory public immutable uniswapV3Factory;
    IPoolAddressesProvider public immutable addressesProvider;
    IERC1155UniswapV3Wrapper public immutable uniswapV3Wrapper;

    /// @notice Params which are used to initialize position
    /// @param tokenId ID of position token
    /// @param tokenToBorrow Token which has to be borrowed to leverage position
    /// @param amountToBorrow Amount of token to borrow
    /// @param flashLoanProvider IERC3156-flashloan provider chosen by user which will be used to aquire funds for leveraging
    /// @param assetConverter Converter chosen by user which will be used to swap borrowed token into token0 and token1
    /// @param owner Owner of the position
    /// @param maxSwapSlippage Max slippage for swaps
    struct PositionInitParams {
        uint256 tokenId;
        address tokenToBorrow;
        uint256 amountToBorrow;
        IERC3156FlashLender flashLoanProvider;
        IAssetConverter assetConverter;
        address owner;
        uint256 maxSwapSlippage;
    }

    /// @notice Params which are used to deleverage position
    /// @param assetConverter Converter chosen by user which will be used to swap token0 and token1 into borrowed token
    /// @param maxSwapSlippage Max slippage for swaps
    /// @param receiver Address which will receive leftover tokens after deleveraging
    struct DeleverageParams {
        IAssetConverter assetConverter;
        uint256 maxSwapSlippage;
        address receiver;
    }

    constructor(IPoolAddressesProvider _addressesProvider, IERC1155UniswapV3Wrapper _uniswapV3Wrapper) {
        addressesProvider = _addressesProvider;
        uniswapV3Wrapper = _uniswapV3Wrapper;
        positionManager = _uniswapV3Wrapper.positionManager();
        uniswapV3Factory = IUniswapV3Factory(positionManager.factory());
    }

    /// @notice Initializer of the contract. Sets storage variables and performs leveraging operations
    /// 1. Take flashloan
    /// 2. Swap borrowed token into token0 and token1
    /// 3. Increase liquidity of position
    /// 4. Take normal debt at yldr
    /// 5. Repay flashloan with borrowed tokens
    function initialize(PositionInitParams calldata params) public initializer {
        __Ownable_init(params.owner);
        positionTokenId = params.tokenId;
        borrowedToken = params.tokenToBorrow;

        (,, token0, token1, fee, tickLower, tickUpper,,,,,) = positionManager.positions(params.tokenId);
        uniswapV3Pool = IUniswapV3Pool(uniswapV3Factory.getPool(token0, token1, fee));

        _takeFlashloan(params.flashLoanProvider, params.tokenToBorrow, params.amountToBorrow, abi.encode(params));
    }

    /// @notice Helper function for flashloans. Sets temporary flashLoanProvider storage variable to authorize flashloan
    function _takeFlashloan(IERC3156FlashLender _flashLoanProvider, address token, uint256 amount, bytes memory data)
        internal
    {
        flashLoanProvider = _flashLoanProvider;
        flashLoanProvider.flashLoan(this, token, amount, data);
        flashLoanProvider = IERC3156FlashLender(address(0));
    }

    /// @notice Function to perform swaps through user-supplied assetConverter.
    /// @param assetConverter Converter which will be used to perform swaps
    /// @param source Token to swap from
    /// @param destination Token to swap to
    /// @param amount Amount to swap
    /// @param maxSlippage Max slippage for swaps
    function _swap(
        IAssetConverter assetConverter,
        address source,
        address destination,
        uint256 amount,
        uint256 maxSlippage
    ) internal returns (uint256 amountOut) {
        if (source == destination) {
            return amount;
        }
        if (amount == 0) {
            return 0;
        }
        if (IERC20(source).allowance(address(this), address(assetConverter)) < amount) {
            IERC20(source).forceApprove(address(assetConverter), type(uint256).max);
        }
        return assetConverter.swap(source, destination, amount, maxSlippage);
    }

    /// @notice Function which uses current pool price and oracle prices to find distribution in which funds should
    /// be divided to supply liquidity in position with as less leftovers as possible.
    function _divideAmountForSwap(uint256 amount)
        internal
        view
        returns (uint256 amountToSwapFor0, uint256 amountToSwapFor1)
    {
        IYLDROracle oracle = IYLDROracle(addressesProvider.getPriceOracle());

        (,,,,,,, uint128 liquidity,,,,) = positionManager.positions(positionTokenId);

        (uint160 sqrtPriceX96,,,,,,) = uniswapV3Pool.slot0();
        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96, TickMath.getSqrtRatioAtTick(tickLower), TickMath.getSqrtRatioAtTick(tickUpper), liquidity
        );

        uint256 amount0USD = amount0 * oracle.getAssetPrice(token0) / (10 ** IERC20Metadata(token0).decimals());
        uint256 amount1USD = amount1 * oracle.getAssetPrice(token1) / (10 ** IERC20Metadata(token1).decimals());

        amountToSwapFor0 = amount * amount0USD / (amount0USD + amount1USD);
        amountToSwapFor1 = amount * amount1USD / (amount0USD + amount1USD);
    }

    // helps avoid stack too deep
    struct InitPositionVars {
        uint256 amountToSwapFor0;
        uint256 amountToSwapFor1;
        uint256 amount0;
        uint256 amount1;
        uint256 amount0Resulted;
        uint256 amount1Resulted;
        uint256 left0;
        uint256 left1;
    }

    /// @notice Function whicn initializes leveraged position
    function _initPositionInsideFlashloan(PositionInitParams memory params, uint256 flashFee) internal {
        InitPositionVars memory vars;

        // Calculate amounts to swap for token0 and token1
        (vars.amountToSwapFor0, vars.amountToSwapFor1) = _divideAmountForSwap(params.amountToBorrow);

        // Do swaps
        vars.amount0 =
            _swap(params.assetConverter, params.tokenToBorrow, token0, vars.amountToSwapFor0, params.maxSwapSlippage);
        vars.amount1 =
            _swap(params.assetConverter, params.tokenToBorrow, token1, vars.amountToSwapFor1, params.maxSwapSlippage);

        IERC20(token0).forceApprove(address(positionManager), vars.amount0);
        IERC20(token1).forceApprove(address(positionManager), vars.amount1);

        // Add liquidity
        (, vars.amount0Resulted, vars.amount1Resulted) = positionManager.increaseLiquidity(
            INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: positionTokenId,
                amount0Desired: vars.amount0,
                amount1Desired: vars.amount1,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );

        // Account for leftovers
        vars.left0 = vars.amount0 - vars.amount0Resulted;
        vars.left1 = vars.amount1 - vars.amount1Resulted;

        // Swap leftovers back to borrowed token
        uint256 tokenToBorrowLeft = _swap(
            params.assetConverter, token0, params.tokenToBorrow, vars.left0, params.maxSwapSlippage
        ) + _swap(params.assetConverter, token1, params.tokenToBorrow, vars.left1, params.maxSwapSlippage);

        // Borrow additional tokens to repay flashloan, accouning for leftovers
        IPool(addressesProvider.getPool()).borrow(
            params.tokenToBorrow, params.amountToBorrow + flashFee - tokenToBorrowLeft, 0, address(this)
        );
    }

    /// @notice Helper function for deleveraging position which burns position partly and sends the rest to receiver
    /// It is called when we need to withdraw position, but keep part of it to swap into debt token and repay debt
    ///
    /// In case when we are the only owner of the position, we can just unwrap it and decrease liquidity via position manager
    ///
    /// In case when we are not the only owner of the position (this can happen when position was liquidated), we can't unwrap it,
    /// so we burn all shares, receive token0 and token1 amounts and send part of it to receiver
    function _burnPartAndWithdrawRest(uint256 balanceToBurn, address receiver)
        internal
        returns (uint256 amount0, uint256 amount1)
    {
        uint256 totalBalance = uniswapV3Wrapper.balanceOf(address(this), positionTokenId);

        if (uniswapV3Wrapper.totalSupply(positionTokenId) == totalBalance) {
            // If we are the only owner of the position, we can just unwrap it and withdraw liquidity via position manager
            uniswapV3Wrapper.unwrap(address(this), positionTokenId, address(this));
            (,,,,,,, uint128 liquidity,,,,) = positionManager.positions(positionTokenId);
            uint256 liquidityToBurn = Math.mulDiv(balanceToBurn, liquidity, totalBalance, Math.Rounding.Floor);
            (amount0, amount1) = positionManager.decreaseLiquidity(
                INonfungiblePositionManager.DecreaseLiquidityParams({
                    tokenId: positionTokenId,
                    liquidity: uint128(liquidityToBurn),
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                })
            );
            // At this point, tokensOwed contains fees + amounts just withdrawn
            (,,,,,,,,,, uint256 tokensOwed0, uint256 tokensOwed1) = positionManager.positions(positionTokenId);
            uint256 fees0 = tokensOwed0 - amount0;
            uint256 fees1 = tokensOwed1 - amount1;
            amount0 += Math.mulDiv(fees0, balanceToBurn, totalBalance, Math.Rounding.Floor);
            amount1 += Math.mulDiv(fees1, balanceToBurn, totalBalance, Math.Rounding.Floor);
            positionManager.collect(
                INonfungiblePositionManager.CollectParams({
                    tokenId: positionTokenId,
                    recipient: address(this),
                    amount0Max: uint128(amount0),
                    amount1Max: uint128(amount1)
                })
            );
            // Send NFT to owner, we don't need it anymore
            positionManager.safeTransferFrom(address(this), receiver, positionTokenId, "");
        } else {
            // If we are not the only owner of LP, we can't unwrap it, so we need to burn our shares
            (uint256 amount0Total, uint256 amount1Total) =
                uniswapV3Wrapper.burn(address(this), positionTokenId, totalBalance, address(this));

            // Now we can calculate amounts to withdraw for repayments
            amount0 = Math.mulDiv(balanceToBurn, amount0Total, totalBalance, Math.Rounding.Floor);
            amount1 = Math.mulDiv(balanceToBurn, amount1Total, totalBalance, Math.Rounding.Floor);

            // Send leftovers to user
            IERC20(token0).safeTransfer(receiver, amount0Total - amount0);
            IERC20(token1).safeTransfer(receiver, amount1Total - amount1);
        }
    }

    /// @notice Function whicn deleverages position
    /// @param params Params which are used to deleverage position
    /// @param amount Amount of flashloan
    /// @param flashFee Fee of flashloan
    function _deleverageInsideFlashloan(DeleverageParams memory params, uint256 amount, uint256 flashFee) internal {
        IPool pool = IPool(addressesProvider.getPool());
        // Repay debt with flashloaned funds
        IERC20(borrowedToken).forceApprove(address(pool), amount);
        if (amount > 0) {
            pool.repay(borrowedToken, amount, address(this));
        }

        // Withdraw LP
        uint256 balance =
            pool.withdrawERC1155(address(uniswapV3Wrapper), positionTokenId, type(uint256).max, address(this));
        uint256 wrappedTotalSupply = uniswapV3Wrapper.totalSupply(positionTokenId);

        // Calculate amount of LP which will be used for repayment
        uint256 balanceToUseForRepayment;
        {
            IYLDROracle oracle = IYLDROracle(addressesProvider.getPriceOracle());
            uint256 positionValue =
                balance * oracle.getERC1155AssetPrice(address(uniswapV3Wrapper), positionTokenId) / wrappedTotalSupply;
            uint256 debtValue = (amount + flashFee) * oracle.getAssetPrice(borrowedToken)
                / (10 ** IERC20Metadata(borrowedToken).decimals());

            balanceToUseForRepayment = Math.mulDiv(debtValue, balance, positionValue, Math.Rounding.Ceil);
        }

        // Consider slippage, if we will end up with more than needed, rest will be sent to receiver as well
        balanceToUseForRepayment =
            Math.min(balance, balanceToUseForRepayment * (10000 + params.maxSwapSlippage) / 10000);

        // Aquire amounts to swap into borrowed token
        (uint256 amount0, uint256 amount1) = _burnPartAndWithdrawRest(balanceToUseForRepayment, params.receiver);

        // Swap tokens to repay debt
        uint256 amountForRepayment = _swap(
            params.assetConverter, token0, borrowedToken, amount0, params.maxSwapSlippage
        ) + _swap(params.assetConverter, token1, borrowedToken, amount1, params.maxSwapSlippage);

        if (amountForRepayment > amount + flashFee) {
            // If we have leftovers, send them to user
            IERC20(borrowedToken).safeTransfer(params.receiver, amountForRepayment - amount - flashFee);
        }
    }

    /// @notice Function which is called by flashloan provider
    function onFlashLoan(address initiator, address token, uint256 amount, uint256 flashFee, bytes calldata data)
        external
        returns (bytes32)
    {
        require(initiator == address(this), "Invalid initiator");
        require(msg.sender == address(flashLoanProvider), "Invalid caller");

        if (_isInitializing()) {
            _initPositionInsideFlashloan(abi.decode(data, (PositionInitParams)), flashFee);
        } else {
            _deleverageInsideFlashloan(abi.decode(data, (DeleverageParams)), amount, flashFee);
        }

        IERC20(token).forceApprove(msg.sender, amount + flashFee);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    /// @notice Function only callable by position owner to deleverage position
    /// It performs following steps:
    /// 1. Take flashloan
    /// 2. Repay debt with flashloaned funds
    /// 3. Withdraw position
    /// 4. Use part of position's funds to swap token0 and token1 into debt token
    /// 5. Send the rest of position funds to receiver
    /// 6. Repay flashloan with tokens taken from position
    function deleverage(IERC3156FlashLender flashloanProvider, DeleverageParams memory params) external {
        _checkOwner();
        uint256 debtToCover = IERC20(
            IPool(addressesProvider.getPool()).getReserveData(borrowedToken).variableDebtTokenAddress
        ).balanceOf(address(this));
        _takeFlashloan(flashloanProvider, borrowedToken, debtToCover, abi.encode(params));

        emit Deleverage();
    }
}
