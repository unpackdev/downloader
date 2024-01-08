// SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

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

contract Hypervisor is IVault, IUniswapV3MintCallback, IUniswapV3SwapCallback, ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    uint256 public constant DUST_THRESHOLD = 1000;

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
     * @return amount0 Amount of token0 paid by sender
     * @return amount1 Amount of token1 paid by sender
     */
    function deposit(
        uint256 deposit0,
        uint256 deposit1,
        address to
    ) external override nonReentrant returns (uint256 amount0, uint256 amount1) {
        require(to != address(0), "to");

        if (totalSupply() == 0) {
            // For the initial deposit, place just the base order and ignore
            // the limit order
            uint128 shares = _liquidityForAmounts(baseLower, baseUpper, deposit0, deposit1);
            (amount0, amount1) = _mintLiquidity(
                baseLower,
                baseUpper,
                _uint128Safe(shares),
                msg.sender
            );

            _mint(to, shares);
            emit Deposit(msg.sender, to, shares, amount0, amount1);
        } else {
            uint256 finalDeposit0 = deposit0;
            uint256 finalDeposit1 = deposit1;
            {
            (uint256 pool0, uint256 pool1) = getTotalAmounts();
            uint256 price = 1;
            {
            int24 mid = _mid();
            uint160 sqrtPrice = TickMath.getSqrtRatioAtTick(mid);
            price = uint256(sqrtPrice).mul(uint256(sqrtPrice)).mul(1e18) >> (96 * 2);
            }
            int256 zeroForOneTerm = int256(deposit0).mul(int256(pool1)).sub(int256(pool0).mul(int256(deposit1)));
            uint256 token1Exchanged = FullMath.mulDiv(price, zeroForOneTerm > 0 ? uint256(zeroForOneTerm) : uint256(zeroForOneTerm.mul(-1)), pool0.mul(price).div(1e18).add(pool1).mul(1e18));

            if(deposit0 > 0) {
              token0.safeTransferFrom(msg.sender, address(this), deposit0);
            }
            if(deposit1 > 0) {
              token1.safeTransferFrom(msg.sender, address(this), deposit1);
            }

            if (token1Exchanged > 0) {
              (int256 amount0Delta, int256 amount1Delta) = pool.swap(
                  address(this),
                  zeroForOneTerm > 0,
                  zeroForOneTerm > 0 ? int256(token1Exchanged).mul(-1) : int256(token1Exchanged), // if we're swapping zero for one, then we want a precise output of token1 -- if we're swapping one for zero we want a precise input of token1
                  zeroForOneTerm > 0 ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1,
                  abi.encode(address(this))
              );
              finalDeposit0 = uint256(int256(finalDeposit0).sub(amount0Delta));
              finalDeposit1 = uint256(int256(finalDeposit1).sub(amount1Delta));
            }
            }

            // change this to new balanced amounts
            uint128 shares = _liquidityForAmounts(baseLower, baseUpper, finalDeposit0, finalDeposit1);
            uint128 baseLiquidity = _liquidityForShares(baseLower, baseUpper, shares);
            uint128 limitLiquidity = _liquidityForShares(limitLower, limitUpper, shares);

            // Deposit liquidity into Uniswap pool
            (uint256 base0, uint256 base1) =
                _mintLiquidity(baseLower, baseUpper, baseLiquidity, address(this));
            (uint256 limit0, uint256 limit1) =
                _mintLiquidity(limitLower, limitUpper, limitLiquidity, address(this));
            {
            // Transfer in tokens proportional to unused balances
            uint256 unused0 = _depositUnused(token0, shares);
            uint256 unused1 = _depositUnused(token1, shares);

            // Sum up total amounts paid by sender
            amount0 = base0.add(limit0).add(unused0);
            amount1 = base1.add(limit1).add(unused1);
            }

            _mint(to, shares);
            emit Deposit(msg.sender, to, shares, amount0, amount1);
            // Check total supply cap not exceeded. A value of 0 means no limit.
            require(maxTotalSupply == 0 || totalSupply() <= maxTotalSupply, "maxTotalSupply");
        }
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

            // Transfer out tokens proportional to unused balances
            uint256 unused0 = _withdrawUnused(token0, shares, to);
            uint256 unused1 = _withdrawUnused(token1, shares, to);

            // Sum up total amounts sent to recipient
            amount0 = base0.add(limit0).add(unused0);
            amount1 = base1.add(limit1).add(unused1);
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

        int24 mid = _mid();

        // Withdraw all liquidity and collect all fees from Uniswap pool
        uint128 basePosition = _position(baseLower, baseUpper);
        uint128 limitPosition = _position(limitLower, limitUpper);
        // Check current fee holdings
        (uint256 feesLimit0, uint256 feesLimit1) = getLimitFees();
        (uint256 feesBase0, uint256 feesBase1) = getBaseFees();

        uint256 fees0 = feesBase0.add(feesLimit0);
        uint256 fees1 = feesBase1.add(feesLimit1);
        _burnLiquidity(baseLower, baseUpper, basePosition, address(this), true);
        _burnLiquidity(limitLower, limitUpper, limitPosition, address(this), true);

        // transfer 10% of fees for VISR buybacks
        if(fees0 > 0) token0.transfer(feeRecipient, fees0.div(10));
        if(fees1 > 0) token1.transfer(feeRecipient, fees1.div(10));

        // Emit event with useful info
        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));

        emit Rebalance(mid, balance0, balance1, fees0, fees1, totalSupply());

        // Update base range and deposit liquidity in Uniswap pool. Base range
        // is symmetric so this order should use up all of one of the tokens.
        baseLower = _baseLower;
        baseUpper = _baseUpper;
        uint128 baseLiquidity = _maxDepositable(baseLower, baseUpper);
        _mintLiquidity(baseLower, baseUpper, baseLiquidity, address(this));

        // Calculate limit range
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

    /// @dev If vault holds enough unused token balance, transfer in
    /// proportional amount from sender. In general, the unused balance should
    /// be very low, so this transfer wouldn't be triggered.
    function _depositUnused(IERC20 token, uint256 shares) internal returns (uint256 amount) {
        uint256 balance = token.balanceOf(address(this));
        if (balance >= DUST_THRESHOLD) {
            // Add 1 to round up
            amount = balance.mul(shares).div(totalSupply()).add(1);
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    /// @dev If vault holds enough unused token balance, transfer proportional
    /// amount to sender. In general, the unused balance should be very low, so
    /// this transfer wouldn't be triggered.
    function _withdrawUnused(
        IERC20 token,
        uint256 shares,
        address to
    ) internal returns (uint256 amount) {
        uint256 balance = token.balanceOf(address(this));
        if (balance >= DUST_THRESHOLD) {
            amount = balance.mul(shares).div(totalSupply());
            token.safeTransfer(to, amount);
        }
    }

    /// @dev Convert shares into amount of liquidity. Shouldn't be called
    /// when total supply is 0.
    function _liquidityForShares(
        int24 tickLower,
        int24 tickUpper,
        uint256 shares
    ) internal view returns (uint128) {
        uint256 position = uint256(_position(tickLower, tickUpper));
        return _uint128Safe(position.mul(shares).div(totalSupply()));
    }

    /// @dev Amount of liquidity deposited by vault into Uniswap V3 pool for a
    /// certain range.
    function _position(int24 tickLower, int24 tickUpper)
        internal
        view
        returns (uint128 liquidity)
    {
        bytes32 positionKey = keccak256(abi.encodePacked(address(this), tickLower, tickUpper));
        (liquidity, , , , ) = pool.positions(positionKey);
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
        liquidity = _position(baseLower, baseUpper);
        (amount0, amount1) = _amountsForLiquidity(baseLower, baseUpper, liquidity);
    }

    function getBaseFees()
        public
        view
        returns (
            uint256 fees0,
            uint256 fees1
        )
    {
        bytes32 positionKey = keccak256(abi.encodePacked(address(this), baseLower, baseUpper));
        (, , , fees0, fees1) = pool.positions(positionKey);
    }

    function getLimitFees()
        public
        view
        returns (
            uint256 fees0,
            uint256 fees1
        )
    {
        bytes32 positionKey = keccak256(abi.encodePacked(address(this), limitLower, limitUpper));
        (, , , fees0, fees1) = pool.positions(positionKey);
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
        liquidity = _position(limitLower, limitUpper);
        (amount0, amount1) = _amountsForLiquidity(limitLower, limitUpper, liquidity);
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

    /// @dev Get current price from pool
    function _mid() internal view returns (int24 mid) {
        (, mid, , , , , ) = pool.slot0();
    }

    function _uint128Safe(uint256 x) internal pure returns (uint128) {
        assert(x <= type(uint128).max);
        return uint128(x);
    }

    function setMaxTotalSupply(uint256 _maxTotalSupply) external onlyOwner {
        maxTotalSupply = _maxTotalSupply;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _;
    }
}
