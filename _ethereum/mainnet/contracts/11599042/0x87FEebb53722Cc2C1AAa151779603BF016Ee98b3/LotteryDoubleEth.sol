// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.6.0;

import "./SafeMath.sol";

import "./LotteryHistoryInterface.sol";
import "./BootyInterface.sol";
import "./TreasuryInterface.sol";
import "./RandomnessInterface.sol";
import "./GovernanceInterface.sol";
import "./ResolutionAlarmInterface.sol";

import "./GasTokenUser.sol";

/** 
 * @title Lottery with 50% winning chance to ~double the bet
 * @dev Implements betting process
 */
contract LotteryDoubleEth is GasTokenUser {
    using SafeMath for uint256;

    GovernanceInterface public immutable TrustedGovernance;
    RandomnessInterface public immutable TrustedRandomness;
    LotteryHistoryInterface public immutable TrustedHistory;
    TreasuryInterface public TrustedTreasury;
    ResolutionAlarmInterface internal TrustedAlarm;

    // We use LOTTERY_STATE instead of Pausable abstraction
    // to save gas fees, as we need more states in lottery state machine.
    enum LOTTERY_STATE { OPENED, PAUSED, RESOLUTION, RESOLVED }
    LOTTERY_STATE public state = LOTTERY_STATE.OPENED;

    address internal constant ZERO_ADDRESS = address(0);
    uint256 internal constant MAX_BLOCKS_TO_RESOLVE = 300; // ~60-80 minutes

    mapping(uint32 => BootyInterface) public TrustedBooties;
    BootyInterface[] public TrustedAvailableBooties;
    mapping(address => uint32) public lastRoundPlayed;
    mapping(address => uint256) public influencers;
    
    uint32 public lotteryPeriod = 1440 minutes;
    uint32 public currentRound = 0;
    uint256 public casinoFee = 10000;       // in percents * 10000, 10000 means 1%
    uint256 public rewardCof = 140;         // send x140 L7L for ETH betted
    uint256 public refRewardCof = 10;       // send x10 L7L for ETH betted to referrer 
    uint256 public loserRewardCof = 141;    // compensate casino fee
    uint256 public minimalBetAmount = 0.01 ether;
    bytes32 public lastSeed;
    uint public endsAfter;
    uint public maxBlockToResolve;

    modifier onlyDAO() {
        require(msg.sender == TrustedGovernance.owner(), "Only owner");
        _;
    }

    modifier onlyManagement() {
        require(TrustedGovernance.isManagement(msg.sender), "Only management");
        _;
    }

    modifier onlyResolvers() {
        require(msg.sender == address(TrustedAlarm)
            || TrustedGovernance.isManagement(msg.sender), "Only resolvers");
        _;
    }

    modifier onlyOpenedCasino() {
        require(state == LOTTERY_STATE.OPENED, "LE7EL Random is temporary closed");
        _;
    }

    modifier notInResolution() {
        LOTTERY_STATE _state = state;
        require(_state != LOTTERY_STATE.RESOLUTION && _state != LOTTERY_STATE.RESOLVED, "LE7EL Random is in resolution");
        _;
    }

    modifier onlyValidBets() {
        require(msg.value >= minimalBetAmount, "Your bet is too small");
        _;
    }

    /** 
     * @dev L7L DAO should be in charge of lottery smart-contract.
     *
     * @param _governance Orchestration contract.
     * @param _treasury Escrow contract where user winnings are kept.
     * @param _resolution_alarm Chainlink alarm contact proxy.
     * @param _randomness Chainlink randomness contract proxy.
     * @param _history History of games contract.
     */
    constructor(address _governance, address _treasury, address _resolution_alarm, address _randomness, address _history) public {
        TrustedGovernance = GovernanceInterface(_governance);
        TrustedTreasury = TreasuryInterface(_treasury);
        TrustedAlarm = ResolutionAlarmInterface(_resolution_alarm);
        TrustedRandomness = RandomnessInterface(_randomness);
        TrustedHistory = LotteryHistoryInterface(_history);
    }

    /**
     * @dev Start the first round.
     */
    function initialize(uint32 _currentRound) public {
        require(currentRound == 0, "Already initialized");
        currentRound = _currentRound;

        address bootyAddr = TrustedTreasury.createBooty();
        BootyInterface TrustedBooty = BootyInterface(bootyAddr);
        TrustedBooty.useForRound(_currentRound);
        TrustedBooties[_currentRound] = TrustedBooty;

        endsAfter = now + lotteryPeriod;
        TrustedHistory.roundStarted(_currentRound, endsAfter);
    }

    /**
     * @dev Helper to fetch current Booty address.
     */
    function currentBooty() public view returns(address) {
        return address(TrustedBooties[currentRound]);
    }

    /**
     * @dev Checks if game is ready for resolution by 3rd party alarm resolvers.
     */
    function canResolve() public view returns (bool) {
        return state == LOTTERY_STATE.OPENED && now > endsAfter;
    }

    /** 
     * @dev Requests Chainlink randomness.
     *
     * In case one side doesn't have bets, declare draw.
     *
     * In case there are no bets at all - recycle to save gas.
     */
    function results() public onlyOpenedCasino onlyResolvers {
        if (msg.sender == address(TrustedAlarm)) require(now > endsAfter, "Not ready for results");

        uint32 _currentRound = currentRound;
        BootyInterface TrustedBooty = TrustedBooties[_currentRound];
        uint8 bootyReadiness = TrustedBooty.readiness();

        if (bootyReadiness == 2) {
            uint256 seed = uint256(keccak256(abi.encodePacked(block.difficulty, _currentRound)));

            maxBlockToResolve = block.number + MAX_BLOCKS_TO_RESOLVE;
            state = LOTTERY_STATE.RESOLUTION;
            setAlarm(lotteryPeriod);

            TrustedRandomness.getRandom(seed, _currentRound);
            lastSeed = bytes32(seed);
        } else if (bootyReadiness == 1) {
            TrustedBooty.declareDraw();

            LotteryHistoryInterface _TrustedHistory = TrustedHistory;
            _TrustedHistory.roundEnded(_currentRound, 0, 0, 0);

            reset();

            uint256 _endsAfter = setAlarm(lotteryPeriod);
            _TrustedHistory.roundStarted(_currentRound + 1, _endsAfter);
        } else {
            LotteryHistoryInterface _TrustedHistory = TrustedHistory;
            _TrustedHistory.roundEnded(_currentRound, 0, 0, 0);

            currentRound++;

            address mmBlue;
            uint256 amBlue;
            address mmGreen;
            uint256 amGreen;
            uint32 _newRound = _currentRound + 1;
            (mmBlue, amBlue, mmGreen, amGreen) = TrustedBooty.recycleForRound(_newRound);

            if (mmBlue != ZERO_ADDRESS) _TrustedHistory.newBet(_newRound, 0, mmBlue, amBlue, ZERO_ADDRESS);
            if (mmGreen != ZERO_ADDRESS) _TrustedHistory.newBet(_newRound, 1, mmGreen, amGreen, ZERO_ADDRESS);

            state = LOTTERY_STATE.OPENED;
            TrustedBooties[_newRound] = TrustedBooty;

            uint256 _endsAfter = setAlarm(lotteryPeriod);
            _TrustedHistory.roundStarted(_newRound, _endsAfter);
        }
    }

    /**
     * @dev Callback function used by VRF Coordinator, pay the winners and reset the lottery.
     *
     * Presence of bets was checked in results() query.
     *
     * @param randomness Random result from Oracle.
     */
    function fulfillRandom(uint256 randomness) external {
        require(msg.sender == address(TrustedRandomness), "Only randomness");
        require(state == LOTTERY_STATE.RESOLUTION, "Not ready");

        BootyInterface TrustedBooty = TrustedBooties[currentRound];
        LotteryHistoryInterface _TrustedHistory = TrustedHistory;

        // Even result makes Blue betters a winner
        // Odd result makes Green betters a winners
        if (randomness % 2 == 0) {
            TrustedBooty.declareBlueWin();
            _TrustedHistory.roundEnded(currentRound, randomness, address(TrustedBooty).balance, TrustedBooty.totalBlue());
        } else {
            TrustedBooty.declareGreenWin();
            _TrustedHistory.roundEnded(currentRound, randomness, address(TrustedBooty).balance, TrustedBooty.totalGreen());
        }

        state = LOTTERY_STATE.RESOLVED;
    }

    /**
     * @dev Checks if game is ready for a new round after successful resolution.
     */
    function canContinue() public view returns (bool) {
        return state == LOTTERY_STATE.RESOLVED;
    }

    /** 
     * @dev Continue game after the round was resolved.
     */
    function continueGame() public onlyResolvers {
        require(canContinue(), "Not resolved");

        reset();

        TrustedHistory.roundStarted(currentRound, endsAfter);
    }

    /**
     * @dev Set alarm clock which should trigger Chainlink oracle
     * resolution for the current lottery round
     *
     *  @param _lotteryPeriod Minutes until lottery resolution.
     */
    function setAlarm(uint32 _lotteryPeriod) private returns(uint256) {
        uint256 _endsAfter = now + _lotteryPeriod;
        endsAfter = _endsAfter;
        TrustedAlarm.setAlarm(_lotteryPeriod);
        return _endsAfter;
    }

    /**
     * @dev Claim pending booty for the sender account.
     */
    function claimBooty() external {
        TrustedTreasury.withdrawPayments(msg.sender);
    }

    /**
     * @dev Claim pending booty for the sender account, burning the gas token.
     */
    function claimBootyWithGasToken() external usesGasToken(msg.sender) {
        TrustedTreasury.withdrawPayments(msg.sender);
    }

    /**
     * @dev Prepare lottery for the next round.
     */
    function reset() private {
        currentRound++;

        require(TrustedAvailableBooties.length > 0, "No free booty contracts");
        BootyInterface TrustedBooty = TrustedAvailableBooties[TrustedAvailableBooties.length - 1];
        TrustedBooty.useForRound(currentRound);
        TrustedBooties[currentRound] = TrustedBooty;
        TrustedAvailableBooties.pop();

        state = LOTTERY_STATE.OPENED;
    }

    /**
     * @dev Put bet to a Blue side, interface to optimise gas usage.
     *
     * @param _referrer Address of referrer for extra L7L rewards, pass 0 if none.
     */
    function betBlue(address _referrer) external payable onlyOpenedCasino onlyValidBets {
        commitBlueBet(msg.sender, msg.value, currentRound, _referrer);
    }

    /**
     * @dev Put bet to a Blue side, burning the gas token.
     *
     * @param _referrer Address of referrer for extra L7L rewards, pass 0 if none.
     */
    function betBlueWithGasToken(address _referrer) external payable onlyOpenedCasino onlyValidBets usesGasToken(msg.sender) {
        commitBlueBet(msg.sender, msg.value, currentRound, _referrer);
    }

    /**
     * @dev Put bet to a Green side, interface to optimise gas usage.
     *
     * @param _referrer Address of referrer for extra L7L rewards, pass 0 if none.
     */
    function betGreen(address _referrer) external payable onlyOpenedCasino onlyValidBets {
        commitGreenBet(msg.sender, msg.value, currentRound, _referrer);
    }

    /**
     * @dev Put bet to a Green side, burning the gas token.
     *
     * @param _referrer Address of referrer for extra L7L rewards, pass 0 if none.
     */
    function betGreenWithGasToken(address _referrer) external payable onlyOpenedCasino onlyValidBets usesGasToken(msg.sender) {
        commitGreenBet(msg.sender, msg.value, currentRound, _referrer);
    }

    /**
     * @dev By default do market making with equal bets to both sides.
     */
    receive() external payable onlyOpenedCasino onlyValidBets {
        uint256 greenValue = msg.value.div(2);
        uint256 blueValue = msg.value.sub(greenValue);

        commitGreenBet(msg.sender, greenValue, currentRound, ZERO_ADDRESS);
        commitBlueBet(msg.sender, blueValue, currentRound, ZERO_ADDRESS);
    }

    /**
     * @dev Put bet to a Blue side.
     *
     * @param sender Address of better.
     * @param value Bet size in wei.
     * @param _round Current round.
     * @param _referrer Referral ticket.
     */
    function commitBlueBet(address payable sender, uint256 value, uint32 _round, address _referrer) private {
        uint256 _cleanBet = cleanValue(value);
        BootyInterface TrustedBooty = TrustedBooties[_round];
        TrustedBooty.blueBet{value: _cleanBet}(sender);
        commitBet(sender, value, TrustedBooty, _round, _referrer);
        TrustedHistory.newBet(_round, 0, sender, _cleanBet, _referrer);
    }

    /**
     * @dev Put bet to a Green side.
     *
     * @param sender Address of better.
     * @param value Bet size in wei.
     * @param _round Current round.
     * @param _referrer Referral ticket.
     */
    function commitGreenBet(address payable sender, uint256 value, uint32 _round, address _referrer) private {
        uint256 _cleanBet = cleanValue(value);
        BootyInterface TrustedBooty = TrustedBooties[_round];
        TrustedBooty.greenBet{value: _cleanBet}(sender);
        commitBet(sender, value, TrustedBooty, _round, _referrer);
        TrustedHistory.newBet(_round, 1, sender, _cleanBet, _referrer);
    }

    /**
     * @dev Shared betting business logic
     *
     * We don't use pendingL7lRewards to optimise reads from storage 
     * as this function is used a lot.
     *
     * @param sender Address of better.
     * @param value Bet size in wei.
     * @param TrustedBooty Contract to interact with current round Booty.
     * @param _round Current round.
     */
    function commitBet(address payable sender, uint256 value, BootyInterface TrustedBooty, uint32 _round, address _referrer) private {
        address _senderAddr = address(sender);
        uint32 _lastPlayerRound = lastRoundPlayed[_senderAddr];
        uint256 _pendingReward = 0;
        uint256 _rewardCof = rewardCof;
        uint256 _refRewardCof = refRewardCof;

        if (_lastPlayerRound != _round) {
            TrustedTreasury.registerPlayerBooty(sender, address(TrustedBooty));
            lastRoundPlayed[_senderAddr] = _round;

            if (_lastPlayerRound > 0 && _rewardCof > 0) {
                _pendingReward = TrustedBooties[_lastPlayerRound].losesOf(_senderAddr).mul(loserRewardCof);
            }
        }

        if (_referrer != ZERO_ADDRESS && _referrer != _senderAddr && _refRewardCof > 0) {
            _pendingReward = _pendingReward.add(value.mul(_refRewardCof));

            uint256 _refCof = _refRewardCof;
            uint256 _customCof = influencers[_referrer];
            if (_customCof > 0) _refCof = _customCof;
            TrustedTreasury.rewardL7l(_referrer, value.mul(_refCof));
        }

        if (_rewardCof > 0) TrustedTreasury.rewardL7l(_senderAddr, _pendingReward.add(value.mul(_rewardCof)));
    }

    /**
     * @dev Get pending L7L reward from previous loses.
     */
    function pendingL7lRewards(address player) public view returns(uint256) {
        uint32 lastPlayerRound = lastRoundPlayed[player];
        if (lastPlayerRound != currentRound && lastPlayerRound > 0 && rewardCof > 0) {
            return TrustedBooties[lastPlayerRound].losesOf(player).mul(loserRewardCof);
        } else {
            return 0;
        }
    }

    /**
     * @dev Helper to calculate value without casino share.
     *
     * @param _value Original amount to deduct from.
     */
    function cleanValue(uint256 _value) private view returns (uint256) {
        return _value.sub(_value.mul(casinoFee).div(1000000));
    }

    /**
     * @dev Helper to create and register new Booty contracts.
     */
    function createBooty() public {
        address bootyAddr = TrustedTreasury.createBooty();
        TrustedAvailableBooties.push(BootyInterface(bootyAddr));
    }

    /**
     * @dev Helper to create and register new Booty contracts.
     */
    function createBootyWithGasToken() public usesGasToken(msg.sender) {
        createBooty();
    }

    /**
     * @dev Manual lottery reset in case it stuck, refund players if there are bets.
     * In case resolution has stucked, it's possible to hard reset in 300 blocks (~60-80 minutes)
     *
     * Use continueGame is it was resolved.
     *
     * @param _lotteryPeriod Minutes until lottery resolution.
     */
    function daoReset(uint32 _lotteryPeriod) external onlyManagement {
        require(state != LOTTERY_STATE.RESOLVED || block.number > maxBlockToResolve, "Wait 300 blocks to refund");

        TrustedBooties[currentRound].declareDraw();
        LotteryHistoryInterface _TrustedHistory = TrustedHistory;

        _TrustedHistory.roundEnded(currentRound, 0, 0, 0);

        reset();

        uint256 _endsAfter = endsAfter;
        if (_lotteryPeriod > 0) {
            _endsAfter = setAlarm(_lotteryPeriod);
        }

        _TrustedHistory.roundStarted(currentRound, _endsAfter);
    }

    /** 
     * @dev Change lottery period from default 24 hours.
     * 
     * @param _lotteryPeriod Minutes until lottery resolution.
     */
    function daoChangePeriod(uint32 _lotteryPeriod) external onlyManagement {
        lotteryPeriod = _lotteryPeriod;
    }

    /** 
     * @dev Temporary game suspention for quick reaction against hacks
     * L7L DAO can revoke suspention and revoke manager rights 
     */
    function daoToggleLock() external notInResolution onlyManagement {
        if (state == LOTTERY_STATE.OPENED) {
            state = LOTTERY_STATE.PAUSED;
        } else {
            state = LOTTERY_STATE.OPENED;

            if (now > endsAfter) {
                setAlarm(lotteryPeriod);
            }
        }
    }
    
    /** 
     * @dev Used to update LE7EL fee.
     *
     * @param _casinoFee Casino share in hundreds of percents (10000 is 1%, 10000 is 10% etc)
     */
    function daoSetCasinoFee(uint256 _casinoFee) external notInResolution onlyDAO {
        casinoFee = _casinoFee;
        loserRewardCof = rewardCof.add(_casinoFee.div(10000));
    }

    /** 
     * @dev Used to update Chainlink oracle fee.
     *
     * @param _rewardCof How much L7L is rewarded for 1 ETH in bets.
     */
    function daoSetL7lReward(uint256 _rewardCof) external onlyDAO {
        rewardCof = _rewardCof;
        loserRewardCof = _rewardCof.add(casinoFee.div(10000));
    }

    /** 
     * @dev Used to update default referral and referee rewards.
     *
     * @param _refRewardCof How much extra L7L is rewarded for 1 ETH in bets.
     */
    function daoDefaultRefReward(uint256 _refRewardCof) external onlyDAO {
        refRewardCof = _refRewardCof;
    }

    /** 
     * @dev Change custom referral reward.
     *
     * @param _referrer Address of influencer to recieve custom reward.
     * @param _rewardCof Custom ref reward amount in L7L per ETH bet.
     */
    function daoInfluencerReward(address _referrer, uint256 _rewardCof) external onlyManagement {
        require(_rewardCof < 100, "Too high reward");
        influencers[_referrer] = _rewardCof;
    }
    
    /** 
     * @dev Used to update minimal bet amount.
     *
     * @param _minimalBetAmount Minimal amount in wei.
     */
    function daoSetMinimalBet(uint256 _minimalBetAmount) external onlyDAO {
        minimalBetAmount = _minimalBetAmount;
    }

    /** 
     * @dev Used to withdraw earned comission.
     */
    function daoWithdraw() external onlyManagement {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = TrustedGovernance.beneficiary().call{value: address(this).balance}("");
        require(success, "unable to withdraw casino share");
    }

    /** 
     * @dev All payouts should be cleared before contract can be recycled.
     */
    function daoRecycleBooty(uint32 round) external onlyManagement {
        BootyInterface TrustedBooty = TrustedBooties[round];
        TrustedBooty.forceRecycle();
        TrustedAvailableBooties.push(TrustedBooty);
    }

    /** 
     * @dev Used to upgrade to a new contract version.
     *
     * @param _resolution_alarm Change smart contract for periodic alarms, can be a casual wallet as well.
     */
    function daoChangeAlarmClock(address _resolution_alarm) external onlyDAO {
        TrustedAlarm = ResolutionAlarmInterface(_resolution_alarm);
    }

    /** 
     * @dev Used to upgrade to a new contract version.
     */
    function daoDie() external onlyDAO {
        require(TrustedBooties[currentRound].readiness() == 0, "Game is in process");
        selfdestruct(TrustedGovernance.beneficiary());
    }
}
