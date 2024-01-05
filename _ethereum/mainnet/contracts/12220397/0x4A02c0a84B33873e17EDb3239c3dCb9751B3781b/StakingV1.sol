// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;

import "./IERC20.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./ITokenV1.sol";
import "./IAuctionV1.sol";
import "./IStakingV1.sol";
import "./ISubBalancesV1.sol";

contract StakingV1 is IStakingV1, AccessControl {
    using SafeMath for uint256;

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

    uint256 private _sessionsIds;

    bytes32 public constant EXTERNAL_STAKER_ROLE =
        keccak256('EXTERNAL_STAKER_ROLE');

    struct Payout {
        uint256 payout;
        uint256 sharesTotalSupply;
    }

    struct Session {
        uint256 amount;
        uint256 start;
        uint256 end;
        uint256 shares;
        uint256 nextPayout;
    }

    address public mainToken;
    address public auction;
    address public subBalances;
    uint256 public shareRate;
    uint256 public sharesTotalSupply;
    uint256 public nextPayoutCall;
    uint256 public stepTimestamp;
    uint256 public startContract;
    uint256 public globalPayout;
    uint256 public globalPayin;

    mapping(address => mapping(uint256 => Session))
        public
        override sessionDataOf;
    mapping(address => uint256[]) public sessionsOf;
    Payout[] public payouts;

    modifier onlyExternalStaker() {
        require(
            hasRole(EXTERNAL_STAKER_ROLE, _msgSender()),
            'Caller is not a external staker'
        );
        _;
    }

    function init(
        address _mainToken,
        address _auction,
        address _subBalances,
        address _foreignSwap,
        uint256 _stepTimestamp
    ) external {
        _setupRole(EXTERNAL_STAKER_ROLE, _foreignSwap);
        _setupRole(EXTERNAL_STAKER_ROLE, _auction);
        mainToken = _mainToken;
        auction = _auction;
        subBalances = _subBalances;
        shareRate = 1e18;
        stepTimestamp = _stepTimestamp;
        nextPayoutCall = now.add(_stepTimestamp);
        startContract = now;
    }

    function sessionsOf_(address account)
        external
        view
        returns (uint256[] memory)
    {
        return sessionsOf[account];
    }

    function stake(uint256 amount, uint256 stakingDays) external {
        if (now >= nextPayoutCall) makePayout();

        require(stakingDays > 0, 'stakingDays < 1');

        uint256 start = now;
        uint256 end = now.add(stakingDays.mul(stepTimestamp));

        ITokenV1(mainToken).burn(msg.sender, amount);
        _sessionsIds = _sessionsIds.add(1);
        uint256 sessionId = _sessionsIds;
        uint256 shares = _getStakersSharesAmount(amount, start, end);
        sharesTotalSupply = sharesTotalSupply.add(shares);

        sessionDataOf[msg.sender][sessionId] = Session({
            amount: amount,
            start: start,
            end: end,
            shares: shares,
            nextPayout: payouts.length
        });

        sessionsOf[msg.sender].push(sessionId);

        ISubBalancesV1(subBalances).callIncomeStakerTrigger(
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
    ) external override {
        if (now >= nextPayoutCall) makePayout();

        require(stakingDays > 0, 'stakingDays < 1');

        uint256 start = now;
        uint256 end = now.add(stakingDays.mul(stepTimestamp));

        _sessionsIds = _sessionsIds.add(1);
        uint256 sessionId = _sessionsIds;
        uint256 shares = _getStakersSharesAmount(amount, start, end);
        sharesTotalSupply = sharesTotalSupply.add(shares);

        sessionDataOf[staker][sessionId] = Session({
            amount: amount,
            start: start,
            end: end,
            shares: shares,
            nextPayout: payouts.length
        });

        sessionsOf[staker].push(sessionId);

        ISubBalancesV1(subBalances).callIncomeStakerTrigger(
            staker,
            sessionId,
            start,
            end,
            shares
        );

        emit Stake(staker, sessionId, amount, start, end, shares);
    }

    function _initPayout(address to, uint256 amount) internal {
        ITokenV1(mainToken).mint(to, amount);
        globalPayout = globalPayout.add(amount);
    }

    function calculateStakingInterest(
        uint256 sessionId,
        address account,
        uint256 shares
    ) public view returns (uint256) {
        uint256 stakingInterest;

        for (
            uint256 i = sessionDataOf[account][sessionId].nextPayout;
            i < payouts.length;
            i++
        ) {
            uint256 payout =
                payouts[i].payout.mul(shares).div(payouts[i].sharesTotalSupply);

            stakingInterest = stakingInterest.add(payout);
        }

        return stakingInterest;
    }

    function _updateShareRate(
        address account,
        uint256 shares,
        uint256 stakingInterest,
        uint256 sessionId
    ) internal {
        uint256 newShareRate =
            _getShareRate(
                sessionDataOf[account][sessionId].amount,
                shares,
                sessionDataOf[account][sessionId].start,
                sessionDataOf[account][sessionId].end,
                stakingInterest
            );

        if (newShareRate > shareRate) {
            shareRate = newShareRate;
        }
    }

    function unstake(uint256 sessionId) external {
        if (now >= nextPayoutCall) makePayout();

        require(
            sessionDataOf[msg.sender][sessionId].shares > 0,
            'Staking: Shares balance is empty'
        );

        uint256 shares = sessionDataOf[msg.sender][sessionId].shares;

        sessionDataOf[msg.sender][sessionId].shares = 0;

        if (sessionDataOf[msg.sender][sessionId].nextPayout >= payouts.length) {
            // To auction
            uint256 amount = sessionDataOf[msg.sender][sessionId].amount;

            _initPayout(auction, amount);
            IAuctionV1(auction).callIncomeDailyTokensTrigger(amount);

            emit Unstake(
                msg.sender,
                sessionId,
                amount,
                sessionDataOf[msg.sender][sessionId].start,
                sessionDataOf[msg.sender][sessionId].end,
                shares
            );

            ISubBalancesV1(subBalances).callOutcomeStakerTrigger(
                msg.sender,
                sessionId,
                sessionDataOf[msg.sender][sessionId].start,
                sessionDataOf[msg.sender][sessionId].end,
                shares
            );

            return;
        }

        uint256 stakingInterest =
            calculateStakingInterest(sessionId, msg.sender, shares);

        _updateShareRate(msg.sender, shares, stakingInterest, sessionId);

        sharesTotalSupply = sharesTotalSupply.sub(shares);

        (uint256 amountOut, uint256 penalty) =
            getAmountOutAndPenalty(sessionId, stakingInterest);

        // To auction
        _initPayout(auction, penalty);
        IAuctionV1(auction).callIncomeDailyTokensTrigger(penalty);

        // To account
        _initPayout(msg.sender, amountOut);

        emit Unstake(
            msg.sender,
            sessionId,
            amountOut,
            sessionDataOf[msg.sender][sessionId].start,
            sessionDataOf[msg.sender][sessionId].end,
            shares
        );

        ISubBalancesV1(subBalances).callOutcomeStakerTrigger(
            msg.sender,
            sessionId,
            sessionDataOf[msg.sender][sessionId].start,
            sessionDataOf[msg.sender][sessionId].end,
            sessionDataOf[msg.sender][sessionId].shares
        );
    }

    /** This is for testing purposes to fix v1 unstakes */
    function unstakeTest(uint256 sessionId) external {
        require(
            sessionDataOf[msg.sender][sessionId].shares != 0,
            'Staking: Shares balance is empty'
        );

        sessionDataOf[msg.sender][sessionId].shares = 0;
    }

    function getAmountOutAndPenalty(uint256 sessionId, uint256 stakingInterest)
        public
        view
        returns (uint256, uint256)
    {
        uint256 stakingDays =
            (
                sessionDataOf[msg.sender][sessionId].end.sub(
                    sessionDataOf[msg.sender][sessionId].start
                )
            )
                .div(stepTimestamp);

        uint256 daysStaked =
            (now.sub(sessionDataOf[msg.sender][sessionId].start)).div(
                stepTimestamp
            );

        uint256 amountAndInterest =
            sessionDataOf[msg.sender][sessionId].amount.add(stakingInterest);

        // Early
        if (stakingDays > daysStaked) {
            uint256 payOutAmount =
                amountAndInterest.mul(daysStaked).div(stakingDays);

            uint256 earlyUnstakePenalty = amountAndInterest.sub(payOutAmount);

            return (payOutAmount, earlyUnstakePenalty);
            // In time
        } else if (
            stakingDays <= daysStaked && daysStaked < stakingDays.add(14)
        ) {
            return (amountAndInterest, 0);
            // Late
        } else if (
            stakingDays.add(14) <= daysStaked &&
            daysStaked < stakingDays.add(714)
        ) {
            uint256 daysAfterStaking = daysStaked.sub(stakingDays);

            uint256 payOutAmount =
                amountAndInterest.mul(uint256(714).sub(daysAfterStaking)).div(
                    700
                );

            uint256 lateUnstakePenalty = amountAndInterest.sub(payOutAmount);

            return (payOutAmount, lateUnstakePenalty);
            // Nothing
        } else if (stakingDays.add(714) <= daysStaked) {
            return (0, amountAndInterest);
        }

        return (0, 0);
    }

    function makePayout() public {
        require(now >= nextPayoutCall, 'Staking: Wrong payout time');

        uint256 payout = _getPayout();

        payouts.push(
            Payout({payout: payout, sharesTotalSupply: sharesTotalSupply})
        );

        nextPayoutCall = nextPayoutCall.add(stepTimestamp);

        emit MakePayout(payout, sharesTotalSupply, now);
    }

    function readPayout() external view returns (uint256) {
        uint256 amountTokenInDay = IERC20(mainToken).balanceOf(address(this));

        uint256 currentTokenTotalSupply =
            (IERC20(mainToken).totalSupply()).add(globalPayin);

        uint256 inflation =
            uint256(8).mul(currentTokenTotalSupply.add(sharesTotalSupply)).div(
                36500
            );

        return amountTokenInDay.add(inflation);
    }

    function _getPayout() internal returns (uint256) {
        uint256 amountTokenInDay = IERC20(mainToken).balanceOf(address(this));

        globalPayin = globalPayin.add(amountTokenInDay);

        if (globalPayin > globalPayout) {
            globalPayin = globalPayin.sub(globalPayout);
            globalPayout = 0;
        } else {
            globalPayin = 0;
            globalPayout = 0;
        }

        uint256 currentTokenTotalSupply =
            (IERC20(mainToken).totalSupply()).add(globalPayin);

        ITokenV1(mainToken).burn(address(this), amountTokenInDay);

        uint256 inflation =
            uint256(8).mul(currentTokenTotalSupply.add(sharesTotalSupply)).div(
                36500
            );

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

        uint256 numerator =
            (amount.add(stakingInterest)).mul(uint256(1819).add(stakingDays));

        uint256 denominator = uint256(1820).mul(shares);

        return (numerator).mul(1e18).div(denominator);
    }

    // Helper
    function getNow0x() external view returns (uint256) {
        return now;
    }
}
