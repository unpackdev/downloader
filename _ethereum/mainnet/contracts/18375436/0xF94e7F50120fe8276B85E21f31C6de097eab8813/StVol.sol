// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IPyth.sol";
import "./PythStructs.sol";

contract StVol is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable token; // Prediction token

    IPyth public oracle;

    bool public genesisOpenOnce = false;
    bool public genesisStartOnce = false;

    bytes32 public priceId; // address of the pyth price
    address public adminAddress; // address of the admin
    address public operatorAddress; // address of the operator
    address public operatorVaultAddress; // address of the operator vault

    uint256 public bufferSeconds; // number of seconds for valid execution of a participate round
    uint256 public intervalSeconds; // interval in seconds between two participate rounds

    uint256 public minParticipateAmount; // minimum participate amount (denominated in wei)
    uint256 public commissionfee; // commission rate (e.g. 200 = 2%, 150 = 1.50%)
    uint256 public treasuryAmount; // treasury amount that was not claimed
    uint256 public operateRate; // operate distribute rate (e.g. 200 = 2%, 150 = 1.50%)
    uint256 public participantRate; // participant distribute rate (e.g. 200 = 2%, 150 = 1.50%)
    int256 public strategyRate; // strategy rate (e.g. 100 = 1%)
    StrategyType public strategyType; // strategy type

    uint256 public currentEpoch; // current epoch for round

    uint256 public constant BASE = 10000; // 100%
    uint256 public constant MAX_COMMISSION_FEE = 200; // 2%

    uint256 public constant DEFAULT_MIN_PARTICIPATE_AMOUNT = 1000000; // 1 USDC
    uint256 public constant DEFAULT_INTERVAL_SECONDS = 86400; // 24 * 60 * 60 * 1(1day)
    uint256 public constant DEFAULT_BUFFER_SECONDS = 600; // 60 * 10 (10min)

    mapping(uint256 => mapping(Position => mapping(address => ParticipateInfo)))
        public ledger;
    mapping(uint256 => Round) public rounds;
    mapping(address => uint256[]) public userRounds;

    enum Position {
        Over,
        Under
    }

    enum StrategyType {
        None,
        Up,
        Down
    }

    struct Round {
        uint256 epoch;
        uint256 openTimestamp;
        uint256 startTimestamp;
        uint256 closeTimestamp;
        int256 startPrice;
        int256 closePrice;
        uint256 startOracleId;
        uint256 closeOracleId;
        uint256 totalAmount;
        uint256 overAmount;
        uint256 underAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        bool oracleCalled;
    }

    struct ParticipateInfo {
        Position position;
        uint256 amount;
        bool claimed; // default false
    }

    event ParticipateUnder(
        address indexed sender,
        uint256 indexed epoch,
        uint256 amount
    );
    event ParticipateOver(
        address indexed sender,
        uint256 indexed epoch,
        uint256 amount
    );
    event Claim(
        address indexed sender,
        uint256 indexed epoch,
        Position position,
        uint256 amount
    );
    event EndRound(uint256 indexed epoch, int256 price);
    event StartRound(uint256 indexed epoch, int256 price);
    event PythPriceInfo(int64 price, uint publishTime);

    event NewAdminAddress(address admin);
    event NewBufferAndIntervalSeconds(
        uint256 bufferSeconds,
        uint256 intervalSeconds
    );
    event NewMinParticipateAmount(
        uint256 indexed epoch,
        uint256 minParticipateAmount
    );
    event NewCommissionfee(uint256 indexed epoch, uint256 commissionfee);
    event NewOperatorAddress(address operator);
    event NewOperatorVaultAddress(address operatorVault);
    event NewOracle(address oracle);

    event Pause(uint256 indexed epoch);
    event RewardsCalculated(
        uint256 indexed epoch,
        uint256 rewardBaseCalAmount,
        uint256 rewardAmount,
        uint256 treasuryAmount
    );

    event OpenRound(
        uint256 indexed epoch,
        int256 strategyRate,
        StrategyType strategyType
    );
    event TokenRecovery(address indexed token, uint256 amount);
    event TreasuryClaim(uint256 amount);
    event Unpause(uint256 indexed epoch);

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Not admin");
        _;
    }

    modifier onlyAdminOrOperator() {
        require(
            msg.sender == adminAddress ||
                msg.sender == operatorAddress,
            "Not operator/admin"
        );
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    /**
     * @notice Constructor
     * @param _token: prediction token
     * @param _oracleAddress: oracle address
     * @param _adminAddress: admin address
     * @param _operatorAddress: operator address
     * @param _operatorVaultAddress: operator vault address
     * @param _commissionfee: commission fee (1000 = 10%)
     * @param _operateRate: operate rate (10000 = 100%)
     * @param _strategyRate: strategy rate (100 = 1%)
     * @param _strategyType: strategy type
     * @param _priceId: pyth price address
     */
    constructor(
        address _token,
        address _oracleAddress,
        address _adminAddress,
        address _operatorAddress,
        address _operatorVaultAddress,
        uint256 _commissionfee,
        uint256 _operateRate,
        int256 _strategyRate,
        StrategyType _strategyType,
        bytes32 _priceId
    ) {
        require(
            _commissionfee <= MAX_COMMISSION_FEE,
            "Commission fee too high"
        );
        if (_strategyRate > 0) {
            require(
                _strategyType != StrategyType.None,
                "Strategy Type must be Up or Down"
            );
        } else {
            require(
                _strategyType == StrategyType.None,
                "Strategy Type must be None"
            );
        }

        token = IERC20(_token);
        oracle = IPyth(_oracleAddress);
        adminAddress = _adminAddress;
        operatorAddress = _operatorAddress;
        operatorVaultAddress = _operatorVaultAddress;
        commissionfee = _commissionfee;
        operateRate = _operateRate;
        strategyRate = _strategyRate;
        strategyType = _strategyType;
        priceId = _priceId;

        intervalSeconds = DEFAULT_INTERVAL_SECONDS;
        bufferSeconds = DEFAULT_BUFFER_SECONDS;
        minParticipateAmount = DEFAULT_MIN_PARTICIPATE_AMOUNT;
    }

    /**
     * @notice Participate under position
     * @param epoch: epoch
     */
    function participateUnder(
        uint256 epoch,
        uint256 _amount
    ) external whenNotPaused nonReentrant notContract {
        require(epoch == currentEpoch, "Participate is too early/late");
        require(_participable(epoch), "Round not participable");
        require(
            _amount >= minParticipateAmount,
            "Participate amount must be greater than minParticipateAmount"
        );

        token.safeTransferFrom(msg.sender, address(this), _amount);
        // Update round data
        uint256 amount = _amount;
        Round storage round = rounds[epoch];
        round.totalAmount = round.totalAmount + amount;
        round.underAmount = round.underAmount + amount;

        // Update user data
        ParticipateInfo storage participateInfo = ledger[epoch][Position.Under][
            msg.sender
        ];
        participateInfo.position = Position.Under;
        participateInfo.amount = participateInfo.amount + amount;
        userRounds[msg.sender].push(epoch);

        emit ParticipateUnder(msg.sender, epoch, amount);
    }

    /**
     * @notice Participate over position
     * @param epoch: epoch
     */
    function participateOver(
        uint256 epoch,
        uint256 _amount
    ) external whenNotPaused nonReentrant notContract {
        require(epoch == currentEpoch, "Participate is too early/late");
        require(_participable(epoch), "Round not participable");
        require(
            _amount >= minParticipateAmount,
            "Participate amount must be greater than minParticipateAmount"
        );

        token.safeTransferFrom(msg.sender, address(this), _amount);
        // Update round data
        uint256 amount = _amount;
        Round storage round = rounds[epoch];
        round.totalAmount = round.totalAmount + amount;
        round.overAmount = round.overAmount + amount;

        // Update user data
        ParticipateInfo storage participateInfo = ledger[epoch][Position.Over][
            msg.sender
        ];
        participateInfo.position = Position.Over;
        participateInfo.amount = participateInfo.amount + amount;
        userRounds[msg.sender].push(epoch);

        emit ParticipateOver(msg.sender, epoch, amount);
    }

    /**
     * @notice Claim reward for an epoch
     * @param epoch: epoch
     */
    function claim(
        uint256 epoch,
        Position position
    ) external nonReentrant notContract {
        uint256 reward; // Initializes reward

        require(rounds[epoch].openTimestamp != 0, "Round has not started");
        require(
            block.timestamp > rounds[epoch].closeTimestamp,
            "Round has not ended"
        );

        uint256 addedReward = 0;

        // Round valid, claim rewards
        if (rounds[epoch].oracleCalled) {
            require(
                claimable(epoch, position, msg.sender),
                "Not eligible for claim"
            );
            Round memory round = rounds[epoch];
            if ((round.overAmount > 0 && round.underAmount > 0) && (round.startPrice != round.closePrice)) {
                addedReward +=
                    (ledger[epoch][position][msg.sender].amount *
                        round.rewardAmount) /
                    round.rewardBaseCalAmount;
            } else {
                // no winner
            }
        } else {
            // Round invalid, refund Participate amount
            require(
                refundable(epoch, position, msg.sender),
                "Not eligible for refund"
            );
        }
        ledger[epoch][position][msg.sender].claimed = true;
        reward = ledger[epoch][position][msg.sender].amount + addedReward;

        emit Claim(msg.sender, epoch, position, reward);

        if (reward > 0) {
            token.safeTransfer(msg.sender, reward);
        }
    }

    /**
     * @notice Claim all reward for user
     */
    function claimAll() external nonReentrant notContract {
        _trasferReward(msg.sender);
    }

    /**
     * @notice redeem all assets
     * @dev Callable by admin
     */
    function redeemAll(address _user) external whenPaused onlyAdmin {
        _trasferReward(_user);
    }

    /**
     * @notice Open the next round n, lock price for round n-1, end round n-2
     * @dev Callable by operator
     */
    function executeRound(
        int64 pythPrice,
        uint256 initDate
    ) external whenNotPaused onlyOperator {
        require(
            genesisOpenOnce && genesisStartOnce,
            "Can only run after genesisOpenRound and genesisStartRound is triggered"
        );

        // CurrentEpoch refers to previous round (n-1)
        _safeStartRound(currentEpoch, pythPrice);
        _safeEndRound(currentEpoch - 1, pythPrice);
        _calculateRewards(currentEpoch - 1);

        // Increment currentEpoch to current round (n)
        currentEpoch = currentEpoch + 1;
        _safeOpenRound(currentEpoch, initDate);
    }

    function executePythPriceUpdate(
        bytes[] calldata priceUpdateData
    ) external payable whenNotPaused onlyOperator {
        uint fee = oracle.getUpdateFee(priceUpdateData);
        oracle.updatePriceFeeds{value: fee}(priceUpdateData);
        PythStructs.Price memory pythPrice = oracle.getPrice(priceId);

        emit PythPriceInfo(pythPrice.price, pythPrice.publishTime);
    }

    /**
     * @notice Start genesis round
     * @dev Callable by operator
     */
    function genesisStartRound(
        int64 pythPrice,
        uint256 initDate
    ) external whenNotPaused onlyOperator {
        require(
            genesisOpenOnce,
            "Can only run after genesisOpenRound is triggered"
        );
        require(!genesisStartOnce, "Can only run genesisStartRound once");

        _safeStartRound(currentEpoch, pythPrice);

        currentEpoch = currentEpoch + 1;
        _openRound(currentEpoch, initDate);
        genesisStartOnce = true;
    }

    /**
     * @notice Open genesis round
     * @dev Callable by admin or operator
     */
    function genesisOpenRound(
        uint256 initDate
    ) external whenNotPaused onlyOperator {
        require(!genesisOpenOnce, "Can only run genesisOpenRound once");

        currentEpoch = currentEpoch + 1;
        _openRound(currentEpoch, initDate);
        genesisOpenOnce = true;
    }

    /**
     * @notice called by the admin to pause, triggers stopped state
     * @dev Callable by admin or operator
     */
    function pause() external whenNotPaused onlyAdminOrOperator {
        _pause();
        emit Pause(currentEpoch);
    }

    /**
     * @notice Claim all rewards in treasury
     * @dev Callable by admin
     */
    function claimTreasury() external nonReentrant onlyAdmin {
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;

        // operator 100%
        token.safeTransfer(
            operatorVaultAddress,
            (currentTreasuryAmount * operateRate) / BASE
        );

        emit TreasuryClaim(currentTreasuryAmount);
    }

    /**
     * @notice called by the admin to unpause, returns to normal state
     * Reset genesis state. Once paused, the rounds would need to be kickstarted by genesis
     * @dev Callable by admin or operator 
     */
    function unpause() external whenPaused onlyAdminOrOperator {
        genesisOpenOnce = false;
        genesisStartOnce = false;
        _unpause();

        emit Unpause(currentEpoch);
    }

    /**
     * @notice Set buffer and interval (in seconds)
     * @dev Callable by admin
     */
    function setBufferAndIntervalSeconds(
        uint256 _bufferSeconds,
        uint256 _intervalSeconds
    ) external whenPaused onlyAdmin {
        require(
            _bufferSeconds < _intervalSeconds,
            "bufferSeconds must be inferior to intervalSeconds"
        );
        bufferSeconds = _bufferSeconds;
        intervalSeconds = _intervalSeconds;

        emit NewBufferAndIntervalSeconds(_bufferSeconds, _intervalSeconds);
    }

    /**
     * @notice Set operator address
     * @dev Callable by admin
     */
    function setOperator(address _operatorAddress) external onlyAdmin {
        require(_operatorAddress != address(0), "Cannot be zero address");
        operatorAddress = _operatorAddress;
        emit NewOperatorAddress(_operatorAddress);
    }
    
    /**
     * @notice Set operator vault address
     * @dev Callable by admin
     */
    function setOperatorVault(
        address _operatorVaultAddress
    ) external onlyAdmin {
        require(
            _operatorVaultAddress != address(0),
            "Cannot be zero address"
        );
        operatorVaultAddress = _operatorVaultAddress;
        emit NewOperatorVaultAddress(_operatorVaultAddress);
    }

    /**
     * @notice Set Oracle address
     * @dev Callable by admin
     */
    function setOracle(address _oracle) external whenPaused onlyAdmin {
        require(_oracle != address(0), "Cannot be zero address");
        oracle = IPyth(_oracle);

        emit NewOracle(_oracle);
    }

    /**
     * @notice Set treasury fee
     * @dev Callable by admin
     */
    function setCommissionfee(
        uint256 _commissionfee
    ) external whenPaused onlyAdmin {
        require(
            _commissionfee <= MAX_COMMISSION_FEE,
            "Commission fee too high"
        );
        commissionfee = _commissionfee;
        emit NewCommissionfee(currentEpoch, commissionfee);
    }

    function _trasferReward(address _user) internal {
        uint256 reward = 0; // Initializes reward

        for (uint256 epoch = 1; epoch <= currentEpoch; epoch++) {
            if (rounds[epoch].startTimestamp == 0 || (block.timestamp < rounds[epoch].closeTimestamp + bufferSeconds)) continue;

            Round memory round = rounds[epoch];
            // 0: Over, 1: Under
            uint8 pst = 0;
            while(pst <= uint(Position.Under)) {
                Position position = pst == 0 ? Position.Over : Position.Under;
                uint256 addedReward = 0;

                // Round vaild, claim rewards
                if (claimable(epoch, position, _user)) {
                    if ((round.overAmount > 0 && round.underAmount > 0) && (round.startPrice != round.closePrice)) {
                        addedReward +=
                            (ledger[epoch][position][_user].amount *
                                round.rewardAmount) /
                            round.rewardBaseCalAmount;
                    }
                    addedReward += ledger[epoch][position][_user].amount;
                } else {
                    // Round invaild, refund bet amount
                    if (refundable(epoch, position, _user)) {
                        addedReward += ledger[epoch][position][_user].amount;
                    }
                }

                if (addedReward != 0) {
                    ledger[epoch][position][_user].claimed = true;
                    reward += addedReward;
                    emit Claim(_user, epoch, position, addedReward);
                }
                pst++;
            }
        }

        if (reward > 0) {
            token.safeTransfer(_user, reward);
        }
    }

    /**
     * @notice Set admin address
     * @dev Callable by owner
     */
    function setAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0), "Cannot be zero address");
        adminAddress = _adminAddress;

        emit NewAdminAddress(_adminAddress);
    }


    /**
     * @notice Returns round epochs and participate information for a user that has participated
     * @param user: user address
     * @param cursor: cursor
     * @param size: size
     */
    function getUserRounds(
        address user,
        uint256 cursor,
        uint256 size
    )
        external
        view
        returns (
            uint256[] memory,
            ParticipateInfo[] memory,
            ParticipateInfo[] memory,
            uint256
        )
    {
        uint256 length = size;

        if (length > userRounds[user].length - cursor) {
            length = userRounds[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        ParticipateInfo[] memory overParticipateInfo = new ParticipateInfo[](
            length
        );
        ParticipateInfo[] memory underParticipateInfo = new ParticipateInfo[](
            length
        );

        for (uint256 i = 0; i < length; i++) {
            values[i] = userRounds[user][cursor + i];
            for (uint8 j = 0; j < 2; j++) {
                Position p = (j == 0) ? Position.Over : Position.Under;
                if (p == Position.Over) {
                    overParticipateInfo[i] = ledger[values[i]][p][user];
                } else {
                    underParticipateInfo[i] = ledger[values[i]][p][user];
                }
            }
        }

        return (
            values,
            overParticipateInfo,
            underParticipateInfo,
            cursor + length
        );
    }

    /**
     * @notice Returns round epochs length
     * @param user: user address
     */
    function getUserRoundsLength(address user) external view returns (uint256) {
        return userRounds[user].length;
    }

    /**
     * @notice Get the claimable stats of specific epoch and user account
     * @param epoch: epoch
     * @param position: Position
     * @param user: user address
     */
    function claimable(
        uint256 epoch,
        Position position,
        address user
    ) public view returns (bool) {
        ParticipateInfo memory participateInfo = ledger[epoch][position][user];
        Round memory round = rounds[epoch];
        
        bool isPossible = false;
        if (round.overAmount > 0 && round.underAmount > 0) {
            isPossible = ((round.closePrice > _getStrategyRatePrice(round.startPrice) &&
                participateInfo.position == Position.Over) ||
                (round.closePrice < _getStrategyRatePrice(round.startPrice) &&
                    participateInfo.position == Position.Under) ||
                (round.closePrice == _getStrategyRatePrice(round.startPrice)));
        } else {
            // refund user's fund if there is no paticipation on the other side
            isPossible = true;
        }

        return
            round.oracleCalled &&
            participateInfo.amount != 0 &&
            !participateInfo.claimed && isPossible;
    }

    /**
     * @notice Get the refundable stats of specific epoch and user account
     * @param epoch: epoch
     * @param user: user address
     */
    function refundable(
        uint256 epoch,
        Position position,
        address user
    ) public view returns (bool) {
        ParticipateInfo memory participateInfo = ledger[epoch][position][user];
        Round memory round = rounds[epoch];
        return
            !round.oracleCalled &&
            !participateInfo.claimed &&
            block.timestamp > round.closeTimestamp + bufferSeconds &&
            participateInfo.amount != 0;
    }

    /**
     * @notice Calculate rewards for round
     * @param epoch: epoch
     */
    function _calculateRewards(uint256 epoch) internal {
        require(
            rounds[epoch].rewardBaseCalAmount == 0 &&
                rounds[epoch].rewardAmount == 0,
            "Rewards calculated"
        );
        Round storage round = rounds[epoch];
        uint256 rewardBaseCalAmount;
        uint256 treasuryAmt;
        uint256 rewardAmount;

        // No participation on the other side refund participant amount to users 
        if (round.overAmount == 0 || round.underAmount == 0) {
                rewardBaseCalAmount = 0;
                rewardAmount = 0;
                treasuryAmt = 0;
        } else {
            // Over wins
            if (round.closePrice > _getStrategyRatePrice(round.startPrice)) {
                rewardBaseCalAmount = round.overAmount;
                treasuryAmt = (round.underAmount * commissionfee) / BASE;
                rewardAmount = round.underAmount - treasuryAmt;
            }
            // Under wins
            else if (round.closePrice < _getStrategyRatePrice(round.startPrice)) {
                rewardBaseCalAmount = round.underAmount;
                treasuryAmt = (round.overAmount * commissionfee) / BASE;
                rewardAmount = round.overAmount - treasuryAmt;
            }
            // No one wins refund participant amount to users
            else {
                rewardBaseCalAmount = 0;
                rewardAmount = 0;
                treasuryAmt = 0;
            }
        }
        round.rewardBaseCalAmount = rewardBaseCalAmount;
        round.rewardAmount = rewardAmount;

        // Add to treasury
        treasuryAmount += treasuryAmt;

        emit RewardsCalculated(
            epoch,
            rewardBaseCalAmount,
            rewardAmount,
            treasuryAmt
        );
    }

    /**
     * @notice Calculate start price applied with strategy Rate
     * @param price: start price
     */
    function _getStrategyRatePrice(
        int256 price
    ) internal view returns (int256) {
        if (strategyType == StrategyType.Up) {
            return price + (price * strategyRate) / int256(BASE);
        } else if (strategyType == StrategyType.Down) {
            return price - (price * strategyRate) / int256(BASE);
        } else {
            return price;
        }
    }

    /**
     * @notice End round
     * @param epoch: epoch
     * @param price: price of the round
     */
    function _safeEndRound(uint256 epoch, int256 price) internal {
        require(
            rounds[epoch].startTimestamp != 0,
            "Can only end round after round has locked"
        );
        require(
            block.timestamp >= rounds[epoch].closeTimestamp,
            "Can only end round after closeTimestamp"
        );
        require(
            block.timestamp <= rounds[epoch].closeTimestamp + bufferSeconds,
            "Can only end round within bufferSeconds"
        );
        Round storage round = rounds[epoch];
        round.closePrice = price;
        round.oracleCalled = true;

        emit EndRound(epoch, round.closePrice);
    }

    /**
     * @notice Start round
     * @param epoch: epoch
     * @param price: price of the round
     */
    function _safeStartRound(uint256 epoch, int256 price) internal {
        require(
            rounds[epoch].openTimestamp != 0,
            "Can only lock round after round has started"
        );
        require(
            block.timestamp >= rounds[epoch].startTimestamp,
            "Can only start round after startTimestamp"
        );
        require(
            block.timestamp <= rounds[epoch].startTimestamp + bufferSeconds,
            "Can only start round within bufferSeconds"
        );
        Round storage round = rounds[epoch];
        round.startPrice = price;

        emit StartRound(epoch, round.startPrice);
    }

    /**
     * @notice Open round
     * Previous round n-2 must end
     * @param epoch: epoch
     * @param initDate: initDate
     */
    function _safeOpenRound(uint256 epoch, uint256 initDate) internal {
        require(
            genesisOpenOnce,
            "Can only run after genesisOpenRound is triggered"
        );
        require(
            rounds[epoch - 2].closeTimestamp != 0,
            "Can only open round after round n-2 has ended"
        );
        require(
            block.timestamp >= rounds[epoch - 2].closeTimestamp,
            "Can only open new round after round n-2 closeTimestamp"
        );
        require(
            block.timestamp >= initDate,
            "Can only open new round after init date"
        );
        _openRound(epoch, initDate);
    }

    /**
     * @notice Start round
     * Previous round n-2 must end
     * @param epoch: epoch
     * @param initDate: initDate
     */
    function _openRound(uint256 epoch, uint256 initDate) internal {
        require(
            block.timestamp >= initDate,
            "Can only open new round after init date"
        );

        Round storage round = rounds[epoch];
        round.openTimestamp = initDate;
        round.startTimestamp = initDate + intervalSeconds;
        round.closeTimestamp = initDate + (2 * intervalSeconds);
        round.epoch = epoch;
        round.totalAmount = 0;

        emit OpenRound(epoch, strategyRate, strategyType);
    }

    /**
     * @notice Determine if a round is valid for receiving bets
     * Round must have started and locked
     * Current timestamp must be within openTimestamp and closeTimestamp
     */
    function _participable(uint256 epoch) internal view returns (bool) {
        return
            rounds[epoch].openTimestamp != 0 &&
            rounds[epoch].startTimestamp != 0 &&
            block.timestamp > rounds[epoch].openTimestamp &&
            block.timestamp < rounds[epoch].startTimestamp;
    }

    /**
     * @notice Returns true if `account` is a contract.
     * @param account: account address
     */
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    event TestEvent(uint256 data);
}
