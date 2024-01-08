// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./IRiskManagerV1.sol";
import "./RiskManagerV1.sol";
import "./CoveragePool.sol";
import "./CoveragePoolConstants.sol";

import "./Ownable.sol";

/// @notice Interface for the Uniswap v2 router.
/// @dev This is an interface with just a few function signatures of the
///      router contract. For more info and function description please see:
///      https://uniswap.org/docs/v2/smart-contracts/router02
interface IUniswapV2Router {
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function factory() external pure returns (address);

    /* solhint-disable-next-line func-name-mixedcase */
    function WETH() external pure returns (address);
}

/// @notice Interface for the Uniswap v2 pair.
/// @dev This is an interface with just a few function signatures of the
///      pair contract. For more info and function description please see:
///      https://uniswap.org/docs/v2/smart-contracts/pair
interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

/// @title SignerBondsUniswapV2
/// @notice ETH purchased by the risk manager from tBTC signer bonds needs to be
///         swapped and deposited back to the coverage pool as collateral.
///         SignerBondsUniswapV2 is a swap strategy implementation which
///         can withdraw the given bonds amount from the risk manager, swap them
///         on Uniswap v2 exchange and deposit as coverage pool collateral.
///         The governance can set crucial swap parameters: max allowed
///         percentage impact, slippage tolerance and swap deadline, to force
///         reasonable swap outcomes. It is up to the governance to decide what
///         these values should be.
contract SignerBondsUniswapV2 is ISignerBondsSwapStrategy, Ownable {
    // One basis point is equivalent to 1/100th of a percent.
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    IUniswapV2Router public immutable uniswapRouter;
    IUniswapV2Pair public immutable uniswapPair;
    address public immutable assetPool;
    address public immutable collateralToken;

    mapping(address => bool) public approvedSwappers;

    // Determines the maximum allowed price impact for the swap transaction.
    // If transaction's price impact is higher, transaction will be reverted.
    // Default value is 100 basis points (1%).
    uint256 public maxAllowedPriceImpact = 100;
    // Determines the slippage tolerance for the swap transaction.
    // If transaction's slippage is higher, transaction will be reverted.
    // Default value is 50 basis points (0.5%).
    uint256 public slippageTolerance = 50;
    // Determines the deadline in which the swap transaction has to be mined.
    // If that deadline is exceeded, transaction will be reverted.
    uint256 public swapDeadline = 20 minutes;
    // Determines if the swap should revert when open auctions exists. If true,
    // swaps cannot be performed if there is at least one open auction.
    // If false, open auctions are not taken into account.
    bool public revertIfAuctionOpen = true;

    event SignerBondsSwapperApproved(address swapper);
    event SignerBondsSwapperUnapproved(address swapper);
    event UniswapV2SwapExecuted(uint256[] amounts);

    /// @notice Reverts if called by a signer bonds swapper that is not approved
    modifier onlyApprovedSwapper() {
        require(
            approvedSwappers[msg.sender],
            "Signer bonds swapper not approved"
        );
        _;
    }

    constructor(IUniswapV2Router _uniswapRouter, CoveragePool _coveragePool) {
        uniswapRouter = _uniswapRouter;
        assetPool = address(_coveragePool.assetPool());
        address _collateralToken = address(_coveragePool.collateralToken());
        collateralToken = _collateralToken;
        uniswapPair = IUniswapV2Pair(
            computePairAddress(
                _uniswapRouter.factory(),
                _uniswapRouter.WETH(),
                _collateralToken
            )
        );
    }

    /// @notice Receive ETH upon withdrawal of risk manager's signer bonds.
    /// @dev Do not send arbitrary funds. They will be locked forever.
    receive() external payable {}

    /// @notice Notifies the strategy about signer bonds purchase.
    /// @param amount Amount of purchased signer bonds.
    function onSignerBondsPurchased(uint256 amount) external override {}

    /// @notice Sets the maximum price impact allowed for a swap transaction.
    /// @param _maxAllowedPriceImpact Maximum allowed price impact specified
    ///        in basis points. Value of this parameter must be between
    ///        0 and 10000 (inclusive). It should be chosen carefully as
    ///        high limit level will accept transactions with high volumes.
    ///        Those transactions may result in poor execution prices. Very low
    ///        limit will force low swap volumes. Limit equal to 0 will
    ///        effectively make swaps impossible.
    function setMaxAllowedPriceImpact(uint256 _maxAllowedPriceImpact)
        external
        onlyOwner
    {
        require(
            _maxAllowedPriceImpact <= BASIS_POINTS_DIVISOR,
            "Maximum value is 10000 basis points"
        );
        maxAllowedPriceImpact = _maxAllowedPriceImpact;
    }

    /// @notice Sets the slippage tolerance for a swap transaction.
    /// @param _slippageTolerance Slippage tolerance in basis points. Value of
    ///        this parameter must be between 0 and 10000 (inclusive). It
    ///        should be chosen carefully as transactions with high slippage
    ///        tolerance result in poor execution prices. On the other hand,
    ///        very low slippage tolerance may cause transactions to be
    ///        reverted frequently. Slippage tolerance equal to 0 is possible
    ///        and disallows any slippage to happen on the swap at the cost
    ///        of higher revert risk.
    function setSlippageTolerance(uint256 _slippageTolerance)
        external
        onlyOwner
    {
        require(
            _slippageTolerance <= BASIS_POINTS_DIVISOR,
            "Maximum value is 10000 basis points"
        );
        slippageTolerance = _slippageTolerance;
    }

    /// @notice Sets the deadline for a swap transaction.
    /// @param _swapDeadline Swap deadline in seconds. Value of this parameter
    ///        should be equal or greater than 0. It should be chosen carefully
    ///        as transactions with long deadlines may result in poor execution
    ///        prices. On the other hand, very short deadlines may cause
    ///        transactions to be reverted frequently, especially in a
    ///        gas-expensive environment. Deadline equal to 0 will effectively
    //         make swaps impossible.
    function setSwapDeadline(uint256 _swapDeadline) external onlyOwner {
        swapDeadline = _swapDeadline;
    }

    /// @notice Sets whether a swap should revert if at least one
    ///         open auction exists.
    /// @param _revertIfAuctionOpen If true, revert the swap if there is at
    ///        least one open auction. If false, open auctions won't be taken
    ///        into account.
    function setRevertIfAuctionOpen(bool _revertIfAuctionOpen)
        external
        onlyOwner
    {
        revertIfAuctionOpen = _revertIfAuctionOpen;
    }

    /// @notice Swaps signer bonds on Uniswap v2 exchange.
    /// @dev Swaps the given ETH amount for the collateral token using the
    ///      Uniswap exchange. The maximum ETH amount is capped by the
    ///      contract balance. Some governance parameters are applied on the
    ///      transaction. The swap's price impact must fit within the
    ///      maximum allowed price impact and the transaction is constrained
    ///      with the slippage tolerance and deadline. Acquired collateral
    ///      tokens are sent to the asset pool address set during
    ///      contract construction.
    /// @param riskManager Address of the risk manager which holds the bonds.
    /// @param amount Amount to swap.
    function swapSignerBondsOnUniswapV2(
        IRiskManagerV1 riskManager,
        uint256 amount
    ) external onlyApprovedSwapper {
        require(amount > 0, "Amount must be greater than 0");
        require(
            amount <= address(riskManager).balance,
            "Amount exceeds risk manager balance"
        );

        if (revertIfAuctionOpen) {
            require(!riskManager.hasOpenAuctions(), "There are open auctions");
        }

        riskManager.withdrawSignerBonds(amount);

        // Setup the swap path. WETH must be the first component.
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = collateralToken;

        // Calculate the maximum output token amount basing on pair reserves.
        // This value will be used as the minimum amount of output tokens that
        // must be received for the transaction not to revert.
        // This value includes liquidity fee equal to 0.3%.
        uint256 amountOutMin = uniswapRouter.getAmountsOut(amount, path)[1];

        require(
            isAllowedPriceImpact(amountOutMin),
            "Price impact exceeds allowed limit"
        );

        // Include slippage tolerance into the minimum amount of output tokens.
        amountOutMin =
            (amountOutMin * (BASIS_POINTS_DIVISOR - slippageTolerance)) /
            BASIS_POINTS_DIVISOR;

        // slither-disable-next-line arbitrary-send,reentrancy-events
        uint256[] memory amounts = uniswapRouter.swapExactETHForTokens{
            value: amount
        }(
            amountOutMin,
            path,
            assetPool,
            /* solhint-disable-next-line not-rely-on-time */
            block.timestamp + swapDeadline
        );

        emit UniswapV2SwapExecuted(amounts);
    }

    /// @notice Approves the signer bonds swapper. The change takes effect
    ///         immediately.
    /// @dev Can be called only by the contract owner.
    /// @param swapper Swapper that will be approved
    function approveSwapper(address swapper) external onlyOwner {
        require(
            !approvedSwappers[swapper],
            "Signer bonds swapper has been already approved"
        );
        emit SignerBondsSwapperApproved(swapper);
        approvedSwappers[swapper] = true;
    }

    /// @notice Unapproves the signer bonds swapper. The change takes effect
    ///         immediately.
    /// @dev Can be called only by the contract owner.
    /// @param swapper Swapper that will be unapproved
    function unapproveSwapper(address swapper) external onlyOwner {
        require(
            approvedSwappers[swapper],
            "Signer bonds swapper is not approved"
        );
        emit SignerBondsSwapperUnapproved(swapper);
        delete approvedSwappers[swapper];
    }

    /// @notice Checks the price impact of buying a given amount of tokens
    ///         against the maximum allowed price impact limit.
    /// @param amount Amount of tokens.
    /// @return True if the price impact is allowed, false otherwise.
    function isAllowedPriceImpact(uint256 amount) public view returns (bool) {
        // Get reserve of the collateral token.
        address WETH = uniswapRouter.WETH();
        address token0 = WETH < collateralToken ? WETH : collateralToken;
        (uint256 reserve0, uint256 reserve1, ) = uniswapPair.getReserves();
        uint256 collateralTokenReserve = WETH == token0 ? reserve1 : reserve0;

        // Same as: priceImpact <= priceImpactLimit
        return
            amount * BASIS_POINTS_DIVISOR <=
            maxAllowedPriceImpact * collateralTokenReserve;
    }

    /// @notice Compute Uniswap v2 pair address.
    /// @param factory Address of the Uniswap v2 factory.
    /// @param tokenA Address of token A.
    /// @param tokenB Address of token B.
    /// @return Address of token pair.
    function computePairAddress(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address) {
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);

        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                factory,
                                keccak256(abi.encodePacked(token0, token1)),
                                hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
                            )
                        )
                    )
                )
            );
    }
}
