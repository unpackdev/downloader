// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// ====================================================================
// ======================== UniV3Asset.sol ============================
// ====================================================================

/**
 * @title Uniswap V3 Asset
 * @dev Implementation:
 * Mints a new LP.
 * Increases and decreases the liquidity for the LP created.
 * Collects fees from the LP.
 */

import "./Stabilizer.sol";
import "./LiquidityHelper.sol";
import "./INonfungiblePositionManager.sol";
import "./IERC721Receiver.sol";

contract UniV3Asset is IERC721Receiver, Stabilizer {
    // Uniswap V3 Position Manager
    INonfungiblePositionManager public constant nonfungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    LiquidityHelper private immutable liquidityHelper;

    // Variables
    uint256 public tokenId;
    address public token0;
    address public token1;
    uint128 public liquidity;
    bool private immutable flag; // The sort status of tokens
    int24 public constant TICK_SPACE = 10; // TICK_SPACE are 10, 60, 200

    // Events
    event Invested(uint256 indexed usdxAmount, uint256 indexed sweepAmount);
    event Divested(uint256 indexed usdxAmount, uint256 indexed sweepAmount);
    event Mint(uint256 tokenId, uint128 liquidity);
    event Collected(uint256 amount0, uint256 amount1);

    // Errors
    error NotMinted();
    error AlreadyMinted();
    error InvalidTokenID();
    error NonEmptyLiquidity();
    error OnlyPositionManager();

    /* ========== Modifies ========== */

    modifier isMinted() {
        if (tokenId == 0) revert NotMinted();
        _;
    }

    constructor(
        string memory _name,
        address _sweep,
        address _usdx,
        address _liquidityHelper,
        address _oracleUsdx,
        address _borrower
    ) Stabilizer(_name, _sweep, _usdx, _oracleUsdx, _borrower) {
        flag = _usdx < _sweep;

        (token0, token1) = flag ? (_usdx, _sweep) : (_sweep, _usdx);

        liquidityHelper = LiquidityHelper(_liquidityHelper);
    }

    /* ========== Views ========== */

    /**
     * @notice Current Value of investment.
     * @return total with 6 decimal to be compatible with dollar coins.
     */
    function currentValue() public view override returns (uint256) {
        uint256 accruedFeeInUSD = sweep.convertToUSD(accruedFee());
        return assetValue() + super.currentValue() - accruedFeeInUSD;
    }

    /**
     * @notice Gets the asset price of AMM
     * @return the amm usdx amount
     */
    function assetValue() public view returns (uint256) {
        if (tokenId == 0) return 0;

        IAMM _amm = amm();
        (uint256 amount0, uint256 amount1) = liquidityHelper
            .getTokenAmountsFromLP(tokenId, token0, token1, _amm.poolFee());
        (uint256 usdxAmount, uint256 sweepAmount) = flag
            ? (amount0, amount1)
            : (amount1, amount0);

        return _oracleUsdxToUsd(usdxAmount) + sweep.convertToUSD(sweepAmount);
    }

    /* ========== Actions ========== */

    /**
     * @notice Implementing `onERC721Received` so this contract can receive custody of erc721 tokens
     */
    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        if (msg.sender != address(nonfungiblePositionManager))
            revert OnlyPositionManager();
        if (tokenId > 0) revert AlreadyMinted();
        _createDeposit(_tokenId);

        return this.onERC721Received.selector;
    }

    /**
     * @notice Increases liquidity in the current range
     * @dev Pool must be initialized already to add liquidity
     * @param usdxAmount USDX Amount of asset to be deposited
     * @param sweepAmount Sweep Amount of asset to be deposited
     * @param usdxMinIn Min USDX amount to be used for liquidity.
     * @param sweepMinIn Min Sweep amount to be used for liquidity.
     */
    function invest(
        uint256 usdxAmount,
        uint256 sweepAmount,
        uint256 usdxMinIn,
        uint256 sweepMinIn
    )
        external
        onlyBorrower
        whenNotPaused
        nonReentrant
        validAmount(usdxAmount)
        validAmount(sweepAmount)
        returns (uint256, uint256)
    {
        return _invest(usdxAmount, sweepAmount, usdxMinIn, sweepMinIn);
    }

    /**
     * @notice A function that decreases the current liquidity.
     * @param liquidityAmount Liquidity Amount to decrease
     */
    function divest(
        uint256 liquidityAmount,
        uint256 amountOut0,
        uint256 amountOut1
    )
        external
        onlyBorrower
        isMinted
        nonReentrant
        validAmount(liquidityAmount)
        returns (uint256, uint256)
    {
        return _divest(liquidityAmount, amountOut0, amountOut1);
    }

    /**
     * @notice Collects the fees associated with provided liquidity
     * @dev The contract must hold the erc721 token before it can collect fees
     */
    function collect()
        external
        onlyBorrower
        whenNotPaused
        nonReentrant
        isMinted
        returns (uint256, uint256)
    {
        return _collect();
    }

    /**
     * @notice Burn NFT
     */
    function burnNFT() external onlyBorrower nonReentrant isMinted {
        nonfungiblePositionManager.burn(tokenId);
        tokenId = 0;
    }

    /**
     * @notice Get the ticks which will be used in the creating LP
     * @return minTick The minimum tick
     * @return maxTick The maximum tick
     */
    function showTicks() internal view returns (int24 minTick, int24 maxTick) {
        uint256 sweepPrice = sweep.targetPrice();
        uint256 minPrice = (sweepPrice * 99) / 100;
        uint256 maxPrice = (sweepPrice * 101) / 100;
        uint8 decimals = sweep.decimals();

        minTick = liquidityHelper.getTickFromPrice(
            minPrice,
            decimals,
            TICK_SPACE,
            flag
        );

        maxTick = liquidityHelper.getTickFromPrice(
            maxPrice,
            decimals,
            TICK_SPACE,
            flag
        );

        (minTick, maxTick) = minTick < maxTick
            ? (minTick, maxTick)
            : (maxTick, minTick);
    }

    function _createDeposit(uint256 _tokenId) internal {
        (
            ,
            ,
            address _token0,
            address _token1,
            ,
            ,
            ,
            uint128 _liquidity,
            ,
            ,
            ,

        ) = nonfungiblePositionManager.positions(_tokenId);

        if (token0 != _token0 || token1 != _token1) revert InvalidTokenID();

        liquidity = _liquidity;
        tokenId = _tokenId;

        emit Mint(_tokenId, _liquidity);
    }

    /**
     * @notice Calls the mint function defined in periphery, mints the same amount of each token.
     * For this example we are providing 1000 USDX and 1000 address(SWEEP) in liquidity
     * @dev Pool must be initialized already to add liquidity
     * @param amount0ToMint Amount of USDX
     * @param amount1ToMint Amount of SWEEP
     * @return _tokenId The id of the newly minted ERC721
     * @return _liquidity The amount of liquidity for the position
     * @return _amount0 The amount of token0
     * @return _amount1 The amount of token1
     */
    function _mint(
        uint256 amount0ToMint,
        uint256 amount1ToMint,
        uint256 minAmount0,
        uint256 minAmount1
    )
        internal
        returns (
            uint256 _tokenId,
            uint128 _liquidity,
            uint256 _amount0,
            uint256 _amount1
        )
    {
        (int24 minTick, int24 maxTick) = showTicks();
        IAMM _amm = amm();
        (_tokenId, _liquidity, _amount0, _amount1) = nonfungiblePositionManager
            .mint(
                INonfungiblePositionManager.MintParams({
                    token0: token0,
                    token1: token1,
                    fee: _amm.poolFee(),
                    tickLower: minTick,
                    tickUpper: maxTick,
                    amount0Desired: amount0ToMint,
                    amount1Desired: amount1ToMint,
                    amount0Min: minAmount0,
                    amount1Min: minAmount1,
                    recipient: address(this),
                    deadline: block.timestamp
                })
            );

        // Create a deposit
        _createDeposit(_tokenId);
    }

    function _invest(
        uint256 usdxAmount,
        uint256 sweepAmount,
        uint256 usdxMinIn,
        uint256 sweepMinIn
    ) internal returns (uint256, uint256) {
        (uint256 usdxBalance, uint256 sweepBalance) = _balances();
        if (usdxBalance == 0 || sweepBalance == 0) revert NotEnoughBalance();
        if (usdxBalance < usdxAmount) usdxAmount = usdxBalance;
        if (sweepBalance < sweepAmount) sweepAmount = sweepBalance;

        TransferHelper.safeApprove(
            address(usdx),
            address(nonfungiblePositionManager),
            usdxAmount
        );

        TransferHelper.safeApprove(
            address(sweep),
            address(nonfungiblePositionManager),
            sweepAmount
        );

        uint128 _liquidity;
        uint256 _amount0;
        uint256 _amount1;
        (uint256 amountAdd0, uint256 amountAdd1) = flag
            ? (usdxAmount, sweepAmount)
            : (sweepAmount, usdxAmount);
        (uint256 minAmount0, uint256 minAmount1) = flag
            ? (usdxMinIn, sweepMinIn)
            : (sweepMinIn, usdxMinIn);

        if (tokenId == 0) {
            (, _liquidity, _amount0, _amount1) = _mint(
                amountAdd0,
                amountAdd1,
                minAmount0,
                minAmount1
            );
        } else {
            (_liquidity, _amount0, _amount1) = nonfungiblePositionManager
                .increaseLiquidity(
                    INonfungiblePositionManager.IncreaseLiquidityParams({
                        tokenId: tokenId,
                        amount0Desired: amountAdd0,
                        amount1Desired: amountAdd1,
                        amount0Min: minAmount0,
                        amount1Min: minAmount1,
                        deadline: block.timestamp + 60 // Expiration: 1 hour from now
                    })
                );
            liquidity += _liquidity;
        }

        if (flag) {
            emit Invested(_amount0, _amount1);
            return (_amount0, _amount1);
        } else {
            emit Invested(_amount1, _amount0);
            return (_amount1, _amount0);
        }
    }

    function _divest(
        uint256 liquidityAmount,
        uint256 amountOut0,
        uint256 amountOut1
    ) internal returns (uint256, uint256) {
        uint128 decreaseLP = uint128(liquidityAmount);
        if (decreaseLP > liquidity) decreaseLP = liquidity;
        liquidity -= decreaseLP;

        // if the amount received after burning is not greater than these minimums, transaction will fail
        nonfungiblePositionManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: decreaseLP,
                amount0Min: amountOut0,
                amount1Min: amountOut1,
                deadline: block.timestamp
            })
        );

        (uint256 amount0, uint256 amount1) = _collect();

        if (flag) {
            emit Divested(amount0, amount1);
            return (amount0, amount1);
        } else {
            emit Divested(amount1, amount0);
            return (amount1, amount0);
        }
    }

    function _collect() internal returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = nonfungiblePositionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );

        emit Collected(amount0, amount1);
    }
}
