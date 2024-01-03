// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;

/** OpenZeppelin Dependencies */
// import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./IERC20Upgradeable.sol";
/** Local Interfaces */
import "./IToken.sol";
import "./IAuction.sol";
import "./IStaking.sol";
import "./ISubBalances.sol";
import "./IStakingV1.sol";


contract Staking is IStaking, Initializable, AccessControlUpgradeable {
    using SafeMathUpgradeable for uint256;

    /** Events */
    event Stake(
        address indexed account,
        uint256 indexed sessionId,
        uint256 amount,
        uint256 start,
        uint256 end,
        uint256 shares
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

    Addresses public addresses;
    IStakingV1 public stakingV1;

    /** Roles */
    bytes32 public constant MIGRATOR_ROLE = keccak256("MIGRATOR_ROLE");
    bytes32 public constant EXTERNAL_STAKER_ROLE = keccak256("EXTERNAL_STAKER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /** Public Variables */
    uint256 public shareRate;
    uint256 public sharesTotalSupply;
    uint256 public nextPayoutCall;
    uint256 public stepTimestamp;
    uint256 public startContract;
    uint256 public globalPayout;
    uint256 public globalPayin;
    uint256 public lastSessionId;
    uint256 public lastSessionIdV1;

    /** Mappings / Arrays */
    mapping(address => mapping(uint256 => Session)) public sessionDataOf;
    mapping(address => uint256[]) public sessionsOf;
    Payout[] public payouts;
    
    /** Booleans */
    bool public init_;

    /** Variables after initial contract launch must go below here. https://github.com/OpenZeppelin/openzeppelin-sdk/issues/37 */
    /** End Variables after launch */

    /** Roles */
    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Caller is not a manager");
        _;
    }
    modifier onlyMigrator() {
        require(hasRole(MIGRATOR_ROLE, _msgSender()), "Caller is not a migrator");
        _;
    }
    modifier onlyExternalStaker() {
        require(
            hasRole(EXTERNAL_STAKER_ROLE, _msgSender()),
            "Caller is not a external staker"
        );
        _;
    }

    /** Init functions */
    function initialize(
        address _manager,
        address _migrator
    ) public initializer {
        _setupRole(MANAGER_ROLE, _manager);
        _setupRole(MIGRATOR_ROLE, _migrator);
        init_ = false;
    }
    
    function init(
        address _mainTokenAddress,
        address _auctionAddress,
        address _subBalancesAddress,
        address _foreignSwapAddress,
        address _stakingV1Address,
        uint256 _stepTimestamp
    ) external onlyMigrator {
        require(!init_, "Staking: init is active");
        init_ = true;
        /** Setup */
        _setupRole(EXTERNAL_STAKER_ROLE, _foreignSwapAddress);
        _setupRole(EXTERNAL_STAKER_ROLE, _auctionAddress);

        addresses = Addresses({
            mainToken: _mainTokenAddress,
            auction: _auctionAddress,
            subBalances: _subBalancesAddress
        });
        
        stakingV1 = IStakingV1(_stakingV1Address);

        stepTimestamp = _stepTimestamp;

        if (startContract == 0) {
            startContract = now;
            nextPayoutCall = startContract.add(_stepTimestamp);
        }

        if (shareRate == 0) {
            shareRate = 1e18;
        }
    }
    /** End init functions */

    function sessionsOf_(address account)
        external
        view
        returns (uint256[] memory)
    {
        return sessionsOf[account];
    }

    function stake(uint256 amount, uint256 stakingDays) external {
        if (now >= nextPayoutCall) makePayout();

        // Staking days must be greater then 0 and less then or equal to 5555.
        require(stakingDays != 0, "stakingDays < 1");
        require(stakingDays <= 5555, "stakingDays > 5555");

        uint256 start = now;
        uint256 end = now.add(stakingDays.mul(stepTimestamp));

        IToken(addresses.mainToken).burn(msg.sender, amount);
        lastSessionId = lastSessionId.add(1);
        uint256 sessionId = lastSessionId;
        uint256 shares = _getStakersSharesAmount(amount, start, end);
        sharesTotalSupply = sharesTotalSupply.add(shares);

        sessionDataOf[msg.sender][sessionId] = Session({
            amount: amount,
            start: start,
            end: end,
            shares: shares,
            firstPayout: payouts.length,
            lastPayout: payouts.length + stakingDays,
            withdrawn: false,
            payout: 0
        });

        sessionsOf[msg.sender].push(sessionId);

        ISubBalances(addresses.subBalances).callIncomeStakerTrigger(
            msg.sender,
            sessionId,
            start,
            end,
            shares
        );

        emit Stake(msg.sender, sessionId, amount, start, end, shares);
    }

    function externalStake(
        uint256 amount,
        uint256 stakingDays,
        address staker
    ) external override onlyExternalStaker {
        if (now >= nextPayoutCall) makePayout();

        require(stakingDays != 0, "stakingDays < 1");
        require(stakingDays <= 5555, "stakingDays > 5555");

        uint256 start = now;
        uint256 end = now.add(stakingDays.mul(stepTimestamp));

        lastSessionId = lastSessionId.add(1);
        uint256 sessionId = lastSessionId;
        uint256 shares = _getStakersSharesAmount(amount, start, end);
        sharesTotalSupply = sharesTotalSupply.add(shares);

        sessionDataOf[staker][sessionId] = Session({
            amount: amount,
            start: start,
            end: end,
            shares: shares,
            firstPayout: payouts.length,
            lastPayout: payouts.length + stakingDays,
            withdrawn: false,
            payout: 0
        });

        sessionsOf[staker].push(sessionId);

        ISubBalances(addresses.subBalances).callIncomeStakerTrigger(
            staker,
            sessionId,
            start,
            end,
            shares
        );

        emit Stake(staker, sessionId, amount, start, end, shares);
    }

    function _initPayout(address to, uint256 amount) internal {
        IToken(addresses.mainToken).mint(to, amount);
        globalPayout = globalPayout.add(amount);
    }

    function calculateStakingInterest(
        uint256 firstPayout,
        uint256 lastPayout,
        uint256 shares
    ) public view returns (uint256) {
        uint256 stakingInterest;
        uint256 lastIndex = MathUpgradeable.min(
            payouts.length, 
            lastPayout
        );

        for (
            uint256 i = firstPayout;
            i < lastIndex;
            i++
        ) {
            uint256 payout = payouts[i].payout.mul(shares).div(
                payouts[i].sharesTotalSupply
            );

            stakingInterest = stakingInterest.add(payout);
        }

        return stakingInterest;
    }

    function unstake(uint256 sessionId) external {
        if (now >= nextPayoutCall) makePayout();

        Session storage session = sessionDataOf[msg.sender][sessionId];

        require(
            session.shares != 0 
                && session.withdrawn == false,
            "Staking: Stake withdrawn/invalid"
        );

        uint256 actualEnd = now;
        uint256 amountOut = unstakeInternal(
            sessionId,
            session.amount, 
            session.start, 
            session.end,
            actualEnd,
            session.shares, 
            session.firstPayout, 
            session.lastPayout
        );

        ISubBalances(addresses.subBalances).callOutcomeStakerTrigger(
            sessionId,
            session.start,
            session.end,
            actualEnd,
            session.shares
        );

        session.end = actualEnd;
        session.withdrawn = true;
        session.payout = amountOut;
    }

    function unstakeV1(uint256 sessionId) external {
        if (now >= nextPayoutCall) makePayout();

        require(sessionId <= lastSessionIdV1, "Staking: Invalid sessionId");

        Session storage session = sessionDataOf[msg.sender][sessionId];

        // Unstaked already
        require(
            session.shares == 0 && session.withdrawn == false,
            "Staking: Stake withdrawn"
        );

        (uint256 amount, uint256 start, uint256 end, uint256 shares, uint256 firstPayout) 
            = stakingV1.sessionDataOf(msg.sender, sessionId);

        // Unstaked in v1 / doesn't exist
        require(
            shares > 0,
            "Staking: Stake withdrawn"
        );

        uint256 lastPayout = (end - start) / stepTimestamp + firstPayout;

        uint256 actualEnd = now;
        uint256 amountOut = unstakeInternal(
            sessionId, 
            amount, 
            start,
            end,
            actualEnd,
            shares, 
            firstPayout, 
            lastPayout
        );

        ISubBalances(addresses.subBalances).callOutcomeStakerTriggerV1(
            msg.sender,
            sessionId,
            start,
            end,
            actualEnd,
            shares
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
    }

    function unstakeInternal(
        uint256 sessionId, 
        uint256 amount, 
        uint256 start, 
        uint256 end, 
        uint256 actualEnd,
        uint256 shares, 
        uint256 firstPayout,
        uint256 lastPayout
    ) internal returns (uint256) {
        uint256 stakingInterest = calculateStakingInterest(
            firstPayout,
            lastPayout,
            shares
        );

        sharesTotalSupply = sharesTotalSupply.sub(shares);

        (uint256 amountOut, uint256 penalty) = getAmountOutAndPenalty(
            amount,
            start,
            end,
            stakingInterest
        );

        // To auction
        if (penalty != 0) {
            _initPayout(addresses.auction, penalty);
            IAuction(addresses.auction).callIncomeDailyTokensTrigger(penalty);
        }
        
        // To account
        _initPayout(msg.sender, amountOut);

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

    function getAmountOutAndPenalty(uint256 amount, uint256 start, uint256 end, uint256 stakingInterest)
        public
        view
        returns (uint256, uint256)
    {
        uint256 stakingSeconds = end.sub(start);
        uint256 stakingDays = stakingSeconds.div(stepTimestamp);
        uint256 secondsStaked = now.sub(start);
        uint256 daysStaked = secondsStaked.div(stepTimestamp);
        uint256 amountAndInterest = amount.add(stakingInterest);

        // Early
        if (stakingDays > daysStaked) {
            uint256 payOutAmount = amountAndInterest.mul(secondsStaked).div(
                stakingSeconds
            );

            uint256 earlyUnstakePenalty = amountAndInterest.sub(payOutAmount);

            return (payOutAmount, earlyUnstakePenalty);
            // In time
        } else if (
            daysStaked < stakingDays.add(14)
        ) {
            return (amountAndInterest, 0);
            // Late
        } else if (
            daysStaked < stakingDays.add(714)
        ) {
            uint256 daysAfterStaking = daysStaked - stakingDays;

            uint256 payOutAmount = amountAndInterest
                .mul(uint256(714).sub(daysAfterStaking))
                .div(700);

            uint256 lateUnstakePenalty = amountAndInterest.sub(payOutAmount);

            return (payOutAmount, lateUnstakePenalty);
            // Nothing
        } else {
            return (0, amountAndInterest);
        }
    }

    function makePayout() public {
        require(now >= nextPayoutCall, "Staking: Wrong payout time");

        uint256 payout = _getPayout();

        payouts.push(
            Payout({payout: payout, sharesTotalSupply: sharesTotalSupply})
        );

        nextPayoutCall = nextPayoutCall.add(stepTimestamp);

        emit MakePayout(payout, sharesTotalSupply, now);
    }

    function readPayout() external view returns (uint256) {
        uint256 amountTokenInDay = IERC20Upgradeable(addresses.mainToken).balanceOf(address(this));

        uint256 currentTokenTotalSupply = (IERC20Upgradeable(addresses.mainToken).totalSupply()).add(
            globalPayin
        );

        uint256 inflation = uint256(8)
            .mul(currentTokenTotalSupply.add(sharesTotalSupply))
            .div(36500);

        return amountTokenInDay.add(inflation);
    }

    function _getPayout() internal returns (uint256) {
        uint256 amountTokenInDay = IERC20Upgradeable(addresses.mainToken).balanceOf(address(this));

        globalPayin = globalPayin.add(amountTokenInDay);

        if (globalPayin > globalPayout) {
            globalPayin = globalPayin.sub(globalPayout);
            globalPayout = 0;
        } else {
            globalPayin = 0;
            globalPayout = 0;
        }

        uint256 currentTokenTotalSupply = (IERC20Upgradeable(addresses.mainToken).totalSupply()).add(
            globalPayin
        );

        IToken(addresses.mainToken).burn(address(this), amountTokenInDay);

        uint256 inflation = uint256(8)
            .mul(currentTokenTotalSupply.add(sharesTotalSupply))
            .div(36500);


        globalPayin = globalPayin.add(inflation);

        return amountTokenInDay.add(inflation);
    }

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

    function _getShareRate(
        uint256 amount,
        uint256 shares,
        uint256 start,
        uint256 end,
        uint256 stakingInterest
    ) internal view returns (uint256) {
        uint256 stakingDays = (end.sub(start)).div(stepTimestamp);

        uint256 numerator = (amount.add(stakingInterest)).mul(
            uint256(1819).add(stakingDays)
        );

        uint256 denominator = uint256(1820).mul(shares);

        return (numerator).mul(1e18).div(denominator);
    }

    /** Roles management - only for multi sig address */
    function setupRole(bytes32 role, address account) external onlyManager {
        _setupRole(role, account);
    }
}
