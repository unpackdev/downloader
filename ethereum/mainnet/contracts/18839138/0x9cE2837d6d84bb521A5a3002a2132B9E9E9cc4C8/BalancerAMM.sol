// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// ==========================================================
// ====================== BalancerAMM.sol ====================
// ==========================================================

/**
 * @title Balancer AMM
 * @dev Interactions with Balancer Pool
 */

import "./Chainlink.sol";
import "./IERC20Metadata.sol";
import "./Math.sol";
import "./TransferHelper.sol";
import "./ISweep.sol";
import "./IBalancer.sol";
import "./StableMath.sol";
import "./IMarketMaker.sol";

contract BalancerAMM {
    using Math for uint256;

    IBalancerVault public vault;
    IBalancerPool public pool;

    IERC20Metadata public immutable base;
    ISweep public immutable sweep;
    IPriceFeed public immutable oracleBase;
    IPriceFeed public immutable sequencer;
    uint256 public immutable oracleBaseUpdateFrequency;
    IMarketMaker public marketMaker;

    uint8 private constant USD_DECIMALS = 6;
    uint16 private constant DEADLINE_GAP = 15 minutes;

    constructor(
        address _sweep,
        address _base,
        address _sequencer,
        address _oracleBase,
        uint256 _oracleBaseUpdateFrequency
    ) {
        sweep = ISweep(_sweep);
        base = IERC20Metadata(_base);
        oracleBase = IPriceFeed(_oracleBase);
        sequencer = IPriceFeed(_sequencer);
        oracleBaseUpdateFrequency = _oracleBaseUpdateFrequency;
    }

    // Events
    event Bought(uint256 usdxAmount);
    event Sold(uint256 sweepAmount);

    // Errors
    error ZeroAmount();
    error BadRate();
    error NotOwnerOrGov();

    modifier onlyOwner () {
        if (msg.sender != sweep.fastMultisig() && msg.sender != sweep.owner())
            revert NotOwnerOrGov();
        _;
    }

    /**
     * @notice Get Price
     * @dev Get the quote for selling 1 unit of a token.
     */
    function getPrice() public view returns (uint256 amountOut) {
        if(address(pool) == address(0)) return 2e6;

        uint8 sweepDecimals = sweep.decimals();
        uint8 baseDecimals = base.decimals();
        uint8 quoteDecimals = sweepDecimals - baseDecimals;

        uint256[] memory factors = pool.getScalingFactors();
        (uint256 amplification, , ) = pool.getAmplificationParameter();
        (IAsset[] memory tokens, uint256[] memory balances,) = IBalancerVault(pool.getVault()).getPoolTokens(pool.getPoolId());

        uint8 tokenIndexIn = findAssetIndex(address(sweep), tokens);
        uint8 tokenIndexOut = findAssetIndex(address(base), tokens);

        uint256[] memory newBalances = new uint256[](2);
        newBalances[0] = balances[tokenIndexIn];
        newBalances[1] = balances[tokenIndexOut] * (10 ** quoteDecimals);

        uint256 invariant = StableMath._calculateInvariant(amplification, newBalances);
        uint256 quote = StableMath._calcOutGivenIn(amplification, newBalances, 0, 1, 1e18, invariant);
        uint8 oracleDecimals = ChainlinkLibrary.getDecimals(oracleBase);
        uint256 price = ChainlinkLibrary.getPrice(
            oracleBase,
            sequencer,
            oracleBaseUpdateFrequency
        );

        amountOut = (quote * factors[tokenIndexIn] * price) / (10 ** (oracleDecimals + sweepDecimals + quoteDecimals));
    }

    /**
     * @notice Get TWA Price
     * @dev Get the quote for selling 1 unit of a token.
     */
    function getTWAPrice() external view returns (uint256 amountOut) {
        return getPrice();
    }

    function getRate() public view returns (uint256 rate) {
        rate = sweep.targetPrice() * 1e12;
    }

    function getPositions(uint256)
        public view
        returns (uint256 usdxAmount, uint256 sweepAmount, uint256 lp)
    {
        (IAsset[] memory tokens, uint256[] memory balances,) = IBalancerVault(pool.getVault()).getPoolTokens(pool.getPoolId());
        uint8 usdxIndex = findAssetIndex(address(base), tokens);
        uint8 sweepIndex = findAssetIndex(address(sweep), tokens);
        uint8 lpIndex = findAssetIndex(address(pool), tokens);

        usdxAmount = balances[usdxIndex];
        sweepAmount = balances[sweepIndex];
        lp = balances[lpIndex];
    }

    /* ========== Actions ========== */

    /**
     * @notice Buy Sweep
     * @param usdxAddress Token Address to use for buying sweep.
     * @param usdxAmount Token Amount.
     * @param amountOutMin Minimum amount out.
     * @dev Increases the sweep balance and decrease collateral balance.
     */
    function buySweep(address usdxAddress, uint256 usdxAmount, uint256 amountOutMin) 
        external returns (uint256 sweepAmount)
    {
        emit Bought(usdxAmount);

        if (address(marketMaker) != address(0) && marketMaker.getBuyPrice() < getPrice()) {
            TransferHelper.safeTransferFrom(address(base), msg.sender, address(this), usdxAmount);
            TransferHelper.safeApprove(address(base), address(marketMaker), usdxAmount);
            sweepAmount = marketMaker.buySweep(usdxAmount);
            TransferHelper.safeTransfer(address(sweep), msg.sender, sweepAmount);
        } else {
            checkRate(usdxAddress, usdxAmount, amountOutMin);
            sweepAmount = swap(usdxAddress, address(sweep), usdxAmount, amountOutMin, address(pool));
        }        
    }

    /**
     * @notice Sell Sweep
     * @param usdxAddress Token Address to return after selling sweep.
     * @param sweepAmount Sweep Amount.
     * @param amountOutMin Minimum amount out.
     * @dev Decreases the sweep balance and increase collateral balance
     */
    function sellSweep(
        address usdxAddress,
        uint256 sweepAmount,
        uint256 amountOutMin
    ) external returns (uint256 tokenAmount) {
        emit Sold(sweepAmount);
        checkRate(usdxAddress, amountOutMin, sweepAmount);
        tokenAmount = swap(address(sweep), usdxAddress, sweepAmount, amountOutMin, address(pool));
    }

    /**
     * @notice Swap tokenIn for tokenOut using balancer exact input swap
     * @param tokenIn Address to in
     * @param tokenOut Address to out
     * @param amountIn Amount of _tokenA
     * @param amountOutMin Minimum amount out.
     */
    function swapExactInput(
        address tokenIn,
        address tokenOut,
        uint24,
        uint256 amountIn,
        uint256 amountOutMin
    ) public returns (uint256 amountOut) {
        return swap(tokenIn, tokenOut, amountIn, amountOutMin, address(pool));
    }

    function setPool(address poolAddress) external {
        require(msg.sender == sweep.owner(), "BalancerAMM: Not Governance");
        pool = IBalancerPool(poolAddress);
    }

    function findAssetIndex(address asset, IAsset[] memory assets) internal pure returns (uint8) {
        for (uint8 i = 0; i < assets.length; i++) {
            if (address(assets[i]) == asset) {
                return i;
            }
        }
        revert("BalancerAMM: Asset not found");
    }

    function checkRate(address token, uint256 tokenAmount, uint256 sweepAmount) internal view {
        if(tokenAmount == 0 || sweepAmount == 0) revert ZeroAmount();
        uint256 tokenFactor = 10 ** IERC20Metadata(token).decimals();
        uint256 sweepFactor = 10 ** sweep.decimals();
        uint256 rate = tokenAmount * sweepFactor * 1e6 / (tokenFactor * sweepAmount);
        if(rate > 16e5 || rate < 6e5) revert BadRate();
    }

    /**
     * @notice Swap tokenIn for tokenOut using balancer exact input swap
     * @param tokenIn Address to in
     * @param tokenOut Address to out
     * @param amountIn Amount of _tokenA
     * @param amountOutMin Minimum amount out.
     * @param poolAddress The pool to execute the swap into
     */
    function swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin, address poolAddress) 
        private returns (uint256 amountOut)
    {
        bytes32 poolId = IBalancerPool(poolAddress).getPoolId();
        address vaultAddress = IBalancerPool(poolAddress).getVault();

        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(tokenIn, vaultAddress, amountIn);

        bytes memory userData;
        SingleSwap memory singleSwap = SingleSwap(
            poolId,
            SwapKind.GIVEN_IN,
            IAsset(tokenIn),
            IAsset(tokenOut),
            amountIn,
            userData
        );

        FundManagement memory funds = FundManagement(address(this), false, payable(msg.sender), false);
        uint256 deadline = block.timestamp + DEADLINE_GAP;

        amountOut = IBalancerVault(vaultAddress).swap(singleSwap, funds, amountOutMin, deadline);
    }

    function setMarketMaker(address _marketMaker) external onlyOwner {
        marketMaker = IMarketMaker(_marketMaker);
    }
}
