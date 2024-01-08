// SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

import "./console.sol";
import "./SafeMath.sol";
import "./SignedSafeMath.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./IUniswapV3MintCallback.sol";
import "./IUniswapV3SwapCallback.sol";
import "./IUniswapV3Pool.sol";
import "./TickMath.sol";
import "./FullMath.sol";
import "./LiquidityAmounts.sol";

import "./IVault.sol";
import "./IUniversalVault.sol";

/**
 * @title   Passive Rebalance Vault
 * @notice  Automatically manages liquidity on Uniswap V3 on behalf of users.
 *
 *          When a user calls deposit(), they have to add amounts of the two
 *          tokens proportional to the vault's current holdings. These are
 *          directly deposited into the Uniswap V3 pool. Similarly, when a user
 *          calls withdraw(), the proportion of liquidity is withdrawn from the
 *          pool and the resulting amounts are returned to the user.
 *
 *          The rebalance() method has to be called periodically. This method
 *          withdraws all liquidity from the pool, collects fees and then uses
 *          all the tokens it holds to place the two range orders below.
 *
 *              1. Base order is placed between X - B and X + B + TS.
 *              2. Limit order is placed between X - L and X, or between X + TS
 *                 and X + L + TS, depending on which token it holds more of.
 *
 *          where:
 *
 *              X = current tick rounded down to multiple of tick spacing
 *              TS = tick spacing
 *              B = base threshold
 *              L = limit threshold
 *
 *          Note that after the rebalance, the vault should theoretically
 *          have deposited all its tokens and shouldn't have any unused
 *          balance. The base order deposits equal values, so it uses up
 *          the entire balance of whichever token it holds less of. Then, the
 *          limit order is placed only one side of the current price so that
 *          the other token which it holds more of is used up.
 */
contract Hypervisor is IVault, IUniswapV3MintCallback, IUniswapV3SwapCallback, ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    uint256 public constant DUST_THRESHOLD = 1000;
    uint256 public constant MILLIBASIS = 100000;

    IUniswapV3Pool public pool;
    IERC20 public token0;
    IERC20 public token1;
    uint24 public fee;
    int24 public tickSpacing;

    int24 public baseLower;
    int24 public baseUpper;
    int24 public limitLower;
    int24 public limitUpper;

    address public owner;
    uint256 public maxTotalSupply;

    /**
     * @param _pool Underlying Uniswap V3 pool
     * @param _owner The owner of the Hypervisor Contract
     */
    constructor(
        address _pool,
        address _owner,
        int24 _baseLower,
        int24 _baseUpper,
        int24 _limitLower,
        int24 _limitUpper
    ) ERC20("Fungible Liquidity", "LIQ") {
        pool = IUniswapV3Pool(_pool);
        token0 = IERC20(pool.token0());
        token1 = IERC20(pool.token1());
        fee = pool.fee();
        tickSpacing = pool.tickSpacing();

        owner = _owner;

        baseLower =  _baseLower;
        baseUpper =  _baseUpper;
        limitLower =  _limitLower;
        limitUpper =  _limitUpper;
        maxTotalSupply = 0; // no cap
    }

    /**
     * @notice Deposit tokens in proportion to the vault's holdings.
     * @param deposit0 Amount of token0 to deposit
     * @param deposit1 Amount of token1 to deposit
     * @param to Recipient of shares
     * @return shares Amount of shares distributed to sender
     */
    function deposit(
        uint256 deposit0,
        uint256 deposit1,
        address to
    ) external override nonReentrant returns (uint256 shares) {
        require(deposit0 > 0 || deposit1 > 0, "deposits must be nonzero");
        require(to != address(0) && to != address(this), "to");

        // update fess for inclusion in total pool amounts
        (uint128 baseLiquidity,,) = _position(baseLower, baseUpper);
        if (baseLiquidity > 0) {
            pool.burn(baseLower, baseUpper, 0);
        }
        (uint128 limitLiquidity,,)  = _position(limitLower, limitUpper);
        if (limitLiquidity > 0) {
            pool.burn(limitLower, limitUpper, 0);
        }

        uint256 price;
        {
        int24 currentTick = currentTick();
        uint160 sqrtPrice = TickMath.getSqrtRatioAtTick(currentTick);
        price = uint256(sqrtPrice).mul(uint256(sqrtPrice)).mul(1e18) >> (96 * 2);
        }

        // tokens which help balance the pool are given 100% of their token1
        // value in liquidity tokens
        // if the deposit worsens the ratio, dock the max - min amount 2%
        uint256 deposit0PricedInToken1 = deposit0.mul(price).div(1e18);
        (uint256 pool0, uint256 pool1) = getTotalAmounts();
        uint256 pool0PricedInToken1 = pool0.mul(price).div(1e18);
        if (pool0PricedInToken1.add(deposit0PricedInToken1) >= pool1 && deposit0PricedInToken1 > deposit1) {
            shares = reduceByPercent(deposit0PricedInToken1.sub(deposit1), 2);
            shares = shares.add(deposit1.mul(2));
        } else if (pool0PricedInToken1 <= pool1 && deposit0PricedInToken1 < deposit1) {
            shares = reduceByPercent(deposit1.sub(deposit0PricedInToken1), 2);
            shares = shares.add(deposit0PricedInToken1.mul(2));
        } else if (pool0PricedInToken1.add(deposit0PricedInToken1) < pool1.add(deposit1) && deposit0PricedInToken1 < deposit1) {
            uint256 docked1 = pool1.add(deposit1).sub(pool0PricedInToken1.add(deposit0PricedInToken1));
            shares = reduceByPercent(docked1, 2);
            shares = deposit1.sub(docked1).add(deposit0PricedInToken1);
        } else if (pool0PricedInToken1.add(deposit0PricedInToken1) > pool1.add(deposit1) && deposit0PricedInToken1 > deposit1) {
            uint256 docked0 = pool0PricedInToken1.add(deposit0PricedInToken1).sub(pool1.add(deposit1));
            shares = reduceByPercent(docked0, 2);
            shares = deposit0PricedInToken1.sub(docked0).add(deposit1);
        } else {
            shares = deposit1.add(deposit0PricedInToken1);
        }

        if (deposit0 > 0) {
          token0.safeTransferFrom(msg.sender, address(this), deposit0);
        }
        if (deposit1 > 0) {
          token1.safeTransferFrom(msg.sender, address(this), deposit1);
        }

        _mint(to, shares);
        emit Deposit(msg.sender, to, shares, deposit0, deposit1);
        // Check total supply cap not exceeded. A value of 0 means no limit.
        require(maxTotalSupply == 0 || totalSupply() <= maxTotalSupply, "maxTotalSupply");
    }

    /**
     * @notice Withdraw tokens in proportion to the vault's holdings.
     * @param shares Shares burned by sender
     * @param to Recipient of tokens
     * @return amount0 Amount of token0 sent to recipient
     * @return amount1 Amount of token1 sent to recipient
     */
    function withdraw(
        uint256 shares,
        address to,
        address from
    ) external override nonReentrant returns (uint256 amount0, uint256 amount1) {
        require(shares > 0, "shares");
        require(to != address(0), "to");

        {
            // Calculate how much liquidity to withdraw
            uint128 baseLiquidity = _liquidityForShares(baseLower, baseUpper, shares);
            uint128 limitLiquidity = _liquidityForShares(limitLower, limitUpper, shares);

            // Withdraw liquidity from Uniswap pool
            (uint256 base0, uint256 base1) =
                _burnLiquidity(baseLower, baseUpper, baseLiquidity, to, false);
            (uint256 limit0, uint256 limit1) =
                _burnLiquidity(limitLower, limitUpper, limitLiquidity, to, false);

            // Sum up total amounts sent to recipient
            amount0 = base0.add(limit0);
            amount1 = base1.add(limit1);
        }

        require(from == msg.sender || IUniversalVault(from).owner() == msg.sender, "Sender must own the tokens");
        _burn(from, shares);

        emit Withdraw(from, to, shares, amount0, amount1);
    }

    /**
     * @notice Update vault's positions arbitrarily
     */
    function rebalance(int24 _baseLower, int24 _baseUpper, int24 _limitLower, int24 _limitUpper, address feeRecipient) external override nonReentrant onlyOwner {
        // Check that ranges are not the same
        assert(_baseLower != _limitLower || _baseUpper != _limitUpper);

        int24 currentTick = currentTick();

        // Withdraw all liquidity and collect all fees from Uniswap pool
        (uint128 baseLiq, uint256 feesLimit0, uint256 feesLimit1) = _position(baseLower, baseUpper);
        (uint128 limitLiq, uint256 feesBase0, uint256 feesBase1)  = _position(limitLower, limitUpper);

        uint256 fees0 = feesBase0.add(feesLimit0);
        uint256 fees1 = feesBase1.add(feesLimit1);
        _burnLiquidity(baseLower, baseUpper, baseLiq, address(this), true);
        _burnLiquidity(limitLower, limitUpper, limitLiq, address(this), true);

        // transfer 10% of fees for VISR buybacks
        if(fees0 > 0) token0.transfer(feeRecipient, fees0.div(10));
        if(fees1 > 0) token1.transfer(feeRecipient, fees1.div(10));

        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));
        emit Rebalance(currentTick, balance0, balance1, fees0, fees1, totalSupply());

        baseLower = _baseLower;
        baseUpper = _baseUpper;
        uint128 baseLiquidity = _maxDepositable(baseLower, baseUpper);
        _mintLiquidity(baseLower, baseUpper, baseLiquidity, address(this));

        limitLower = _limitLower;
        limitUpper = _limitUpper;
        uint128 limitLiquidity = _maxDepositable(limitLower, limitUpper);
        _mintLiquidity(limitLower, limitUpper, limitLiquidity, address(this));
    }

    function _mintLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        address payer
    ) internal returns (uint256 amount0, uint256 amount1) {
      if (liquidity > 0) {
            (amount0, amount1) = pool.mint(
                address(this),
                tickLower,
                tickUpper,
                liquidity,
                abi.encode(payer)
            );
        }
    }

    /// @param collectAll Whether to also collect all accumulated fees.
    function _burnLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        address to,
        bool collectAll
    ) internal returns (uint256 amount0, uint256 amount1) {
        if (liquidity > 0) {
            // Burn liquidity
            (uint256 owed0, uint256 owed1) = pool.burn(tickLower, tickUpper, liquidity);

            // Collect amount owed
            uint128 collect0 = collectAll ? type(uint128).max : _uint128Safe(owed0);
            uint128 collect1 = collectAll ? type(uint128).max : _uint128Safe(owed1);
            if (collect0 > 0 || collect1 > 0) {
                (amount0, amount1) = pool.collect(to, tickLower, tickUpper, collect0, collect1);
            }
        }
    }

    /// @dev Convert shares into amount of liquidity. Shouldn't be called
    /// when total supply is 0.
    function _liquidityForShares(
        int24 tickLower,
        int24 tickUpper,
        uint256 shares
    ) internal view returns (uint128) {
        (uint128 position,,) = _position(tickLower, tickUpper);
        return _uint128Safe(uint256(position).mul(shares).div(totalSupply()));
    }

    /// @dev Amount of liquidity deposited by vault into Uniswap V3 pool for a
    /// certain range.
    function _position(int24 tickLower, int24 tickUpper)
        internal
        view
        returns (uint128 liquidity, uint128 tokensOwed0, uint128 tokensOwed1)
    {
        bytes32 positionKey = keccak256(abi.encodePacked(address(this), tickLower, tickUpper));
        (liquidity, , , tokensOwed0, tokensOwed1) = pool.positions(positionKey);
    }

    /// @dev Maximum liquidity that can deposited in range by vault given
    /// its balances of token0 and token1.
    function _maxDepositable(int24 tickLower, int24 tickUpper) internal view returns (uint128) {
        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));
        return _liquidityForAmounts(tickLower, tickUpper, balance0, balance1);
    }

    /// @dev Callback for Uniswap V3 pool mint.
    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        require(msg.sender == address(pool));
        address payer = abi.decode(data, (address));

        if (payer == address(this)) {
            if (amount0 > 0) token0.safeTransfer(msg.sender, amount0);
            if (amount1 > 0) token1.safeTransfer(msg.sender, amount1);
        } else {
            if (amount0 > 0) token0.safeTransferFrom(payer, msg.sender, amount0);
            if (amount1 > 0) token1.safeTransferFrom(payer, msg.sender, amount1);
        }
    }

    /// @dev Callback for Uniswap V3 pool swap.
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        require(msg.sender == address(pool));
        address payer = abi.decode(data, (address));

        if (amount0Delta > 0) {
        // token0.transfer(msg.sender, uint256(amount0Delta));
        if(payer == address(this)) {
            token0.transfer(msg.sender, uint256(amount0Delta));

          }else{
            token0.safeTransferFrom(payer, msg.sender, uint256(amount0Delta));
          }
        } 
        else if (amount1Delta > 0) {
          if(payer == address(this)) {
            token1.transfer(msg.sender, uint256(amount1Delta));
          }
          else{
            token1.safeTransferFrom(payer, msg.sender, uint256(amount1Delta));
          }
        }
    }

    /**
     * @notice Calculate total holdings of token0 and token1, or how much of
     * each token this vault would hold if it withdrew all its liquidity.
     */
    function getTotalAmounts() public view override returns (uint256 total0, uint256 total1) {
        (, uint256 base0, uint256 base1) = getBasePosition();
        (, uint256 limit0, uint256 limit1) = getLimitPosition();
        total0 = token0.balanceOf(address(this)).add(base0).add(limit0);
        total1 = token1.balanceOf(address(this)).add(base1).add(limit1);
    }

    /**
     * @notice Calculate liquidity and equivalent token amounts of base order.
     */
    function getBasePosition()
        public
        view
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        (uint128 positionLiquidity, uint128 tokensOwed0, uint128 tokensOwed1) = _position(baseLower, baseUpper);
        (amount0, amount1) = _amountsForLiquidity(baseLower, baseUpper, positionLiquidity);
        amount0 = amount0.add(uint256(tokensOwed0));
        amount1 = amount1.add(uint256(tokensOwed1));
        liquidity = positionLiquidity;
    }

    /**
     * @notice Calculate liquidity and equivalent token amounts of limit order.
     */
    function getLimitPosition()
        public
        view
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        (uint128 positionLiquidity, uint128 tokensOwed0, uint128 tokensOwed1) = _position(limitLower, limitUpper);
        (amount0, amount1) = _amountsForLiquidity(limitLower, limitUpper, positionLiquidity);
        amount0 = amount0.add(uint256(tokensOwed0));
        amount1 = amount1.add(uint256(tokensOwed1));
        liquidity = positionLiquidity;
    }

    /// @dev Wrapper around `getAmountsForLiquidity()` for convenience.
    function _amountsForLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal view returns (uint256, uint256) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return
            LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidity
            );
    }

    /// @dev Wrapper around `getLiquidityForAmounts()` for convenience.
    function _liquidityForAmounts(
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) internal view returns (uint128) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return
            LiquidityAmounts.getLiquidityForAmounts(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                amount0,
                amount1
            );
    }

    /// @dev Get current tick from pool
    function currentTick() internal view returns (int24 currentTick) {
        (, currentTick, , , , , ) = pool.slot0();
    }

    function _uint128Safe(uint256 x) internal pure returns (uint128) {
        assert(x <= type(uint128).max);
        return uint128(x);
    }

    function setMaxTotalSupply(uint256 _maxTotalSupply) external onlyOwner {
        maxTotalSupply = _maxTotalSupply;
    }

    function reduceByPercent(uint256 quantity, uint256 percent) internal view returns (uint256) {
          return quantity.mul(MILLIBASIS.mul(100 - percent)).div(MILLIBASIS.mul(100));
    }

    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _;
    }
}
