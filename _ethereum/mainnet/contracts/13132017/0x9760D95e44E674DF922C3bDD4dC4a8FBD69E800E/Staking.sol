// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;

import "./SafeMathUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./EnumerableSetUpgradeable.sol";

import "./IToken.sol";
import "./IAuction.sol";
import "./IStaking.sol";
import "./IStakingV1.sol";

contract Staking is IStaking, Initializable, AccessControlUpgradeable {
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /** Events */
    event Stake(
        address indexed account,
        uint256 indexed sessionId,
        uint256 amount,
        uint256 start,
        uint256 end,
        uint256 shares
    );

    event MaxShareUpgrade(
        address indexed account,
        uint256 indexed sessionId,
        uint256 amount,
        uint256 newAmount,
        uint256 shares,
        uint256 newShares,
        uint256 start,
        uint256 end
    );

    event Unstake(
        address indexed account,
        uint256 indexed sessionId,
        uint256 amount,
        uint256 start,
        uint256 end,
        uint256 shares
    );

    event MakePayout(
        uint256 indexed value,
        uint256 indexed sharesTotalSupply,
        uint256 indexed time
    );

    event DailyBurn(
        uint256 indexed value,
        uint256 indexed totalSupply,
        uint256 indexed time
    );

    event AccountRegistered(
        address indexed account,
        uint256 indexed totalShares
    );

    event WithdrawLiquidDiv(
        address indexed account,
        address indexed tokenAddress,
        uint256 indexed interest
    );

    /** Structs */
    struct Payout {
        uint256 payout;
        uint256 sharesTotalSupply;
    }

    struct Session {
        uint256 amount;
        uint256 start;
        uint256 end;
        uint256 shares;
        uint256 firstPayout;
        uint256 lastPayout;
        bool withdrawn;
        uint256 payout;
    }

    struct Addresses {
        address mainToken;
        address auction;
        address subBalances;
    }

    struct BPDPool {
        uint96[5] pool;
        uint96[5] shares;
    }
    struct BPDPool128 {
        uint128[5] pool;
        uint128[5] shares;
    }

    Addresses public addresses;
    IStakingV1 public stakingV1;

    /** Roles */
    bytes32 public constant MIGRATOR_ROLE = keccak256('MIGRATOR_ROLE');
    bytes32 public constant EXTERNAL_STAKER_ROLE =
        keccak256('EXTERNAL_STAKER_ROLE');
    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');

    /** Public Variables */
    uint256 public shareRate; //shareRate used to calculate the number of shares
    uint256 public sharesTotalSupply; //total shares supply
    uint256 public nextPayoutCall; //used to calculate when the daily makePayout() should run
    uint256 public stepTimestamp; // 24h * 60 * 60
    uint256 public startContract; //time the contract started
    uint256 public globalPayout;
    uint256 public globalPayin;
    uint256 public lastSessionId; //the ID of the last stake
    uint256 public lastSessionIdV1; //the ID of the last stake from layer 1 staking contract

    /** Mappings / Arrays */
    // individual staking sessions
    mapping(address => mapping(uint256 => Session)) public sessionDataOf;
    //array with staking sessions of an address
    mapping(address => uint256[]) public sessionsOf;
    //array with daily payouts
    Payout[] public payouts;

    /** Booleans */
    bool public init_;

    uint256 public basePeriod; //350 days, time of the first BPD
    uint256 public totalStakedAmount; //total amount of staked AXN

    bool private maxShareEventActive; //true if maxShare upgrade is enabled

    uint16 private maxShareMaxDays; //maximum number of days a stake length can be in order to qualify for maxShare upgrade
    uint256 private shareRateScalingFactor; //scaling factor, default 1 to be used on the shareRate calculation

    uint256 internal totalVcaRegisteredShares; //total number of shares from accounts that registered for the VCA

    mapping(address => uint256) internal tokenPricePerShare; //price per share for every token that is going to be offered as divident through the VCA
    EnumerableSetUpgradeable.AddressSet internal divTokens; //list of dividends tokens

    //keep track if an address registered for VCA
    mapping(address => bool) internal isVcaRegistered;
    //total shares of active stakes for an address
    mapping(address => uint256) internal totalSharesOf;
    //mapping address-> VCA token used for VCA divs calculation. The way the system works is that deductBalances is starting as totalSharesOf x price of the respective token. So when the token price appreciates, the interest earned is the difference between totalSharesOf x new price - deductBalance [respective token]
    mapping(address => mapping(address => uint256)) internal deductBalances;

    bool internal paused;

    BPDPool bpd;
    BPDPool128 bpd128;
    /* New variables must go below here. */

    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, _msgSender()), 'Caller is not a manager');
        _;
    }

    modifier onlyMigrator() {
        require(
            hasRole(MIGRATOR_ROLE, _msgSender()),
            'Caller is not a migrator'
        );
        _;
    }

    modifier onlyExternalStaker() {
        require(
            hasRole(EXTERNAL_STAKER_ROLE, _msgSender()),
            'Caller is not a external staker'
        );
        _;
    }

    modifier pausable() {
        require(
            paused == false || hasRole(MIGRATOR_ROLE, _msgSender()),
            'Contract is paused'
        );
        _;
    }

    function initialize(address _manager, address _migrator)
        public
        initializer
    {
        _setupRole(MANAGER_ROLE, _manager);
        _setupRole(MIGRATOR_ROLE, _migrator);
        init_ = false;
    }

    // @param account {address} - address of account
    function sessionsOf_(address account)
        external
        view
        returns (uint256[] memory)
    {
        return sessionsOf[account];
    }

    //staking function which receives AXN and creates the stake - takes as param the amount of AXN and the number of days to be staked
    //staking days need to be >0 and lower than max days which is 5555
    // @param amount {uint256} - AXN amount to be staked
    // @param stakingDays {uint256} - number of days to be staked
    function stake(uint256 amount, uint256 stakingDays) external pausable {
        require(stakingDays != 0, 'Staking: Staking days < 1');
        require(stakingDays <= 5555, 'Staking: Staking days > 5555');

        //call stake internal method
        stakeInternal(amount, stakingDays, msg.sender);
        //on stake axion gets burned
        IToken(addresses.mainToken).burn(msg.sender, amount);
    }

    //external stake creates a stake for a different account than the caller. It takes an extra param the staker address
    // @param amount {uint256} - AXN amount to be staked
    // @param stakingDays {uint256} - number of days to be staked
    // @param staker {address} - account address to create the stake for
    function externalStake(
        uint256 amount,
        uint256 stakingDays,
        address staker
    ) external override onlyExternalStaker pausable {
        require(stakingDays != 0, 'Staking: Staking days < 1');
        require(stakingDays <= 5555, 'Staking: Staking days > 5555');

        stakeInternal(amount, stakingDays, staker);
    }

    // @param amount {uint256} - AXN amount to be staked
    // @param stakingDays {uint256} - number of days to be staked
    // @param staker {address} - account address to create the stake for
    function stakeInternal(
        uint256 amount,
        uint256 stakingDays,
        address staker
    ) internal {
        //once a day we need to call makePayout which takes the interest earned for the last day and adds it into the payout array
        if (now >= nextPayoutCall) makePayout();

        //ensure the user is registered for VCA if not call it
        if (isVcaRegistered[staker] == false)
            setTotalSharesOfAccountInternal(staker);

        //time of staking start is now
        uint256 start = now;
        //time of stake end is now + number of days * stepTimestamp which is 24 hours
        uint256 end = now.add(stakingDays.mul(stepTimestamp));

        //increase the last stake ID
        lastSessionId = lastSessionId.add(1);

        stakeInternalCommon(
            lastSessionId,
            amount,
            start,
            end,
            stakingDays,
            payouts.length,
            staker
        );
    }

    //payment function uses param address and amount to be paid. Amount is minted to address
    // @param to {address} - account address to send the payment to
    // @param amount {uint256} - AXN amount to be paid
    function _initPayout(address to, uint256 amount) internal {
        IToken(addresses.mainToken).mint(to, amount);
        // globalPayout = globalPayout.add(amount);
    }

    //staking interest calculation goes through the payout array and calculates the interest based on the number of shares the user has and the payout for every day
    // @param firstPayout {uint256} - id of the first day of payout for the stake
    // @param lastPayout {uint256} - id of the last day of payout for the stake
    // @param shares {uint256} - number of shares of the stake
    function calculateStakingInterest(
        uint256 firstPayout,
        uint256 lastPayout,
        uint256 shares
    ) public view returns (uint256) {
        uint256 stakingInterest;
        //calculate lastIndex as minimum of lastPayout from stake session and current day (payouts.length).
        uint256 lastIndex = MathUpgradeable.min(payouts.length, lastPayout);

        for (uint256 i = firstPayout; i < lastIndex; i++) {
            uint256 payout =
                payouts[i].payout.mul(shares).div(payouts[i].sharesTotalSupply);

            stakingInterest = stakingInterest.add(payout);
        }

        return stakingInterest;
    }

    //unstake function
    // @param sessionID {uint256} - id of the stake
    function unstake(uint256 sessionId) external pausable {
        Session storage session = sessionDataOf[msg.sender][sessionId];

        //ensure the stake hasn't been withdrawn before
        require(
            session.shares != 0 && session.withdrawn == false,
            'Staking: Stake withdrawn or not set'
        );

        uint256 actualEnd = now;
        //calculate the amount the stake earned; to be paid
        uint256 amountOut = unstakeInternal(session, sessionId, actualEnd);

        // To account
        _initPayout(msg.sender, amountOut);
    }

    //unstake function for layer1 stakes
    // @param sessionID {uint256} - id of the layer 1 stake
    function unstakeV1(uint256 sessionId) external pausable {
        //lastSessionIdv1 is the last stake ID from v1 layer
        require(sessionId <= lastSessionIdV1, 'Staking: Invalid sessionId');

        Session storage session = sessionDataOf[msg.sender][sessionId];

        // Unstaked already
        require(
            session.shares == 0 && session.withdrawn == false,
            'Staking: Stake withdrawn'
        );

        (
            uint256 amount,
            uint256 start,
            uint256 end,
            uint256 shares,
            uint256 firstPayout
        ) = stakingV1.sessionDataOf(msg.sender, sessionId);

        // Unstaked in v1 / doesn't exist
        require(shares != 0, 'Staking: Stake withdrawn or not set');

        uint256 stakingDays = (end - start) / stepTimestamp;
        uint256 lastPayout = stakingDays + firstPayout;

        uint256 actualEnd = now;
        //calculate amount to be paid
        uint256 amountOut =
            unstakeV1Internal(
                sessionId,
                amount,
                start,
                end,
                actualEnd,
                shares,
                firstPayout,
                lastPayout
            );

        // To account
        _initPayout(msg.sender, amountOut);
    }

    //calculate the amount the stake earned and any penalty because of early/late unstake
    // @param amount {uint256} - amount of AXN staked
    // @param start {uint256} - start date of the stake
    // @param end {uint256} - end date of the stake
    // @param stakingInterest {uint256} - interest earned of the stake
    function getAmountOutAndPenalty(
        uint256 amount,
        uint256 start,
        uint256 end,
        uint256 stakingInterest
    ) public view returns (uint256, uint256) {
        uint256 stakingSeconds = end.sub(start);
        uint256 stakingDays = stakingSeconds.div(stepTimestamp);
        uint256 secondsStaked = now.sub(start);
        uint256 daysStaked = secondsStaked.div(stepTimestamp);
        uint256 amountAndInterest = amount.add(stakingInterest);

        // Early
        if (stakingDays > daysStaked) {
            uint256 payOutAmount =
                amountAndInterest.mul(secondsStaked).div(stakingSeconds);

            uint256 earlyUnstakePenalty = amountAndInterest.sub(payOutAmount);

            return (payOutAmount, earlyUnstakePenalty);
            // In time
        } else if (daysStaked < stakingDays.add(14)) {
            return (amountAndInterest, 0);
            // Late
        } else if (daysStaked < stakingDays.add(714)) {
            return (amountAndInterest, 0);
            /** Remove late penalties for now */
            // uint256 daysAfterStaking = daysStaked - stakingDays;

            // uint256 payOutAmount =
            //     amountAndInterest.mul(uint256(714).sub(daysAfterStaking)).div(
            //         700
            //     );

            // uint256 lateUnstakePenalty = amountAndInterest.sub(payOutAmount);

            // return (payOutAmount, lateUnstakePenalty);

            // Nothing
        } else {
            return (0, amountAndInterest);
        }
    }

    //makePayout function runs once per day and takes all the AXN earned as interest and puts it into payout array for the day
    function makePayout() public {
        require(now >= nextPayoutCall, 'Staking: Wrong payout time');

        uint256 payout = _getPayout();

        payouts.push(
            Payout({payout: payout, sharesTotalSupply: sharesTotalSupply})
        );

        nextPayoutCall = nextPayoutCall.add(stepTimestamp);

        //call updateShareRate once a day as sharerate increases based on the daily Payout amount
        updateShareRate(payout);

        emit MakePayout(payout, sharesTotalSupply, now);
    }

    function _getPayout() internal returns (uint256) {
        //amountTokenInDay - AXN from auction buybacks goes into the staking contract
        uint256 amountTokenInDay =
            IERC20Upgradeable(addresses.mainToken).balanceOf(address(this));
        IERC20Upgradeable(addresses.mainToken).transfer(
            0x000000000000000000000000000000000000dEaD,
            amountTokenInDay
        ); // Send to dead address
        uint256 balanceOfDead =
            IERC20Upgradeable(addresses.mainToken).balanceOf(
                0x000000000000000000000000000000000000dEaD
            );

        uint256 currentTokenTotalSupply =
            (IERC20Upgradeable(addresses.mainToken).totalSupply());

        //we add 8% inflation
        uint256 inflation =
            uint256(8)
                .mul(
                currentTokenTotalSupply.sub(balanceOfDead).add(
                    totalStakedAmount
                )
            )
                .div(36500);

        emit DailyBurn(amountTokenInDay, currentTokenTotalSupply, now);
        return inflation;
    }

    // formula for shares calculation given a number of AXN and a start and end date
    // @param amount {uint256} - amount of AXN
    // @param start {uint256} - start date of the stake
    // @param end {uint256} - end date of the stake
    function _getStakersSharesAmount(
        uint256 amount,
        uint256 start,
        uint256 end
    ) internal view returns (uint256) {
        uint256 stakingDays = (end.sub(start)).div(stepTimestamp);
        uint256 numerator = amount.mul(uint256(1819).add(stakingDays));
        uint256 denominator = uint256(1820).mul(shareRate);

        return (numerator).mul(1e18).div(denominator);
    }

    // @param amount {uint256} - amount of AXN
    // @param shares {uint256} - number of shares
    // @param start {uint256} - start date of the stake
    // @param end {uint256} - end date of the stake
    // @param stakingInterest {uint256} - interest earned by the stake
    function _getShareRate(
        uint256 amount,
        uint256 shares,
        uint256 start,
        uint256 end,
        uint256 stakingInterest
    ) internal view returns (uint256) {
        uint256 stakingDays = (end.sub(start)).div(stepTimestamp);

        uint256 numerator =
            (amount.add(stakingInterest)).mul(uint256(1819).add(stakingDays));

        uint256 denominator = uint256(1820).mul(shares);

        return (numerator).mul(1e18).div(denominator);
    }

    //takes a matures stake and allows restake instead of having to withdraw the axn and stake it back into another stake
    //restake will take the principal + interest earned + allow a topup
    // @param sessionID {uint256} - id of the stake
    // @param stakingDays {uint256} - number of days to be staked
    // @param topup {uint256} - amount of AXN to be added as topup to the stake
    function restake(
        uint256 sessionId,
        uint256 stakingDays,
        uint256 topup
    ) external pausable {
        require(stakingDays != 0, 'Staking: Staking days < 1');
        require(stakingDays <= 5555, 'Staking: Staking days > 5555');

        Session storage session = sessionDataOf[msg.sender][sessionId];

        require(
            session.shares != 0 && session.withdrawn == false,
            'Staking: Stake withdrawn/invalid'
        );

        uint256 actualEnd = now;

        require(session.end <= actualEnd, 'Staking: Stake not mature');

        uint256 amountOut = unstakeInternal(session, sessionId, actualEnd);

        if (topup != 0) {
            IToken(addresses.mainToken).burn(msg.sender, topup);
            amountOut = amountOut.add(topup);
        }

        stakeInternal(amountOut, stakingDays, msg.sender);
    }

    //same as restake but for layer 1 stakes
    // @param sessionID {uint256} - id of the stake
    // @param stakingDays {uint256} - number of days to be staked
    // @param topup {uint256} - amount of AXN to be added as topup to the stake
    function restakeV1(
        uint256 sessionId,
        uint256 stakingDays,
        uint256 topup
    ) external pausable {
        require(sessionId <= lastSessionIdV1, 'Staking: Invalid sessionId');
        require(stakingDays != 0, 'Staking: Staking days < 1');
        require(stakingDays <= 5555, 'Staking: Staking days > 5555');

        Session storage session = sessionDataOf[msg.sender][sessionId];

        require(
            session.shares == 0 && session.withdrawn == false,
            'Staking: Stake withdrawn'
        );

        (
            uint256 amount,
            uint256 start,
            uint256 end,
            uint256 shares,
            uint256 firstPayout
        ) = stakingV1.sessionDataOf(msg.sender, sessionId);

        // Unstaked in v1 / doesn't exist
        require(shares != 0, 'Staking: Stake withdrawn');

        uint256 actualEnd = now;

        require(end <= actualEnd, 'Staking: Stake not mature');

        uint256 sessionStakingDays = (end - start) / stepTimestamp;
        uint256 lastPayout = sessionStakingDays + firstPayout;

        uint256 amountOut =
            unstakeV1Internal(
                sessionId,
                amount,
                start,
                end,
                actualEnd,
                shares,
                firstPayout,
                lastPayout
            );

        if (topup != 0) {
            IToken(addresses.mainToken).burn(msg.sender, topup);
            amountOut = amountOut.add(topup);
        }

        stakeInternal(amountOut, stakingDays, msg.sender);
    }

    // @param session {Session} - session of the stake
    // @param sessionId {uint256} - id of the stake
    // @param actualEnd {uint256} - the date when the stake was actually been unstaked
    function unstakeInternal(
        Session storage session,
        uint256 sessionId,
        uint256 actualEnd
    ) internal returns (uint256) {
        uint256 amountOut =
            unstakeInternalCommon(
                sessionId,
                session.amount,
                session.start,
                session.end,
                actualEnd,
                session.shares,
                session.firstPayout,
                session.lastPayout
            );

        session.end = actualEnd;
        session.withdrawn = true;
        session.payout = amountOut;

        return amountOut;
    }

    // @param sessionID {uint256} - id of the stake
    // @param amount {uint256} - amount of AXN
    // @param start {uint256} - start date of the stake
    // @param end {uint256} - end date of the stake
    // @param actualEnd {uint256} - actual end date of the stake
    // @param shares {uint256} - number of stares of the stake
    // @param firstPayout {uint256} - id of the first payout for the stake
    // @param lastPayout {uint256} - if of the last payout for the stake
    // @param stakingDays {uint256} - number of staking days
    function unstakeV1Internal(
        uint256 sessionId,
        uint256 amount,
        uint256 start,
        uint256 end,
        uint256 actualEnd,
        uint256 shares,
        uint256 firstPayout,
        uint256 lastPayout
    ) internal returns (uint256) {
        uint256 amountOut =
            unstakeInternalCommon(
                sessionId,
                amount,
                start,
                end,
                actualEnd,
                shares,
                firstPayout,
                lastPayout
            );

        sessionDataOf[msg.sender][sessionId] = Session({
            amount: amount,
            start: start,
            end: actualEnd,
            shares: shares,
            firstPayout: firstPayout,
            lastPayout: lastPayout,
            withdrawn: true,
            payout: amountOut
        });

        sessionsOf[msg.sender].push(sessionId);

        return amountOut;
    }

    // @param sessionID {uint256} - id of the stake
    // @param amount {uint256} - amount of AXN
    // @param start {uint256} - start date of the stake
    // @param end {uint256} - end date of the stake
    // @param actualEnd {uint256} - actual end date of the stake
    // @param shares {uint256} - number of stares of the stake
    // @param firstPayout {uint256} - id of the first payout for the stake
    // @param lastPayout {uint256} - if of the last payout for the stake
    function unstakeInternalCommon(
        uint256 sessionId,
        uint256 amount,
        uint256 start,
        uint256 end,
        uint256 actualEnd,
        uint256 shares,
        uint256 firstPayout,
        uint256 lastPayout
    ) internal returns (uint256) {
        if (now >= nextPayoutCall) makePayout();
        if (isVcaRegistered[msg.sender] == false)
            setTotalSharesOfAccountInternal(msg.sender);

        uint256 stakingInterest =
            calculateStakingInterest(firstPayout, lastPayout, shares);

        sharesTotalSupply = sharesTotalSupply.sub(shares);
        totalStakedAmount = totalStakedAmount.sub(amount);
        totalVcaRegisteredShares = totalVcaRegisteredShares.sub(shares);

        uint256 oldTotalSharesOf = totalSharesOf[msg.sender];
        totalSharesOf[msg.sender] = totalSharesOf[msg.sender].sub(shares);

        rebalance(msg.sender, oldTotalSharesOf);

        (uint256 amountOut, uint256 penalty) =
            getAmountOutAndPenalty(amount, start, end, stakingInterest);

        // add bpd to amount amountOut if stakingDays >= basePeriod
        uint256 stakingDays = (actualEnd - start) / stepTimestamp;
        if (stakingDays >= basePeriod) {
            // We use "Actual end" so that if a user tries to withdraw their BPD early they don't get the shares
            uint256 bpdAmount =
                calcBPD(start, actualEnd < end ? actualEnd : end, shares);
            amountOut = amountOut.add(bpdAmount);
        }

        // To auction
        // if (penalty != 0) {
        //     _initPayout(addresses.auction, penalty);
        //     IAuction(addresses.auction).callIncomeDailyTokensTrigger(penalty);
        // }

        emit Unstake(
            msg.sender,
            sessionId,
            amountOut,
            start,
            actualEnd,
            shares
        );

        return amountOut;
    }

    // @param sessionID {uint256} - id of the stake
    // @param amount {uint256} - amount of AXN
    // @param start {uint256} - start date of the stake
    // @param end {uint256} - end date of the stake
    // @param stakingDays {uint256} - number of staking days
    // @param firstPayout {uint256} - id of the first payout for the stake
    // @param lastPayout {uint256} - if of the last payout for the stake
    // @param staker {address} - address of the staker account
    function stakeInternalCommon(
        uint256 sessionId,
        uint256 amount,
        uint256 start,
        uint256 end,
        uint256 stakingDays,
        uint256 firstPayout,
        address staker
    ) internal {
        uint256 shares = _getStakersSharesAmount(amount, start, end);

        sharesTotalSupply = sharesTotalSupply.add(shares);
        totalStakedAmount = totalStakedAmount.add(amount);
        totalVcaRegisteredShares = totalVcaRegisteredShares.add(shares);

        uint256 oldTotalSharesOf = totalSharesOf[staker];
        totalSharesOf[staker] = totalSharesOf[staker].add(shares);

        rebalance(staker, oldTotalSharesOf);

        sessionDataOf[staker][sessionId] = Session({
            amount: amount,
            start: start,
            end: end,
            shares: shares,
            firstPayout: firstPayout,
            lastPayout: firstPayout + stakingDays,
            withdrawn: false,
            payout: 0
        });

        sessionsOf[staker].push(sessionId);

        // add shares to bpd pool
        addBPDShares(shares, start, end);

        emit Stake(staker, sessionId, amount, start, end, shares);
    }

    //function to withdraw the dividends earned for a specific token
    // @param tokenAddress {address} - address of the dividend token
    function withdrawDivToken(address tokenAddress) external {
        withdrawDivTokenInternal(tokenAddress, totalSharesOf[msg.sender]);
    }

    function withdrawDivTokenInternal(
        address tokenAddress,
        uint256 _totalSharesOf
    ) internal {
        uint256 tokenInterestEarned =
            getTokenInterestEarnedInternal(
                msg.sender,
                tokenAddress,
                _totalSharesOf
            );

        // after dividents are paid we need to set the deductBalance of that token to current token price * total shares of the account
        deductBalances[msg.sender][tokenAddress] = totalSharesOf[msg.sender]
            .mul(tokenPricePerShare[tokenAddress]);

        /** 0xFF... is our ethereum placeholder address */
        if (
            tokenAddress != address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF)
        ) {
            IERC20Upgradeable(tokenAddress).transfer(
                msg.sender,
                tokenInterestEarned
            );
        } else {
            msg.sender.transfer(tokenInterestEarned);
        }

        emit WithdrawLiquidDiv(msg.sender, tokenAddress, tokenInterestEarned);
    }

    //calculate the interest earned by an address for a specific dividend token
    // @param accountAddress {address} - address of account
    // @param tokenAddress {address} - address of the dividend token
    function getTokenInterestEarned(
        address accountAddress,
        address tokenAddress
    ) external view returns (uint256) {
        return
            getTokenInterestEarnedInternal(
                accountAddress,
                tokenAddress,
                totalSharesOf[accountAddress]
            );
    }

    // @param accountAddress {address} - address of account
    // @param tokenAddress {address} - address of the dividend token
    function getTokenInterestEarnedInternal(
        address accountAddress,
        address tokenAddress,
        uint256 _totalSharesOf
    ) internal view returns (uint256) {
        return
            _totalSharesOf
                .mul(tokenPricePerShare[tokenAddress])
                .sub(deductBalances[accountAddress][tokenAddress])
                .div(10**36); //we divide since we multiplied the price by 10**36 for precision
    }

    //the rebalance function recalculates the deductBalances of an user after the total number of shares changes as a result of a stake/unstake
    // @param staker {address} - address of account
    // @param oldTotalSharesOf {uint256} - previous number of shares for the account
    function rebalance(address staker, uint256 oldTotalSharesOf) internal {
        for (uint8 i = 0; i < divTokens.length(); i++) {
            uint256 tokenInterestEarned =
                oldTotalSharesOf.mul(tokenPricePerShare[divTokens.at(i)]).sub(
                    deductBalances[staker][divTokens.at(i)]
                );

            if (
                totalSharesOf[staker].mul(tokenPricePerShare[divTokens.at(i)]) <
                tokenInterestEarned
            ) {
                withdrawDivTokenInternal(divTokens.at(i), oldTotalSharesOf);
            } else {
                deductBalances[staker][divTokens.at(i)] = totalSharesOf[staker]
                    .mul(tokenPricePerShare[divTokens.at(i)])
                    .sub(tokenInterestEarned);
            }
        }
    }

    //registration function that sets the total number of shares for an account and inits the deductBalances
    // @param account {address} - address of account
    function setTotalSharesOfAccountInternal(address account)
        internal
        pausable
    {
        require(
            isVcaRegistered[account] == false ||
                hasRole(MIGRATOR_ROLE, msg.sender),
            'STAKING: Account already registered.'
        );

        uint256 totalShares;
        //pull the layer 2 staking sessions for the account
        uint256[] storage sessionsOfAccount = sessionsOf[account];

        for (uint256 i = 0; i < sessionsOfAccount.length; i++) {
            if (sessionDataOf[account][sessionsOfAccount[i]].withdrawn)
                //make sure the stake is active; not withdrawn
                continue;

            totalShares = totalShares.add( //sum total shares
                sessionDataOf[account][sessionsOfAccount[i]].shares
            );
        }

        //pull stakes from layer 1
        uint256[] memory v1SessionsOfAccount = stakingV1.sessionsOf_(account);

        for (uint256 i = 0; i < v1SessionsOfAccount.length; i++) {
            if (sessionDataOf[account][v1SessionsOfAccount[i]].shares != 0)
                //make sure the stake was not withdran.
                continue;

            if (v1SessionsOfAccount[i] > lastSessionIdV1) continue; //make sure we only take layer 1 stakes in consideration

            (
                uint256 amount,
                uint256 start,
                uint256 end,
                uint256 shares,
                uint256 firstPayout
            ) = stakingV1.sessionDataOf(account, v1SessionsOfAccount[i]);

            (amount);
            (start);
            (end);
            (firstPayout);

            if (shares == 0) continue;

            totalShares = totalShares.add(shares); //calclate total shares
        }

        isVcaRegistered[account] = true; //confirm the registration was completed

        if (totalShares != 0) {
            totalSharesOf[account] = totalShares;
            totalVcaRegisteredShares = totalVcaRegisteredShares.add( //update the global total number of VCA registered shares
                totalShares
            );

            //init deductBalances with the present values
            for (uint256 i = 0; i < divTokens.length(); i++) {
                deductBalances[account][divTokens.at(i)] = totalShares.mul(
                    tokenPricePerShare[divTokens.at(i)]
                );
            }
        }

        emit AccountRegistered(account, totalShares);
    }

    //function to allow anyone to call the registration of another address
    // @param _address {address} - address of account
    function setTotalSharesOfAccount(address _address) external {
        setTotalSharesOfAccountInternal(_address);
    }

    //function that will update the price per share for a dividend token. it is called from within the auction contract as a result of a venture auction bid
    // @param bidderAddress {address} - the address of the bidder
    // @param originAddress {address} - the address of origin/dev fee
    // @param tokenAddress {address} - the divident token address
    // @param amountBought {uint256} - the amount in ETH that was bid in the auction
    function updateTokenPricePerShare(
        address payable bidderAddress,
        address payable originAddress,
        address tokenAddress,
        uint256 amountBought
    ) external payable override onlyExternalStaker {
        if (tokenAddress != addresses.mainToken) {
            tokenPricePerShare[tokenAddress] = tokenPricePerShare[tokenAddress]
                .add(amountBought.mul(10**36).div(totalVcaRegisteredShares)); //increase the token price per share with the amount bought divided by the total Vca registered shares
        }
    }

    //add a new dividend token
    // @param tokenAddress {address} - dividend token address
    function addDivToken(address tokenAddress)
        external
        override
        onlyExternalStaker
    {
        if (
            !divTokens.contains(tokenAddress) &&
            tokenAddress != addresses.mainToken
        ) {
            //make sure the token is not already added
            divTokens.add(tokenAddress);
        }
    }

    //function to increase the share rate price
    //the update happens daily and used the amount of AXN sold through regular auction to calculate the amount to increase the share rate with
    // @param _payout {uint256} - amount of AXN that was bought back through the regular auction
    function updateShareRate(uint256 _payout) internal {
        uint256 currentTokenTotalSupply =
            IERC20Upgradeable(addresses.mainToken).totalSupply();

        uint256 growthFactor =
            _payout.mul(1e18).div(
                currentTokenTotalSupply + totalStakedAmount + 1 //we calculate the total AXN supply as circulating + staked
            );

        if (shareRateScalingFactor == 0) {
            //use a shareRateScalingFactor which can be set in order to tune the speed of shareRate increase
            shareRateScalingFactor = 1;
        }

        shareRate = shareRate
            .mul(1e18 + shareRateScalingFactor.mul(growthFactor)) //1e18 used for precision.
            .div(1e18);
    }

    //function to set the shareRateScalingFactor
    // @param _scalingFactor {uint256} - scaling factor number
    function setShareRateScalingFactor(uint256 _scalingFactor)
        external
        onlyManager
    {
        shareRateScalingFactor = _scalingFactor;
    }

    //function that allows a stake to be upgraded to a stake with a length of 5555 days without incuring any penalties
    //the function takes the current earned interest and uses the principal + interest to create a new stake
    //for v2 stakes it's only updating the current existing stake info, it's not creating a new stake
    // @param sessionId {uint256} - id of the staking session
    function maxShare(uint256 sessionId) external pausable {
        Session storage session = sessionDataOf[msg.sender][sessionId];

        require(
            session.shares != 0 && session.withdrawn == false,
            'STAKING: Stake withdrawn or not set'
        );

        (
            uint256 newStart,
            uint256 newEnd,
            uint256 newAmount,
            uint256 newShares
        ) =
            maxShareUpgrade(
                session.firstPayout,
                session.lastPayout,
                session.shares,
                session.amount
            );

        addBPDMaxShares(
            session.shares,
            session.start,
            session.end,
            newShares,
            newStart,
            newEnd
        );

        maxShareInternal(
            sessionId,
            session.shares,
            newShares,
            session.amount,
            newAmount,
            newStart,
            newEnd
        );

        sessionDataOf[msg.sender][sessionId].amount = newAmount;
        sessionDataOf[msg.sender][sessionId].end = newEnd;
        sessionDataOf[msg.sender][sessionId].start = newStart;
        sessionDataOf[msg.sender][sessionId].shares = newShares;
        sessionDataOf[msg.sender][sessionId].firstPayout = payouts.length;
        sessionDataOf[msg.sender][sessionId].lastPayout = payouts.length + 5555;
    }

    //similar to the maxShare function, but for layer 1 stakes only
    // @param sessionId {uint256} - id of the staking session
    function maxShareV1(uint256 sessionId) external pausable {
        require(sessionId <= lastSessionIdV1, 'STAKING: Invalid sessionId');

        Session storage session = sessionDataOf[msg.sender][sessionId];

        require(
            session.shares == 0 && session.withdrawn == false,
            'STAKING: Stake withdrawn'
        );

        (
            uint256 amount,
            uint256 start,
            uint256 end,
            uint256 shares,
            uint256 firstPayout
        ) = stakingV1.sessionDataOf(msg.sender, sessionId);

        require(shares != 0, 'STAKING: Stake withdrawn v1');

        uint256 stakingDays = (end - start) / stepTimestamp;
        uint256 lastPayout = stakingDays + firstPayout;

        (
            uint256 newStart,
            uint256 newEnd,
            uint256 newAmount,
            uint256 newShares
        ) = maxShareUpgrade(firstPayout, lastPayout, shares, amount);

        addBPDMaxShares(shares, start, end, newShares, newStart, newEnd);

        maxShareInternal(
            sessionId,
            shares,
            newShares,
            amount,
            newAmount,
            newStart,
            newEnd
        );

        sessionDataOf[msg.sender][sessionId] = Session({
            amount: newAmount,
            start: newStart,
            end: newEnd,
            shares: newShares,
            firstPayout: payouts.length,
            lastPayout: payouts.length + 5555,
            withdrawn: false,
            payout: 0
        });

        sessionsOf[msg.sender].push(sessionId);
    }

    //function to calculate the new start, end, new amount and new shares for a max share upgrade
    // @param firstPayout {uint256} - id of the first Payout
    // @param lasttPayout {uint256} - id of the last Payout
    // @param shares {uint256} - number of shares
    // @param amount {uint256} - amount of AXN
    function maxShareUpgrade(
        uint256 firstPayout,
        uint256 lastPayout,
        uint256 shares,
        uint256 amount
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        require(
            maxShareEventActive == true,
            'STAKING: Max Share event is not active'
        );
        require(
            lastPayout - firstPayout <= maxShareMaxDays,
            'STAKING: Max Share Upgrade - Stake must be less then max share max days'
        );

        uint256 stakingInterest =
            calculateStakingInterest(firstPayout, lastPayout, shares);

        uint256 newStart = now;
        uint256 newEnd = newStart + (stepTimestamp * 5555);
        uint256 newAmount = stakingInterest + amount;
        uint256 newShares =
            _getStakersSharesAmount(newAmount, newStart, newEnd);

        require(
            newShares > shares,
            'STAKING: New shares are not greater then previous shares'
        );

        return (newStart, newEnd, newAmount, newShares);
    }

    // @param sessionId {uint256} - id of the staking session
    // @param oldShares {uint256} - previous number of shares
    // @param newShares {uint256} - new number of shares
    // @param oldAmount {uint256} - old amount of AXN
    // @param newAmount {uint256} - new amount of AXN
    // @param newStart {uint256} - new start date for the stake
    // @param newEnd {uint256} - new end date for the stake
    function maxShareInternal(
        uint256 sessionId,
        uint256 oldShares,
        uint256 newShares,
        uint256 oldAmount,
        uint256 newAmount,
        uint256 newStart,
        uint256 newEnd
    ) internal {
        if (now >= nextPayoutCall) makePayout();
        if (isVcaRegistered[msg.sender] == false)
            setTotalSharesOfAccountInternal(msg.sender);

        sharesTotalSupply = sharesTotalSupply.add(newShares - oldShares);
        totalStakedAmount = totalStakedAmount.add(newAmount - oldAmount);
        totalVcaRegisteredShares = totalVcaRegisteredShares.add(
            newShares - oldShares
        );

        uint256 oldTotalSharesOf = totalSharesOf[msg.sender];
        totalSharesOf[msg.sender] = totalSharesOf[msg.sender].add(
            newShares - oldShares
        );

        rebalance(msg.sender, oldTotalSharesOf);

        emit MaxShareUpgrade(
            msg.sender,
            sessionId,
            oldAmount,
            newAmount,
            oldShares,
            newShares,
            newStart,
            newEnd
        );
    }

    // stepTimestamp
    // startContract
    function calculateStepsFromStart() public view returns (uint256) {
        return now.sub(startContract).div(stepTimestamp);
    }

    /** Set Max Shares */
    function setMaxShareEventActive(bool _active) external onlyManager {
        maxShareEventActive = _active;
    }

    function getMaxShareEventActive() external view returns (bool) {
        return maxShareEventActive;
    }

    function setMaxShareMaxDays(uint16 _maxShareMaxDays) external onlyManager {
        maxShareMaxDays = _maxShareMaxDays;
    }

    function setTotalVcaRegisteredShares(uint256 _shares)
        external
        onlyMigrator
    {
        totalVcaRegisteredShares = _shares;
    }

    function setPaused(bool _paused) external {
        require(
            hasRole(MIGRATOR_ROLE, msg.sender) ||
                hasRole(MANAGER_ROLE, msg.sender),
            'STAKING: User must be manager or migrator'
        );
        paused = _paused;
    }

    function getPaused() external view returns (bool) {
        return paused;
    }

    function getMaxShareMaxDays() external view returns (uint16) {
        return maxShareMaxDays;
    }

    /** Roles management - only for multi sig address */
    function setupRole(bytes32 role, address account) external onlyManager {
        _setupRole(role, account);
    }

    function getDivTokens() external view returns (address[] memory) {
        address[] memory divTokenAddresses = new address[](divTokens.length());

        for (uint8 i = 0; i < divTokens.length(); i++) {
            divTokenAddresses[i] = divTokens.at(i);
        }

        return divTokenAddresses;
    }

    function getTotalSharesOf(address account) external view returns (uint256) {
        return totalSharesOf[account];
    }

    function getTotalVcaRegisteredShares() external view returns (uint256) {
        return totalVcaRegisteredShares;
    }

    function getIsVCARegistered(address staker) external view returns (bool) {
        return isVcaRegistered[staker];
    }

    function setBPDPools(
        uint128[5] calldata poolAmount,
        uint128[5] calldata poolShares
    ) external onlyMigrator {
        for (uint8 i = 0; i < poolAmount.length; i++) {
            bpd128.pool[i] = poolAmount[i];
            bpd128.shares[i] = poolShares[i];
        }
    }

    function findBPDEligible(uint256 starttime, uint256 endtime)
        external
        view
        returns (uint16[2] memory)
    {
        return findBPDs(starttime, endtime);
    }

    function findBPDs(uint256 starttime, uint256 endtime)
        internal
        view
        returns (uint16[2] memory)
    {
        uint16[2] memory bpdInterval;
        uint256 denom = stepTimestamp.mul(350);
        bpdInterval[0] = uint16(
            MathUpgradeable.min(5, starttime.sub(startContract).div(denom))
        ); // (starttime - t0) // 350
        uint256 bpdEnd =
            uint256(bpdInterval[0]) + endtime.sub(starttime).div(denom);
        bpdInterval[1] = uint16(MathUpgradeable.min(bpdEnd, 5)); // bpd_first + nx350

        return bpdInterval;
    }

    function addBPDMaxShares(
        uint256 oldShares,
        uint256 oldStart,
        uint256 oldEnd,
        uint256 newShares,
        uint256 newStart,
        uint256 newEnd
    ) internal {
        uint16[2] memory oldBpdInterval = findBPDs(oldStart, oldEnd);
        uint16[2] memory newBpdInterval = findBPDs(newStart, newEnd);
        for (uint16 i = oldBpdInterval[0]; i < newBpdInterval[1]; i++) {
            uint256 shares = newShares;
            if (oldBpdInterval[1] > i) {
                shares = shares.sub(oldShares);
            }
            bpd128.shares[i] += uint128(shares); // we only do integer shares, no decimals
        }
    }

    function addBPDShares(
        uint256 shares,
        uint256 starttime,
        uint256 endtime
    ) internal {
        uint16[2] memory bpdInterval = findBPDs(starttime, endtime);
        for (uint16 i = bpdInterval[0]; i < bpdInterval[1]; i++) {
            bpd128.shares[i] += uint128(shares); // we only do integer shares, no decimals
        }
    }

    function calcBPDOnWithdraw(uint256 shares, uint16[2] memory bpdInterval)
        internal
        view
        returns (uint256)
    {
        uint256 bpdAmount;
        uint256 shares1e18 = shares.mul(1e18);
        for (uint16 i = bpdInterval[0]; i < bpdInterval[1]; i++) {
            bpdAmount += shares1e18.div(bpd128.shares[i]).mul(bpd128.pool[i]);
        }

        return bpdAmount.div(1e18);
    }

    /** CalcBPD
        @param start - Start of the stake
        @param end - ACTUAL End of the stake. We want to calculate using the actual end. We'll use findBPD's to figure out what BPD's the user is eligible for
        @param shares - Shares of stake
     */
    function calcBPD(
        uint256 start,
        uint256 end,
        uint256 shares
    ) public view returns (uint256) {
        uint16[2] memory bpdInterval = findBPDs(start, end);
        return calcBPDOnWithdraw(shares, bpdInterval);
    }

    function getBPD()
        external
        view
        returns (uint128[5] memory, uint128[5] memory)
    {
        return (bpd128.pool, bpd128.shares);
    }
}
