// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Bloodline.sol";
import "./IERC20.sol";
import "./ILiquidityOwner.sol";
import "./IRewardLocker.sol";
import "./IUniswapV3Pool.sol";
import "./IUniswapV2Pair.sol";

/// Attempt to access admin functionality from unauthorized address.
error NotAdmin();
/// LiquidityOwner initialization is one time action.
error LiquidityOwnerAlreadyInitialized();
/// Provided arrays must be the same length.
error ArraysHaveDifferentLength();
/// Meme cannot be removed, because it is not in a list.
error MemeIsNotInAList();
/// Uniswap V2 pool address cannot be switched for a not set meme.
error SwitchRequiresMemeBeSet();
/// Token is not accepted to be a sacrificable.
error TokenIsNotInSacrificableList();
/// Amount provided to be sacrificed equal 0.
error NothingToSacrifice();
/// Unfortunately, the uniswap pool `uniV2Pool` is out of liquidity.
error UniV2PoolWithoutLiquidity(address uniV2Pool);
/// Attempt to sell sacrificed meme resulted in receiving less ETH than was initially expected.
error InsufficientOutputAmount();
/// Reward did not registered.
error RewardRegistrationFailed();
/// Cycle completed did not registered.
error CycleCompletedRegistrationFailed();
/// Next cycle did not registered.
error NextCycleRegistrationFailed();
/// Liquidity Owner trigger call failed.
error LiquidityOwnerTriggerFailed();
/// Swaps entirely within 0-liquidity regions are not supported
error SwapWithinZeroLiquidity();
/// Attempt to call uniswap v3 swap callback.
error SwapCallbackCanBeCalledOnlyByPool();
/// Attempt to buy BDL resulted in receiving less BDL than was initially expected.
error TooLittleReceived();
/// Attempt to buy BDL resulted in requesting different WETH amount than was initially expected.
error NotExactInput();
/// Goal cannot be set to zero value, breaks invariants.
error GoalCannotBeZero();

/**
 * @title MemeAltar - Place, users come to sacrifice their meme tokens to and get
 *                    rewarded. Admin is able to add/remove meme tokens; adjust
 *                    default goal, cycle duration limit, reward defining points.
 */
contract MemeAltar {
    struct SacrificedMeme {
        uint112 achieved;
        bool cycleParticipant;
    }

    struct Cycle {
        uint112 goal;
        /// @notice total amount of ETH used to buy BDL from Uniswap v3 pool to recover the price in a cycle.
        uint112 ethUsedToBuy;
        uint32 expirationTimestamp;
        mapping(address => SacrificedMeme) sacrificedMemes;
    }

    /*//////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/
    event NewAdmin(address indexed newAdmin);

    event MemeAddedToSacrificableList(
        uint256 indexed cycleNumber, address indexed meme, address indexed memeMarket
    );

    event MemeRemovedFromSacrificableList(uint256 indexed cycleNumber, address indexed meme);

    event NewDefaultCycleGoal(uint256 indexed newDefaultGoal);

    event NewCycleDurationLimit(uint256 indexed newDurationLimit);

    event NewBM(uint64 indexed b, uint64 indexed m);

    event MemeSacrificed(
        address indexed sacrificer,
        address indexed sacrificedToken,
        uint256 indexed sacrificedAmount
    );

    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev The minimum sqrt price value. Equivalent to MIN_TICK = -887200.
    uint160 internal constant MIN_SQRT_RATIO = 4_310_618_293;
    /// @dev The maximum sqrt price value. Equivalent to MAX_TICK = 887200.
    uint160 internal constant MAX_SQRT_RATIO =
        1_456_195_216_270_955_103_206_513_029_158_776_779_468_408_838_535;

    /*//////////////////////////////////////////////////////////////
                        MEME ALTAR STORAGE
    //////////////////////////////////////////////////////////////*/
    /// @notice Contract WETH9 - ERC20 Wrapped Ether.
    address public weth;
    /// @notice ERC20 which is a reward token.
    Bloodline public bloodline;
    /// @notice Uniswap V3 pool: WETH and Bloodline.
    address public uniV3Pool;
    /// @notice Contract that stores the rewards and is triggered when cycle is completed.
    address public rewardLocker;
    /// @notice Contract that stores weth (weth is transfered to) and provides liquidity.
    address public liquidityOwner;
    /// @notice Address, which is allowed to call onlyAdmin functions.
    address public admin;

    /// @notice The number of the current cycle.
    uint112 public currentCycle = 1;
    /// @notice The value used as a cycle goal, if no cycle goal was set.
    uint112 public defaultGoal;
    /// @notice Cycle completes without a winner after this duration limit is expired.
    uint32 public cycleDurationLimit = 7 days;
    /// @notice Stores the data related to the cycles.
    /// @dev cycleNumber -> Cycle struct
    mapping(uint112 => Cycle) public cycles;
    /// @notice Stores uniswap v2 pair (WETH-Meme) addresses.
    /// @dev meme -> uniV2 pair
    mapping(address => address) public memesUniV2Pools;
    /// @notice Stores a list of meme addresses, which are sacrificable in a next cycle.
    address[] public memeList;
    /// @notice y-intercept of linear functions, which defines the reward factor.
    uint64 public b = 95;
    /// @notice Slope of linear functions, which defines the reward factor.
    uint64 public m = 30;
    /// @notice a ratio between BLOOD token and ETH, used as a base to calculate reward.
    uint128 public issuancePrice = 32_000;

    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert NotAdmin();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor sets storage values, initialize rewardLocker, registers first cycle.
     * @param sacrificableList an array of ERC20 meme addresses, which are sacrificable.
     * @param uniV2pools an array of uniswap v2 pair (WETH-Meme) addresses related to list above.
     * @param _weth WETH9 (ERC20 Wrapped Ether) contract address.
     * @param _admin address, which is allowed to adjust memeList, defaultGoal, cycle duration limit, BM.
     * @param _rewardLocker RewardLocker contract address.
     * @param _bloodline ERC20 reward token address.
     * @param _devLiquidityHolder Receiver of minted 3% BLOOD developer fee.
     * @param _defaultGoal a cycle goal competitors have to achieve, denominated in ETH.
     */
    constructor(
        address[] memory sacrificableList,
        address[] memory uniV2pools,
        address _weth,
        address _admin,
        address _rewardLocker,
        address _bloodline,
        address _devLiquidityHolder,
        uint112 _defaultGoal
    ) {
        if (sacrificableList.length != uniV2pools.length) {
            revert ArraysHaveDifferentLength();
        }

        weth = _weth;
        defaultGoal = _defaultGoal;
        admin = _admin;
        rewardLocker = _rewardLocker;
        memeList = sacrificableList;
        bloodline = Bloodline(_bloodline);
        uniV3Pool = bloodline.uniV3Pool();

        Cycle storage cycle = cycles[1];
        cycle.expirationTimestamp = uint32(block.timestamp) + 7 days;
        cycle.goal = _defaultGoal;

        for (uint256 i = 0; i < sacrificableList.length; i++) {
            memesUniV2Pools[sacrificableList[i]] = uniV2pools[i];
            SacrificedMeme storage meme = cycle.sacrificedMemes[sacrificableList[i]];
            meme.cycleParticipant = true;
            emit MemeAddedToSacrificableList(currentCycle, sacrificableList[i], uniV2pools[i]);
        }

        IRewardLocker(_rewardLocker).init(address(this), _bloodline, _devLiquidityHolder);
        IRewardLocker(_rewardLocker).registerNextCycle(currentCycle, sacrificableList);
    }

    /**
     * @notice Method initialize liquidityOwner.
     * @param _liquidityOwner address of LiquidityOwner contract.
     */
    function setLiquidityOwner(address _liquidityOwner) external {
        if (liquidityOwner != address(0)) {
            revert LiquidityOwnerAlreadyInitialized();
        }
        liquidityOwner = _liquidityOwner;
    }

    /*//////////////////////////////////////////////////////////////
                        ADMINISTRATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Method switches `admin` to 'newAdmin' admin address.
     * @param newAdmin address of new admin.
     * @return True
     */
    function switchAdmin(address newAdmin) external onlyAdmin returns (bool) {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
        return true;
    }

    /**
     * @notice Method adds new meme token to a list of sacrificable tokens.
     *         Applied in the next cycles.
     * @param meme address of meme token, which will become sacrificable in next cycles.
     * @param uniV2Pool uniswap v2 pair (WETH-Meme) address.
     * @return True
     */
    function addMemeToList(
        address meme,
        address uniV2Pool
    )
        external
        onlyAdmin
        returns (bool)
    {
        memesUniV2Pools[meme] = uniV2Pool;

        uint256 lastSacrificableIndex = memeList.length - 1;
        while (memesUniV2Pools[memeList[lastSacrificableIndex]] == address(0)) {
            lastSacrificableIndex--;
        }

        memeList.push(meme);

        if (lastSacrificableIndex != memeList.length - 2) {
            // need to replace
            memeList[memeList.length - 1] = memeList[lastSacrificableIndex + 1];
            memeList[lastSacrificableIndex + 1] = meme;
        }

        emit MemeAddedToSacrificableList(currentCycle + 1, meme, uniV2Pool);
        return true;
    }

    /**
     * @notice Method removes meme token from a list of sacrificable tokens.
     *         Applied in the next cycles.
     * @param meme address of meme token, which is not sacrificable in next cycles.
     * @return True
     */
    function removeMemeFromList(address meme) external onlyAdmin returns (bool) {
        // define last sacrificable index
        uint256 lastSacrificableIndex = memeList.length - 1;
        while (memesUniV2Pools[memeList[lastSacrificableIndex]] == address(0)) {
            lastSacrificableIndex--;
        }
        if (memeList[lastSacrificableIndex] != meme) {
            // try to find array index
            uint256 indexId;
            for (uint256 index = 0; index < lastSacrificableIndex + 1; index++) {
                if (memeList[index] == meme) {
                    indexId = index;
                    break;
                }
            }
            // check if element exist
            if (memeList[indexId] != meme) {
                revert MemeIsNotInAList();
            }
            // replace last
            memeList[indexId] = memeList[lastSacrificableIndex];
            memeList[lastSacrificableIndex] = meme;
        }

        memesUniV2Pools[meme] = address(0);
        emit MemeRemovedFromSacrificableList(currentCycle, meme);
        return true;
    }

    /**
     * @notice Method replaces meme uniswap v2 pool to new one.
     *         Applied immidiately.
     * @param meme address of meme token, which pool should be switched.
     * @param newUniV2Pool uniswap v2 pair (WETH-Meme) address.
     * @return True
     */
    function switchUniV2Pool(
        address meme,
        address newUniV2Pool
    )
        external
        onlyAdmin
        returns (bool)
    {
        if (memesUniV2Pools[meme] == address(0)) {
            revert SwitchRequiresMemeBeSet();
        }
        memesUniV2Pools[meme] = newUniV2Pool;
        return true;
    }

    /// @notice Method adjust y-intercept and slope of linear functions. Applied immidiately.
    function adjustBM(uint64 newB, uint64 newM) external onlyAdmin returns (bool) {
        b = newB;
        m = newM;
        emit NewBM(newB, newM);
        return true;
    }

    /**
     * @notice Method adjust default goal value. Applied in the next cycles.
     * @param newDefaultGoal new value of a default goal.
     * @return True
     */
    function adjustDefaultGoal(uint112 newDefaultGoal) external onlyAdmin returns (bool) {
        if (newDefaultGoal == uint112(0)) {
            revert GoalCannotBeZero();
        }
        defaultGoal = newDefaultGoal;
        emit NewDefaultCycleGoal(newDefaultGoal);
        return true;
    }

    /**
     * @notice Method adjust cycles duration limit. Applied in the next cycles.
     * @param newDurationLimit duration in seconds.
     * @return True
     */
    function adjustCycleDurationLimit(uint32 newDurationLimit)
        external
        onlyAdmin
        returns (bool)
    {
        cycleDurationLimit = newDurationLimit;
        emit NewCycleDurationLimit(newDurationLimit);
        return true;
    }

    /*//////////////////////////////////////////////////////////////
              SACRIFICE LOGIC: sacrificeMeme and internals
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Method sacrifices `memeToSacrifice` tokens and rewards with Bloodline tokens.
     *         `memeToSacrifice` token preapproval is required.
     * @param memeToSacrifice address of meme token from the sacrificable list.
     * @param amountToSacrifice amount of sacrificable meme token to be sacrificed.
     * @param minETH minimum amount of ETH to receive for selling meme.
     * @return reward amount for sacrificing in Bloodline tokens.
     */
    function sacrificeMeme(
        address memeToSacrifice,
        uint256 amountToSacrifice,
        uint112 minETH
    )
        external
        returns (uint128 reward)
    {
        if (amountToSacrifice == 0) {
            revert NothingToSacrifice();
        }
        Cycle storage cycle = cycles[currentCycle];
        if (!cycle.sacrificedMemes[memeToSacrifice].cycleParticipant) {
            revert TokenIsNotInSacrificableList();
        }

        uint112 amountOfWETH = _sellToUniV2(memeToSacrifice, amountToSacrifice, minETH);
        uint112 amountWithoutDevFee = amountOfWETH * 97 / 100;

        // calculate reward
        bool cycleCompleted;
        uint112 extraAmount;
        (reward, extraAmount, cycleCompleted) =
            _calculateRewardFor(memeToSacrifice, amountWithoutDevFee);

        if (!IRewardLocker(rewardLocker).registerReward(msg.sender, memeToSacrifice, reward)) {
            revert RewardRegistrationFailed();
        }

        if (cycleCompleted) {
            if (
                !IRewardLocker(rewardLocker).registerCycleCompleted(
                    currentCycle, memeToSacrifice
                )
            ) {
                revert CycleCompletedRegistrationFailed();
            }
        }

        if (!cycleCompleted && cycle.expirationTimestamp <= block.timestamp) {
            // complete cycle without winner
            if (!IRewardLocker(rewardLocker).registerCycleCompleted(currentCycle, address(0)))
            {
                revert CycleCompletedRegistrationFailed();
            }
        }

        if (cycleCompleted || cycle.expirationTimestamp <= block.timestamp) {
            (uint112 nextCycleNumber, uint112 collectedEthInCycle) =
                _registerCycleCompleted(cycle);

            if (!IRewardLocker(rewardLocker).registerNextCycle(nextCycleNumber, memeList)) {
                revert NextCycleRegistrationFailed();
            }

            issuancePrice =
                uint128(ILiquidityOwner(liquidityOwner).provideLiquidity(collectedEthInCycle));

            // cover extra amount
            if (extraAmount > 0) {
                reward += _handleExtraAmount(memeToSacrifice, extraAmount);
            }
        }

        // ask liquidity owner to pay developer fee
        ILiquidityOwner(liquidityOwner).payDeveloperFee(amountOfWETH - amountWithoutDevFee);

        emit MemeSacrificed(msg.sender, memeToSacrifice, amountToSacrifice);
    }

    /// @notice sells meme `memeToSell` token to `uniV2Pool` uniswap v2 pool for ETH.
    function _sellToUniV2(
        address memeToSell,
        uint256 amountToSell,
        uint112 minETH
    )
        internal
        returns (uint112)
    {
        address uniV2Pool = memesUniV2Pools[memeToSell];
        if (uniV2Pool == address(0)) {
            revert TokenIsNotInSacrificableList();
        }
        bool token0 = memeToSell < weth;
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(uniV2Pool).getReserves();

        if (reserve0 == 0 || reserve1 == 0) {
            revert UniV2PoolWithoutLiquidity(uniV2Pool);
        }

        uint256 amountInWithFee = amountToSell * 997;
        uint256 numerator = amountInWithFee * (token0 ? reserve1 : reserve0);
        uint256 denominator = amountInWithFee + ((token0 ? reserve0 : reserve1) * 1000);
        uint256 amountOut = numerator / denominator;

        if (minETH > amountOut) {
            revert InsufficientOutputAmount();
        }

        // transfer tokens directly from msg.sender to uniswapV2 pool
        /// @dev requires memeToSacrifice transferFrom returns bool.
        require(IERC20(memeToSell).transferFrom(msg.sender, uniV2Pool, amountToSell));

        // make a swap, transfer ETH to LiquidityOwner
        token0
            ? IUniswapV2Pair(uniV2Pool).swap(0, amountOut, liquidityOwner, "")
            : IUniswapV2Pair(uniV2Pool).swap(amountOut, 0, liquidityOwner, "");

        return uint112(amountOut);
    }

    /**
     * @notice Calculates reward amount based on a cycle goal, ETH received for
     *         selling meme tokens and this `memeToSacrifice` token previous achievements.
     * @param memeToSacrifice address of meme token from the sacrificable list.
     * @param amountOfWETH ETH amount received for selling, minus developer fee.
     * @return reward calculated amount of BLOOD tokens.
     * @return extraAmount If amountOfWETH is enough to complete two cycles in a row,
     *         only one cycle is completed, next cycle achieved is set 95%, extra amount is returned in meme.
     * @return cycleCompleted True, if amount of ETH was enough to reach a cycle goal.
     */
    function _calculateRewardFor(
        address memeToSacrifice,
        uint112 amountOfWETH
    )
        internal
        returns (uint128 reward, uint112 extraAmount, bool cycleCompleted)
    {
        Cycle storage cycle = cycles[currentCycle];
        SacrificedMeme storage sacrificedMeme = cycle.sacrificedMemes[memeToSacrifice];

        uint112 achievement = amountOfWETH;
        if (sacrificedMeme.achieved + amountOfWETH >= cycle.goal) {
            achievement = cycle.goal - sacrificedMeme.achieved;
            extraAmount = amountOfWETH - achievement;
            cycleCompleted = true;
        }

        reward = _calculateReward(cycle.goal, sacrificedMeme.achieved, achievement);
        sacrificedMeme.achieved += achievement;
    }

    /// @notice general function to calculate reward
    function _calculateReward(
        uint256 goal,
        uint256 achieved,
        uint256 amount
    )
        internal
        view
        returns (uint128)
    {
        return
            uint128(_calculateTripleLinearReward(goal, achieved, amount, issuancePrice, b, m));
    }

    /// @notice Sets current cycle, defines total collected ETH in a completed cycle,
    /// removes removed memes from a meme list, sets expiration timestamp, goal, and participants in a coming cycle.
    function _registerCycleCompleted(Cycle storage cycleCompleted)
        internal
        returns (uint112 nextCycleNumber, uint112 ethCollectedInCycle)
    {
        // storage write
        currentCycle += 1;
        nextCycleNumber = currentCycle;

        Cycle storage cycleComing = cycles[nextCycleNumber];
        uint256 numberOfMemes = memeList.length;
        bool sacrificable = false;
        // loop through a list of completed cycle memes
        for (uint256 i = numberOfMemes; i > 0; i--) {
            address meme = memeList[i - 1];
            SacrificedMeme storage memeCompletedCycle = cycleCompleted.sacrificedMemes[meme];
            // add meme ETH achievement to totalCollectedETH in a completed cycle
            ethCollectedInCycle += memeCompletedCycle.achieved;
            // remove from list memes, which were removed by admin
            if (!sacrificable) {
                if (memesUniV2Pools[meme] == address(0)) {
                    memeList.pop();
                } else {
                    sacrificable = true;
                }
            }
            // set as participants in coming cycle all sacrificable memes (all not removed and newly added memes by admin)
            if (sacrificable) {
                SacrificedMeme storage memeComingCycle = cycleComing.sacrificedMemes[meme];
                memeComingCycle.cycleParticipant = true;
            }
        }
        // subtract ETH used to buy BLOOD from totalCollectedETH in a completed cycle
        ethCollectedInCycle -= cycleCompleted.ethUsedToBuy;

        // set coming cycle state
        cycleComing.expirationTimestamp = uint32(block.timestamp) + cycleDurationLimit;
        cycleComing.goal = defaultGoal;
    }

    /// @notice Handle extra ETH over required to complete cycle.
    /// Returns extra reward, which is registered for a next cycle, if meme is its participant.
    //  Buys meme back, if meme is not participant or extra amount is enough to complete next cycle (complete two cycles in 1 tx is dissalowed).
    function _handleExtraAmount(
        address meme,
        uint112 extraAmount
    )
        internal
        returns (uint128 extraReward)
    {
        // no extraReward, if extraAmount is less than gas cost spent on extraReward
        if (extraAmount < 100_000 * (tx.gasprice > 120 gwei ? 120 gwei : tx.gasprice)) {
            return extraReward;
        }
        // check meme participant in coming cycle
        Cycle storage cycle = cycles[currentCycle];
        SacrificedMeme storage sacrificedMeme = cycle.sacrificedMemes[meme];
        if (sacrificedMeme.cycleParticipant) {
            uint112 achievement = extraAmount;
            if (extraAmount >= cycle.goal) {
                // consume only 95%
                achievement = cycle.goal * 95 / 100;
                _buyBack(extraAmount - achievement, meme);
            }
            extraReward = _calculateReward(cycle.goal, sacrificedMeme.achieved, achievement);
            // storage write
            sacrificedMeme.achieved += achievement;
            if (!IRewardLocker(rewardLocker).registerReward(msg.sender, meme, extraReward)) {
                revert RewardRegistrationFailed();
            }
        } else {
            _buyBack(extraAmount, meme);
        }
    }

    /// @notice Expected to be a rare case. Buys sacrificed meme tokens back and returns them to msg.sender.
    ///  Case 1. Amount received from selling was bigger than required to complete cycle and sacrificed meme is not a participant in next cycle.
    ///  Case 2. Amount received from selling was bigger than required to complete two cycles in a row.
    function _buyBack(uint256 extraAmount, address memeToBuy) internal {
        bool token0 = memeToBuy < weth;
        address uniV2Pool = memesUniV2Pools[memeToBuy];
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(uniV2Pool).getReserves();

        uint256 amountInWithFee = extraAmount * 997;
        uint256 numerator = amountInWithFee * (token0 ? reserve0 : reserve1);
        uint256 denominator = amountInWithFee + ((token0 ? reserve1 : reserve0) * 1000);
        uint256 amountOut = numerator / denominator;

        ILiquidityOwner(liquidityOwner).payWETHToUniswapPool(uniV2Pool, extraAmount);

        // make a swap and transfer tokens directly to sacrificer
        token0
            ? IUniswapV2Pair(uniV2Pool).swap(amountOut, 0, msg.sender, "")
            : IUniswapV2Pair(uniV2Pool).swap(0, amountOut, msg.sender, "");
    }

    /*//////////////////////////////////////////////////////////////
        SACRIFICE LOGIC: sacrificeMemeAndBuyBLOOD and internals
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Method sacrifice `memeToSacrifice` tokens and buys Bloodline reward tokens
     *         from Uniswap V3 pool to maximize user profit and to recover the price, burns bought amount and register
     *         the same reward amount for a user in a current cycle, increases meme cycle achievements.
     *         `memeToSacrifice` token preapproval is required.
     * @param memeToSacrifice address of meme token from the sacrificable list.
     * @param amountToSacrifice amount of sacrificeable meme token to be sacrificed.
     * @param minBLOOD minimum amount of BDL, which should be received by buying from a pool (includes slippage - calculated on frontend side).
     * @return reward amount of the default reward for sacrificing in Bloodline tokens.
     */
    function sacrificeMemeAndBuyBLOOD(
        address memeToSacrifice,
        uint256 amountToSacrifice,
        uint256 minBLOOD
    )
        external
        returns (uint256 reward)
    {
        if (amountToSacrifice == 0) {
            revert NothingToSacrifice();
        }
        Cycle storage cycle = cycles[currentCycle];
        if (!cycle.sacrificedMemes[memeToSacrifice].cycleParticipant) {
            revert TokenIsNotInSacrificableList();
        }
        // set minETH 0, because we have minBLOOD protecting against sandwitch attack, which implicitly includes a minETH value - no need to double check
        uint112 amountOfWETH = _sellToUniV2(memeToSacrifice, amountToSacrifice, 0);
        uint112 amountWithoutDevFee = amountOfWETH * 97 / 100;

        // buy BLOOD from Uniswap v3
        reward = _buyBloodline(amountWithoutDevFee, minBLOOD);

        (bool cycleCompleted, uint256 burnAmount, uint256 transferAmount) =
            _increaseAchievedCompareGoal(memeToSacrifice, amountWithoutDevFee, reward, cycle);

        // burn BLOOD received from a pool to register it as a reward
        require(bloodline.burn(burnAmount));

        if (transferAmount > 0) {
            // transfer extra BLOOD bought for ETH over required to complete cycle
            bloodline.transfer(msg.sender, transferAmount);
        }

        // register reward
        if (
            !IRewardLocker(rewardLocker).registerReward(msg.sender, memeToSacrifice, burnAmount)
        ) {
            revert RewardRegistrationFailed();
        }

        if (cycleCompleted) {
            if (
                !IRewardLocker(rewardLocker).registerCycleCompleted(
                    currentCycle, memeToSacrifice
                )
            ) {
                revert CycleCompletedRegistrationFailed();
            }
        }

        if (!cycleCompleted && cycle.expirationTimestamp <= block.timestamp) {
            // complete cycle without winner
            if (!IRewardLocker(rewardLocker).registerCycleCompleted(currentCycle, address(0)))
            {
                revert CycleCompletedRegistrationFailed();
            }
        }

        if (cycleCompleted || cycle.expirationTimestamp <= block.timestamp) {
            (uint112 nextCycleNumber, uint112 collectedEthInCycle) =
                _registerCycleCompleted(cycle);

            if (!IRewardLocker(rewardLocker).registerNextCycle(nextCycleNumber, memeList)) {
                revert NextCycleRegistrationFailed();
            }

            issuancePrice =
                uint128(ILiquidityOwner(liquidityOwner).provideLiquidity(collectedEthInCycle));
        }

        // ask liquidity owner to pay developer fee
        ILiquidityOwner(liquidityOwner).payDeveloperFee(amountOfWETH - amountWithoutDevFee);

        emit MemeSacrificed(msg.sender, memeToSacrifice, amountToSacrifice);
    }

    function _buyBloodline(
        uint256 ethIn,
        uint256 minBDLOut
    )
        internal
        returns (uint256 bdlOut)
    {
        bytes memory callbackData = abi.encode(ethIn, minBDLOut);
        bool wethToken0 = weth < address(bloodline);
        (int256 amount0, int256 amount1) = IUniswapV3Pool(uniV3Pool).swap(
            address(this),
            wethToken0,
            int256(ethIn),
            wethToken0 ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
            callbackData
        );

        bdlOut = wethToken0 ? uint256(-amount1) : uint256(-amount0);
    }

    /// @notice Adds ETH to meme achievements, defines if cycle is completed,
    /// based on result defines amounts of BLOOD to burn and to transfer to sacrificer.
    function _increaseAchievedCompareGoal(
        address meme,
        uint112 amountOfWETH,
        uint256 reward,
        Cycle storage cycle
    )
        internal
        returns (bool cycleCompleted, uint256 burnAmount, uint256 transferAmount)
    {
        SacrificedMeme storage sacrificedMeme = cycle.sacrificedMemes[meme];
        uint112 achievement = amountOfWETH;
        if (sacrificedMeme.achieved + amountOfWETH >= cycle.goal) {
            achievement = cycle.goal - sacrificedMeme.achieved;
            cycleCompleted = true;
            burnAmount = reward * achievement / amountOfWETH;
            transferAmount = reward - burnAmount;
        } else {
            burnAmount = reward;
        }
        // storage writes
        sacrificedMeme.achieved += achievement;
        cycle.ethUsedToBuy += achievement;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice View method returns meme token participation and already achieved
     *         amount on its way to a cycle `cycleNumber` goal.
     * @param cycleNumber token data is requested for.
     * @param meme address of a meme token, data is requested for.
     * @return participation True, if token is eligable participant in a cycle `cycleNumber`.
     * @return amountAchieved amount in ETH, achived already on a token way to a cycle goal.
     */
    function getSacrificedMeme(
        uint112 cycleNumber,
        address meme
    )
        external
        view
        returns (bool participation, uint256 amountAchieved)
    {
        Cycle storage cycle = cycles[cycleNumber];
        SacrificedMeme storage sacrificedMeme = cycle.sacrificedMemes[meme];
        participation = sacrificedMeme.cycleParticipant;
        amountAchieved = sacrificedMeme.achieved;
    }

    /**
     * @notice View method returns giving reward amount for sacrificing this amount
     *         `amountToSacrifice` of this `memeToSacrifice` meme token now (time/action sensitive data).
     * @param memeToSacrifice address of meme token from the sacrificable list.
     * @param amountToSacrifice amount of sacrificable meme token to calculate current reward for.
     * @return rewardCurrentCycle reward amount for sacrificing in Bloodline tokens in current cycle.
     * @return rewardNextCycle reward amount for sacrificing in Bloodline tokens in next cycle (not accurate, as doesn't consider issuancePrice adjustments).
     */
    function getRewardForSacrifice(
        address memeToSacrifice,
        uint256 amountToSacrifice
    )
        external
        view
        returns (uint256 rewardCurrentCycle, uint256 rewardNextCycle)
    {
        Cycle storage cycle = cycles[currentCycle];
        SacrificedMeme storage sacrificedMeme = cycle.sacrificedMemes[memeToSacrifice];
        (uint256 amountETHBase,) = getAmountETHBase(
            memeToSacrifice, amountToSacrifice, sacrificedMeme.cycleParticipant
        );
        rewardCurrentCycle =
            _calculateReward(cycle.goal, sacrificedMeme.achieved, amountETHBase);
        if (amountETHBase > cycle.goal - sacrificedMeme.achieved) {
            uint256 amountForCurrentCycle = cycle.goal - sacrificedMeme.achieved;
            rewardCurrentCycle =
                _calculateReward(cycle.goal, sacrificedMeme.achieved, amountForCurrentCycle);
            amountETHBase -= amountForCurrentCycle;
            if (amountETHBase >= defaultGoal) {
                amountETHBase = defaultGoal * 95 / 100;
            }
            rewardNextCycle = _calculateReward(defaultGoal, 0, amountETHBase);
        }
    }

    /**
     * @notice View method returns useful amount of ETH for sacrificing this amount
     *         `amountToSacrifice` of this `memeToSacrifice` meme token now (time/action sensitive data).
     *         Useful ETH is an ETH, which is used as a base to calculate reward or buy BLOOD from Uniswap V3 Pool, amount excludes developer fee.
     * @param memeToSacrifice address of meme token from the sacrificable list.
     * @param amountToSacrifice amount of sacrificable meme token to calculate current reward for.
     * @param cycleParticipant True, if meme token is participant of current cycle.
     */
    function getAmountETHBase(
        address memeToSacrifice,
        uint256 amountToSacrifice,
        bool cycleParticipant
    )
        public
        view
        returns (uint256 amountETHBase, uint256 amountETHForSelling)
    {
        bool token0 = memeToSacrifice < weth;
        address uniV2Pool = memesUniV2Pools[memeToSacrifice];

        if (uniV2Pool == address(0)) {
            return (amountETHBase, amountETHForSelling);
        }

        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(uniV2Pool).getReserves();

        if (!cycleParticipant || (reserve0 == 0 || reserve1 == 0)) {
            return (amountETHBase, amountETHForSelling);
        }

        uint256 amountInWithFee = amountToSacrifice * 997;
        uint256 numerator = amountInWithFee * (token0 ? reserve1 : reserve0);
        uint256 denominator = amountInWithFee + ((token0 ? reserve0 : reserve1) * 1000);
        amountETHForSelling = numerator / denominator;
        amountETHBase = amountETHForSelling * 97 / 100;
    }

    /// @notice Returns a cycle `cycleNumber` goal denominated in BLOOD (reward) tokens.
    function getGoalInBLOOD(uint112 cycleNumber) external view returns (uint256) {
        Cycle storage cycle = cycles[cycleNumber];
        if (cycle.goal == uint112(0)) {
            return 0;
        }
        return _calculateReward(cycle.goal, 0, cycle.goal);
    }

    /**
     * @notice View method returns required amount of meme `memeToSacrifice` token
     *         to sacrifice to complete cycle.
     * @param memeToSacrifice address of meme token from the sacrificable list.
     */
    function getAmountToReachGoal(address memeToSacrifice) public view returns (uint256) {
        Cycle storage cycle = cycles[currentCycle];
        SacrificedMeme storage sacrificedMeme = cycle.sacrificedMemes[memeToSacrifice];
        if (!sacrificedMeme.cycleParticipant) {
            return 0;
        }
        bool token0 = memeToSacrifice < weth;
        address uniV2Pool = memesUniV2Pools[memeToSacrifice];
        if (uniV2Pool == address(0)) {
            return 0;
        }
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(uniV2Pool).getReserves();

        if (reserve0 == 0 || reserve1 == 0) {
            return 0;
        }

        uint256 amountOut = 1 + ((cycle.goal - sacrificedMeme.achieved) * 100 / 97);
        uint256 numerator = amountOut * 1000 * (token0 ? reserve0 : reserve1);
        uint256 denominator = ((token0 ? reserve1 : reserve0) - amountOut) * 997;
        uint256 amountIn = (numerator / denominator) + 1;

        return amountIn;
    }

    /*//////////////////////////////////////////////////////////////
                  REWARD CALCULATION INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Triple LINEAR function. 3 lines - 3 sectors.
    /// sector 1: 0-5% goal range. decreasing line.
    /// sector 2: 5-95% goal range. straight line.
    /// sector 3: 95%-100% goal range. increasing line.
    /// @dev b = 95, m = 30 -> mints 96.5% - 3.5% deflation against issuancePrice.
    /// @dev rewardFactors must be divided by 10 ** 18 after multiplied by price and amount
    function _calculateTripleLinearReward(
        uint256 goal,
        uint256 achieved,
        uint256 amount,
        uint256 price,
        uint256 _b,
        uint256 _m
    )
        internal
        pure
        returns (uint256 reward)
    {
        // start and finish points can be in same or different sectors.
        uint256 startPoint = achieved * 100 / goal;
        uint256 finishPoint = (achieved + amount) * 100 / goal;

        uint256 rewardFactor;
        uint256 tempGoal = 5 * goal / 100;
        uint256 tempAmount = amount;

        if (startPoint < 5) {
            if (finishPoint >= 5) {
                // start: sector 1. finish: sector 2, sector 3.
                // fully filled 0-5% goal range, add reward for that, move to next sector.
                tempAmount = tempGoal - achieved;
                amount -= tempAmount;
                rewardFactor = (_b + _m) * 10 ** 16
                    - (_m * 10 ** 16 * (achieved + (achieved + tempAmount)) / tempGoal)
                        / uint256(2);
                reward += rewardFactor * tempAmount * price / 10 ** 18;
                achieved += tempAmount;
            } else {
                // start: sector 1. finish: sector 1.
                // return reward for a partially filling 0-5% goal range.
                rewardFactor = (_b + _m) * 10 ** 16
                    - (_m * 10 ** 16 * (achieved + (achieved + tempAmount)) / tempGoal)
                        / uint256(2);
                reward += rewardFactor * tempAmount * price / 10 ** 18;
                return reward;
            }
        }

        if (finishPoint < 95) {
            // start: sector 1, sector 2. finish: sector 2.
            // return reward for a partially filling 5-95% goal range.
            rewardFactor = _b * 10 ** 16;
            reward += rewardFactor * amount * price / 10 ** 18;
            return reward;
        } else if (startPoint < 95) {
            // start: sector 1, sector 2. finish: sector 3.
            // fully filled 5-95% goal range, add reward, move to next sector.
            tempGoal = 95 * goal / 100;
            tempAmount = tempGoal - achieved;
            amount -= tempAmount;
            achieved += tempAmount;
            rewardFactor = _b * 10 ** 16;
            reward += rewardFactor * tempAmount * price / 10 ** 18;
        }
        // start: sector 1, sector 2, sector 3. finish: sector 3.
        // fully or partially fill 95%-100% goal range, add reward.
        achieved -= 95 * goal / 100;
        tempGoal = 5 * goal / 100;
        rewardFactor = _b * 10 ** 16
            + (_m * 10 ** 16 * (achieved + (achieved + amount)) / tempGoal) / uint256(2);
        reward += rewardFactor * amount * price / 10 ** 18;
    }

    /*//////////////////////////////////////////////////////////////
                                CALLBACKS
    //////////////////////////////////////////////////////////////*/

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    )
        external
    {
        if (amount0Delta <= 0 && amount1Delta <= 0) {
            revert SwapWithinZeroLiquidity();
        }
        if (msg.sender != uniV3Pool) {
            revert SwapCallbackCanBeCalledOnlyByPool();
        }

        (uint256 ethIn, uint256 minBDLOut) = abi.decode(_data, (uint256, uint256));
        (bool isExactInput, uint256 amountToPay, uint256 amountReceived) = amount0Delta > 0
            ? (weth < address(bloodline), uint256(amount0Delta), uint256(-amount1Delta))
            : (address(bloodline) < weth, uint256(amount1Delta), uint256(-amount0Delta));

        // check input amount
        if (!isExactInput || amountToPay != ethIn) {
            revert NotExactInput();
        }
        // check the output amount
        if (amountReceived < minBDLOut) {
            revert TooLittleReceived();
        }
        // transfer eth to univ3 pool
        ILiquidityOwner(liquidityOwner).payWETHToUniswapPool(msg.sender, amountToPay);
    }
}
