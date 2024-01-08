// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./IEpochClock.sol";
import "./IERC20.sol";

contract SovWrapper is ReentrancyGuard {
    using SafeMath for uint256;

    // pool Information
    struct Pool {
        uint256 size;
        bool set;
    }

    // a checkpoint of the valid balance of a user for an epoch
    struct Checkpoint {
        uint128 epochId;
        uint128 multiplier;
        uint256 startBalance;
        uint256 newDeposits;
    }

    uint128 private constant BASE_MULTIPLIER = uint128(1 * 10**18);

    // timestamp for the epoch 1
    // everything before that is considered epoch 0 which won't have a reward but allows for the initial stake
    uint256 public epoch1Start;
    uint256 public epochDuration;

    // the DAO !
    address public reignDao;

    //balancer LP Token
    address public balancerLP;

    //max liquidation fee is 10%
    uint256 public maxLiquidationFee = 100000;

    //the router address is the only allowed to deposit/withdraw on behalf of users
    address public poolRouter;

    // las epoch a user has withdrawn
    uint128 public lastWithdrawEpochId;

    // the percentage fee the holder want's to get for liquidation, 6 decimals of precision
    mapping(address => uint256) public liquidationFee;

    // for each token, we store the total pool size
    mapping(uint256 => Pool) private poolSize;

    // holds the current balance of the user for each token
    mapping(address => uint256) private balances;

    // balanceCheckpoints[user][]
    mapping(address => Checkpoint[]) private balanceCheckpoints;

    // events
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    event Liquidate(
        address indexed liquidator,
        address indexed user,
        uint256 feeAmount,
        uint256 amount
    );

    event InitEpoch(address indexed caller, uint128 indexed epochId);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    modifier onlyRouter() {
        require(msg.sender == poolRouter, "Only Router can do this");
        _;
    }

    //empty constructor, could be removed but makes code more readable
    constructor() {}

    function initialize(
        address _epochClock,
        address _reignDao,
        address _balancerLP,
        address _poolRouter
    ) public {
        require(epoch1Start == 0, "Can only be initialized once"); //sufficient check
        epoch1Start = IEpochClock(_epochClock).getEpoch1Start();
        epochDuration = IEpochClock(_epochClock).getEpochDuration();
        reignDao = _reignDao;
        balancerLP = _balancerLP;
        poolRouter = _poolRouter;
    }

    /**
      Stores `amount`  tokens for the `lpOwner` into the vault
      If deposit is made with 0 amount it just updates the liquidation fee
     */
    function deposit(
        address lpOwner,
        uint256 amount,
        uint256 liquidationPremium
    ) public nonReentrant onlyRouter {
        require(
            liquidationPremium <= maxLiquidationFee,
            "Liquidation fee above max value"
        );
        liquidationFee[lpOwner] = liquidationPremium;

        if (amount > 0) {
            //pull LP tokens from router
            uint256 allowance =
                IERC20(balancerLP).allowance(msg.sender, address(this));
            require(allowance >= amount, "Wrapper: Token allowance too small");
            IERC20(balancerLP).transferFrom(msg.sender, address(this), amount);

            balances[lpOwner] = balances[lpOwner].add(amount);

            // epoch logic
            uint128 currentEpoch = getCurrentEpoch();
            uint128 currentMultiplier = currentEpochMultiplier();

            if (!epochIsInitialized(currentEpoch)) {
                initEpoch(currentEpoch);
            }

            // update the next epoch pool size
            Pool storage pNextEpoch = poolSize[currentEpoch + 1];
            pNextEpoch.size = IERC20(balancerLP).balanceOf(address(this));
            pNextEpoch.set = true;

            Checkpoint[] storage checkpoints = balanceCheckpoints[lpOwner];

            uint256 balanceBefore = getEpochUserBalance(lpOwner, currentEpoch);

            // if there's no checkpoint yet, it means the lpOwner didn't have any activity
            // we want to store checkpoints both for the current epoch and next epoch because
            // if a lpOwner does a withdraw, the current epoch can also be modified and
            // we don't want to insert another checkpoint in the middle of the array as that could be expensive
            if (checkpoints.length == 0) {
                checkpoints.push(
                    Checkpoint(currentEpoch, currentMultiplier, 0, amount)
                );

                // next epoch => multiplier is 1, epoch deposits is 0
                checkpoints.push(
                    Checkpoint(currentEpoch + 1, BASE_MULTIPLIER, amount, 0)
                );
            } else {
                uint256 last = checkpoints.length - 1;

                // the last action happened in an older epoch (e.g. a deposit in epoch 3, current epoch is >=5)
                if (checkpoints[last].epochId < currentEpoch) {
                    uint128 multiplier =
                        computeNewMultiplier(
                            getCheckpointBalance(checkpoints[last]),
                            BASE_MULTIPLIER,
                            amount,
                            currentMultiplier
                        );
                    checkpoints.push(
                        Checkpoint(
                            currentEpoch,
                            multiplier,
                            getCheckpointBalance(checkpoints[last]),
                            amount
                        )
                    );
                    checkpoints.push(
                        Checkpoint(
                            currentEpoch + 1,
                            BASE_MULTIPLIER,
                            balances[lpOwner],
                            0
                        )
                    );
                }
                // the last action happened in the current epoch
                else if (checkpoints[last].epochId == currentEpoch) {
                    checkpoints[last].multiplier = computeNewMultiplier(
                        getCheckpointBalance(checkpoints[last]),
                        checkpoints[last].multiplier,
                        amount,
                        currentMultiplier
                    );
                    checkpoints[last].newDeposits = checkpoints[last]
                        .newDeposits
                        .add(amount);

                    checkpoints.push(
                        Checkpoint(
                            currentEpoch + 1,
                            BASE_MULTIPLIER,
                            balances[lpOwner],
                            0
                        )
                    );
                }
                // the last action happened in the previous epoch
                else {
                    if (
                        last >= 1 &&
                        checkpoints[last - 1].epochId == currentEpoch
                    ) {
                        checkpoints[last - 1].multiplier = computeNewMultiplier(
                            getCheckpointBalance(checkpoints[last - 1]),
                            checkpoints[last - 1].multiplier,
                            amount,
                            currentMultiplier
                        );
                        checkpoints[last - 1].newDeposits = checkpoints[
                            last - 1
                        ]
                            .newDeposits
                            .add(amount);
                    }

                    checkpoints[last].startBalance = balances[lpOwner];
                }
            }

            uint256 balanceAfter = getEpochUserBalance(lpOwner, currentEpoch);

            poolSize[currentEpoch].size = poolSize[currentEpoch].size.add(
                balanceAfter.sub(balanceBefore)
            );
        }

        emit Deposit(lpOwner, amount);
    }

    /*
     * Wraps the withdraw function but emits a different event
     */
    function liquidate(
        address liquidator,
        address lpOwner,
        uint256 amount
    ) public nonReentrant onlyRouter {
        // withdraw lpOwnser's tokens to router
        _withdraw(lpOwner, amount);

        emit Liquidate(liquidator, lpOwner, liquidationFee[lpOwner], amount);
    }

    /*
     *  Withdraws the lp tokens from the lpOwner
     */
    function withdraw(address lpOwner, uint256 amount)
        public
        nonReentrant
        onlyRouter
    {
        _withdraw(lpOwner, amount);
    }

    /*
     * Removes the deposit of the user and sends the amount of `tokenAddress` back to the `lpOwner`
     */
    function _withdraw(address lpOwner, uint256 amount) internal {
        require(balances[lpOwner] >= amount, "Wrapper: balance too small");

        balances[lpOwner] = balances[lpOwner].sub(amount);

        // send LP to router contract
        IERC20 token = IERC20(balancerLP);
        token.transfer(msg.sender, amount);

        // epoch logic
        uint128 currentEpoch = getCurrentEpoch();

        lastWithdrawEpochId = currentEpoch;

        if (!epochIsInitialized(currentEpoch)) {
            initEpoch(currentEpoch);
        }

        // update the pool size of the next epoch to its current balance
        Pool storage pNextEpoch = poolSize[currentEpoch + 1];
        pNextEpoch.size = token.balanceOf(address(this));
        pNextEpoch.set = true;

        Checkpoint[] storage checkpoints = balanceCheckpoints[lpOwner];
        uint256 last = checkpoints.length - 1;

        // note: it's impossible to have a withdraw and no checkpoints because the balance would be 0 and revert

        // there was a deposit in an older epoch (more than 1 behind [eg: previous 0, now 5]) but no other action since then
        if (checkpoints[last].epochId < currentEpoch) {
            checkpoints.push(
                Checkpoint(currentEpoch, BASE_MULTIPLIER, balances[lpOwner], 0)
            );

            poolSize[currentEpoch].size = poolSize[currentEpoch].size.sub(
                amount
            );
        }
        // there was a deposit in the current epoch
        else if (checkpoints[last].epochId == currentEpoch) {
            checkpoints[last].startBalance = balances[lpOwner];
            checkpoints[last].newDeposits = 0;
            checkpoints[last].multiplier = BASE_MULTIPLIER;

            poolSize[currentEpoch].size = poolSize[currentEpoch].size.sub(
                amount
            );
        }
        // there was a deposit in the `epochId - 1` epoch => we have a checkpoint for the current epoch
        else {
            Checkpoint storage currentEpochCheckpoint = checkpoints[last - 1];

            uint256 balanceBefore =
                getCheckpointEffectiveBalance(currentEpochCheckpoint);

            // in case of withdraw, we have 2 branches:
            // 1. the lpOwner withdraws less than he added in the current epoch
            // 2. the lpOwner withdraws more than he added in the current epoch (including 0)
            if (amount < currentEpochCheckpoint.newDeposits) {
                uint128 avgDepositMultiplier =
                    uint128(
                        balanceBefore
                            .sub(currentEpochCheckpoint.startBalance)
                            .mul(BASE_MULTIPLIER)
                            .div(currentEpochCheckpoint.newDeposits)
                    );

                currentEpochCheckpoint.newDeposits = currentEpochCheckpoint
                    .newDeposits
                    .sub(amount);

                currentEpochCheckpoint.multiplier = computeNewMultiplier(
                    currentEpochCheckpoint.startBalance,
                    BASE_MULTIPLIER,
                    currentEpochCheckpoint.newDeposits,
                    avgDepositMultiplier
                );
            } else {
                currentEpochCheckpoint.startBalance = currentEpochCheckpoint
                    .startBalance
                    .sub(amount.sub(currentEpochCheckpoint.newDeposits));
                currentEpochCheckpoint.newDeposits = 0;
                currentEpochCheckpoint.multiplier = BASE_MULTIPLIER;
            }

            uint256 balanceAfter =
                getCheckpointEffectiveBalance(currentEpochCheckpoint);

            poolSize[currentEpoch].size = poolSize[currentEpoch].size.sub(
                balanceBefore.sub(balanceAfter)
            );

            checkpoints[last].startBalance = balances[lpOwner];
        }

        emit Withdraw(lpOwner, amount);
    }

    /*
     * initEpoch can be used by anyone to initialize an epoch based on the previous one
     * This is only applicable if there was no action (deposit/withdraw) in the current epoch.
     * Any deposit and withdraw will automatically initialize the current and next epoch.
     */
    function initEpoch(uint128 epochId) public {
        require(epochId <= getCurrentEpoch(), "can't init a future epoch");

        Pool storage p = poolSize[epochId];

        if (epochId == 0) {
            p.size = uint256(0);
            p.set = true;
        } else {
            require(
                !epochIsInitialized(epochId),
                "Wrapper: epoch already initialized"
            );
            require(
                epochIsInitialized(epochId - 1),
                "Wrapper: previous epoch not initialized"
            );

            p.size = poolSize[epochId - 1].size;
            p.set = true;
        }

        emit InitEpoch(msg.sender, epochId);
    }

    /**
        Allows anyone to take out the LP tokens if there have been no withdraws for 1o0 epochs
        This does not burn SOV as it is an emergency action
     */
    function emergencyWithdraw() public {
        require(
            (getCurrentEpoch() - lastWithdrawEpochId) >= 10,
            "At least 10 epochs must pass without success"
        );

        uint256 totalUserBalance = balances[msg.sender];
        require(totalUserBalance > 0, "Amount must be > 0");

        balances[msg.sender] = 0;

        IERC20 token = IERC20(balancerLP);
        token.transfer(msg.sender, totalUserBalance);

        emit EmergencyWithdraw(msg.sender, totalUserBalance);
    }

    /**
        Allows DAO to update max liquidation fee, does not affect existing positions
     */
    function setMaxLiquidationFee(uint256 newFee) public {
        require(msg.sender == reignDao, "Only DAO can call this");
        maxLiquidationFee = newFee;
    }

    /**
        Allows users to update their liquidation fee
     */
    function setLiquidationFee(uint256 value) public {
        require(value <= maxLiquidationFee, "Liquidation fee above max value");
        liquidationFee[msg.sender] = value;
    }

    /**
        VIEWS
     */

    /*
     * Returns the valid balance of a user that was taken into consideration in the total pool size for the epoch
     * A deposit will only change the next epoch balance.
     * A withdraw will decrease the current epoch (and subsequent) balance.
     */
    function getEpochUserBalance(address user, uint128 epochId)
        public
        view
        returns (uint256)
    {
        Checkpoint[] storage checkpoints = balanceCheckpoints[user];

        // if there are no checkpoints, it means the user never deposited any tokens, so the balance is 0
        if (checkpoints.length == 0 || epochId < checkpoints[0].epochId) {
            return 0;
        }

        uint256 min = 0;
        uint256 max = checkpoints.length - 1;

        // shortcut for blocks newer than the latest checkpoint == current balance
        if (epochId >= checkpoints[max].epochId) {
            return getCheckpointEffectiveBalance(checkpoints[max]);
        }

        // binary search of the value in the array
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (checkpoints[mid].epochId <= epochId) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }

        return getCheckpointEffectiveBalance(checkpoints[min]);
    }

    /*
     * Returns the amount of `token` that the `user` has currently staked
     */
    function balanceLocked(address user) public view returns (uint256) {
        return balances[user];
    }

    /*
     * Returns the id of the current epoch derived from block.timestamp
     */
    function getCurrentEpoch() public view returns (uint128) {
        if (block.timestamp < epoch1Start) {
            return 0;
        }

        return
            uint128(((block.timestamp - epoch1Start).div(epochDuration)) + 1);
    }

    /*
     * Returns the total amount of `tokenAddress` that was locked from beginning to end of epoch identified by `epochId`
     */
    function getEpochPoolSize(uint128 epochId) public view returns (uint256) {
        // Premises:
        // 1. it's impossible to have gaps of uninitialized epochs
        // - any deposit or withdraw initialize the current epoch which requires the previous one to be initialized
        if (epochIsInitialized(epochId)) {
            return poolSize[epochId].size;
        }

        // epochId not initialized and epoch 0 not initialized => there was never any action on this pool
        if (!epochIsInitialized(0)) {
            return 0;
        }

        // epoch 0 is initialized => there was an action at some point but none that initialized the epochId
        // which means the current pool size is equal to the current balance of token held by the staking contract
        IERC20 token = IERC20(balancerLP);
        return token.balanceOf(address(this));
    }

    /*
     * Returns the percentage of time left in the current epoch
     */
    function currentEpochMultiplier() public view returns (uint128) {
        uint128 currentEpoch = getCurrentEpoch();
        uint256 currentEpochEnd = epoch1Start + currentEpoch * epochDuration;
        uint256 timeLeft = currentEpochEnd - block.timestamp;
        uint128 multiplier =
            uint128((timeLeft * BASE_MULTIPLIER) / epochDuration);

        return multiplier;
    }

    function computeNewMultiplier(
        uint256 prevBalance,
        uint128 prevMultiplier,
        uint256 amount,
        uint128 currentMultiplier
    ) public pure returns (uint128) {
        uint256 prevAmount =
            prevBalance.mul(prevMultiplier).div(BASE_MULTIPLIER);
        uint256 addAmount = amount.mul(currentMultiplier).div(BASE_MULTIPLIER);
        uint128 newMultiplier =
            uint128(
                prevAmount.add(addAmount).mul(BASE_MULTIPLIER).div(
                    prevBalance.add(amount)
                )
            );

        return newMultiplier;
    }

    /*
     * Checks if an epoch is initialized, meaning we have a pool size set for it
     */
    function epochIsInitialized(uint128 epochId) public view returns (bool) {
        return poolSize[epochId].set;
    }

    function getCheckpointBalance(Checkpoint memory c)
        internal
        pure
        returns (uint256)
    {
        return c.startBalance.add(c.newDeposits);
    }

    function getCheckpointEffectiveBalance(Checkpoint memory c)
        internal
        pure
        returns (uint256)
    {
        return getCheckpointBalance(c).mul(c.multiplier).div(BASE_MULTIPLIER);
    }
}
