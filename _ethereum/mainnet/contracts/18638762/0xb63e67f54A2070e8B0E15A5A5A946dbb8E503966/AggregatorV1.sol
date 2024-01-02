// Thunderhead: https://github.com/thunderhead-labs


// Author(s)
// Addison Spiegel: https://addison.is
// Pierre Spiegel: https://pierre.wtf

pragma solidity 0.8.20;

import "./TenderSwap.sol";
import "./IStableSwap.sol";
import "./MinterV1.sol";
import "./BurnerV1.sol";
import "./console.sol";
import "./Initializable.sol";
import "./ProxyAdmin.sol";

/**
 * @title Aggregator contract for stFLIP
 * @notice Allows users to stake/unstake optimally allotting users to add a swap 
 * component to their route or instant burn/ normal burn in one tx. Calls 
 * `BurnerV1` to burn, `MinterV1` to mint and `IStableSwap` to swap. After speaking
 * with the Curve team they have recommended we use the StableSwap pool that will 
 * be released later this month. https://github.com/curvefi/stableswap-ng/pull/30
 * This might change some of the function or interfaces with the pool.
 */
contract AggregatorV1 is Initializable, Ownership {

    IERC20 public stflip;
    IERC20 public flip;
    MinterV1 public minter;
    BurnerV1 public burner;
    IStableSwap public canonicalPool;

    constructor () {
        _disableInitializers();
    }

    function initialize (address minter_, address burner_, address liquidityPool_, address stflip_, address flip_, address gov_) initializer public {
        // // associating relevant contracts
        minter = MinterV1(minter_);
        burner = BurnerV1(burner_);
        canonicalPool = IStableSwap(liquidityPool_);
        flip = IERC20(flip_);
        stflip = IERC20(stflip_);

        // giving infinite approvals to the curve pool and the minter
        
        if (liquidityPool_ != address(0)) {
            flip.approve(address(liquidityPool_), type(uint256).max);
        }
        flip.approve(address(minter), type(uint256).max);
        stflip.approve(address(burner), type(uint256).max);
        stflip.approve(address(liquidityPool_), type(uint256).max);

        __AccessControlDefaultAdminRules_init(0, gov_);
    }

    event StakeAggregation (address indexed sender, uint256 indexed swapReceived, uint256 indexed minted);
    event BurnAggregation (address sender, uint256 indexed amountInstantBurn, uint256 indexed amountBurn, uint256 indexed received);
    event CanonicalPoolChanged(address indexed pool);

    error NoAttemptsLeft();

    /**
    * @notice Spends stFLIP for FLIP via swap, instant burn, and unstake request.
    * @param amountInstantBurn The amount of stFLIP to instant burn
    * @param amountBurn The amount of stFLIP to burn.
    * @param amountSwap The amount of stFLIP to swap for FLIP
    * @param minimumAmountSwapOut The minimum amount of FLIP  to receive from the swap piece of the route
    * @dev Contract will only swap if `amountSwap > 0`. Contract will only mint if amountSwap < amountTotal.
     */
    function unstakeAggregate(uint256 amountInstantBurn, uint256 amountBurn, uint256 amountSwap, uint256 minimumAmountSwapOut) external returns (uint256) {
        uint256 total = amountInstantBurn + amountBurn + amountSwap;
        uint256 swapReceived;

        stflip.transferFrom(msg.sender, address(this), total);
        
        if (amountInstantBurn != 0) {
            uint256 instantBurnId = burner.burn(msg.sender, amountInstantBurn);
            burner.redeem(instantBurnId); 
        }

        if (amountBurn != 0) {
            burner.burn(msg.sender, amountBurn);
        }

        if (amountSwap != 0) {
            swapReceived = canonicalPool.exchange(1, 0, amountSwap, minimumAmountSwapOut, msg.sender);
        }

        emit BurnAggregation(msg.sender,amountInstantBurn, amountBurn, swapReceived);

        return amountInstantBurn + swapReceived;
    }

    /**
    * @notice Spends FLIP to mint and swap for stFLIP in the same transaction.
    * @param amountTotal The total amount of FLIP to spend.
    * @param amountSwap The amount of FLIP to swap for stFLIP.
    * @param minimumAmountSwapOut The minimum amount of stFLIP to receive from the swap piece of the route
    * @dev Contract will only swap if `amountSwap > 0`. Contract will only mint if amountSwap < amountTotal. 
    * Use `calculatePurchasable` on frontend to determine route prior to calling this.  
     */
    function stakeAggregate(uint256 amountTotal, uint256 amountSwap, uint256 minimumAmountSwapOut) external returns (uint256) {
        flip.transferFrom(msg.sender, address(this), amountTotal);
        uint256 swapReceived;
        uint256 mintAmount = amountTotal - amountSwap;

        if (amountSwap != 0){
            swapReceived = canonicalPool.exchange(0, 1, amountSwap, minimumAmountSwapOut, msg.sender);
        } 

        if (mintAmount != 0) {
            minter.mint(msg.sender, mintAmount);
        }

        emit StakeAggregation (msg.sender, swapReceived, mintAmount);
        
        return mintAmount + swapReceived;
    }


    /**
     * Public function for marginal cost
     * @param pool_ The pool to calculate the marginal cost for. If 0, uses the canonical pool
     * @param tokenIn The token index for the in token
     * @param tokenOut Token index for the out token
     * @param amount The unit to calculate at
     */
    function marginalCost(address pool_, int128 tokenIn, int128 tokenOut, uint256 amount) external view returns (uint256) {
        address pool = (pool_ == address(0)) ? address(canonicalPool) : pool_;
        return _marginalCost(pool, tokenIn, tokenOut, amount);
    }

    /**
    * @notice Calculates the marginal cost for the last unit of swap of `amount`
    * @param amount The size to calculate marginal cost for the last unit of swap
     */
    function _marginalCost(address pool, int128 tokenIn, int128 tokenOut, uint256 amount) internal view returns (uint256) {
        uint256 dx1 = amount;
        uint256 dx2 = amount + 10**18;

        uint256 amt1 = IStableSwap(pool).get_dy(tokenIn, tokenOut, dx1);
        uint256 amt2 = IStableSwap(pool).get_dy(tokenIn, tokenOut, dx2);

        return (amt2 - amt1)* 10**18 / (dx2 - dx1);
    }


    /**
     * @notice Calculates the total amount of stFLIP purchasable within targetError of a certain targetPrice
     * @param targetPrice The target price to calculate the amount of stFLIP purchasable until. 10**18 = 1
     * @param targetError The acceptable range around `targetPrice` for acceptable return value. 10**18 = 100%
     * @param attempts The number of hops within the binary search allowed before reverting
     * @dev Uses binary search. Must specify number of attempts to prevent infinite loop. This is not a perfect
     * calculation because the marginal cost is not exactly equal to dy. This is a decent approximation though
     * An analytical solution would be ideal but its not easy to get. This is accurate to 1bps, which is good enough
     * because most users are not going to be buying out the entire discount on their own. Even if they are, 1 bps +- is okay.
     * Some possible inaccuracies with very small pool sizes.
     */
    function calculatePurchasable(uint256 targetPrice, uint256 targetError, uint256 attempts, address pool_, int128 tokenIn, int128 tokenOut) external view returns (uint256) {   
        address pool = pool_ == address(0) ? address(canonicalPool) : pool_;
        uint256 first;
        uint256 mid;
        // this would be the absolute maximum of FLIP spendable, so we can start there
        uint256 last = IStableSwap(pool).balances(uint256(int256(tokenOut)));
        uint256 price;
        uint256 currentError = targetError;
        uint256 startPrice = _marginalCost(pool, tokenIn, tokenOut, 1*10**18);

        if (startPrice < targetPrice) {
            return 0;
        }

        while (true) {
            if (attempts == 0) {
                revert NoAttemptsLeft();
            }
            mid = (last+first) / 2;
            price = _marginalCost(pool, tokenIn, tokenOut, mid);
            if (price > targetPrice) {
                first = mid + 1;
            } else {
                last = mid - 1;
            }

            attempts = attempts - 1;

            if (price < targetPrice) {
                currentError = 10**18 - (price*10**18/targetPrice);
            } else {
                currentError = (price*10**18/targetPrice) - 10**18;
            }
 
            if (currentError < targetError) {
                return mid;
            }
        }
    }

    /**
     * @notice Change the canonical pool used in stakeAggregate/unstakeAggregate
     * @param pool_ Address of the new pool
     */
    function setPool(address pool_) external onlyRole(DEFAULT_ADMIN_ROLE) {

        if (address(canonicalPool) != address(0)) {
            flip.approve(address(canonicalPool), 0);
            stflip.approve(address(canonicalPool), 0);
        }

        canonicalPool = IStableSwap(pool_);

        flip.approve(address(canonicalPool), type(uint256).max);
        stflip.approve(address(canonicalPool), type(uint256).max);

        emit CanonicalPoolChanged(pool_);
    }

    function setFlip(address flip_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        flip = IERC20(flip_);
    }

    function setStflip(address stflip_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stflip = IERC20(stflip_);
    }
}
