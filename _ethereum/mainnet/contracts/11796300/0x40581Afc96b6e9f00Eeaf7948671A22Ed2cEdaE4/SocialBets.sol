// SPDX-License-Identifier: No License
pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

contract SocialBets is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address payable;

    // Type definitions
    enum BetStates {WaitingParty2, WaitingFirstVote, WaitingSecondVote, WaitingMediator}
    enum BetCancellationReasons {Party2Timeout, VotesTimeout, Tie, MediatorTimeout, MediatorCancelled}
    enum BetFinishReasons {AnswersMatched, MediatorFinished}
    enum Answers {Unset, FirstPartyWins, SecondPartyWins, Tie}
    struct Bet {
        string metadata;
        address payable firstParty;
        address payable secondParty;
        address payable mediator;
        uint256 firstBetValue;
        uint256 secondBetValue;
        uint256 mediatorFee;
        uint256 secondPartyTimeframe;
        uint256 resultTimeframe;
        BetStates state;
        Answers firstPartyAnswer; // answers: 0 - unset, 1 - first party wins, 2 - second party wins, 3 - tie
        Answers secondPartyAnswer;
    }

    // Storage

    //betId => bet
    mapping(uint256 => Bet) public bets;

    // user => active bets[]
    mapping(address => uint256[]) public firstPartyActiveBets;
    // user => (betId => bet index in the active bets[])
    mapping(address => mapping(uint256 => uint256)) public firstPartyActiveBetsIndexes;
    // user => active bets[]
    mapping(address => uint256[]) public secondPartyActiveBets;
    // user => (betId => bet index in the active bets[])
    mapping(address => mapping(uint256 => uint256)) public secondPartyActiveBetsIndexes;
    // user => active bets[]
    mapping(address => uint256[]) public mediatorActiveBets;
    // user => (betId => bet index in the active bets[])
    mapping(address => mapping(uint256 => uint256)) public mediatorActiveBetsIndexes;

    // fee value collected fot the owner to withdraw
    uint256 public collectedFee;

    // Storage: Admin Settings
    uint256 public minBetValue;
    // bet creation fee
    uint256 public feePercentage;
    // mediator settings
    address payable public defaultMediator;
    uint256 public defaultMediatorFee;
    uint256 public mediationTimeLimit = 7 days;

    // Constants
    uint256 public constant FEE_DECIMALS = 2;
    uint256 public constant FEE_PERCENTAGE_DIVISION = 10000;
    uint256 public constant MEDIATOR_FEE_DIVISION = 10000;

    // Events

    event NewBetCreated(
        uint256 indexed _betId,
        address indexed _firstParty,
        address indexed _secondParty,
        string _metadata,
        address _mediator,
        uint256 _mediatorFee,
        uint256 _firstBetValue,
        uint256 _secondBetValue,
        uint256 _secondPartyTimeframe,
        uint256 _resultTimeframe
    );

    event SecondPartyParticipated(uint256 indexed _betId, address indexed _firstParty, address indexed _secondParty);

    event Voted(uint256 indexed _betId, address indexed _voter, Answers indexed _answer);

    event WaitingMediator(uint256 indexed _betId, address indexed _mediator);

    event Finished(uint256 indexed _betId, address indexed _winner, BetFinishReasons indexed _reason, uint256 _reward);

    event Cancelled(uint256 indexed _betId, BetCancellationReasons indexed _reason);

    event Completed(
        address indexed _firstParty,
        address indexed _secondParty,
        address indexed _mediator,
        uint256 _betId
    );

    //Constructor
    constructor(
        uint256 _feePercentage,
        uint256 _minBetValue,
        uint256 _defaultMediatorFee,
        address payable _defaultMediator
    ) public {
        require(_feePercentage <= FEE_PERCENTAGE_DIVISION, "Bad fee");
        require(_defaultMediatorFee <= MEDIATOR_FEE_DIVISION, "Bad mediator fee");
        require(_defaultMediator != address(0) && !_defaultMediator.isContract(), "Bad mediator");
        minBetValue = _minBetValue;
        feePercentage = _feePercentage;
        defaultMediatorFee = _defaultMediatorFee;
        defaultMediator = _defaultMediator;
    }

    // Modifiers

    /**
     * @dev Checks if bet exists in the bet mapping
     */
    modifier onlyExistingBet(uint256 _betId) {
        require(isBetExists(_betId), "Bet doesn't exist");
        _;
    }

    /**
     * @dev Checks is sender isn't contract
     * [IMPORTANT]
     * ====
     * This modifier will allow the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    modifier onlyNotContract() {
        require(!msg.sender.isContract(), "Contracts are prohibited");
        _;
    }

    // Getters

    /**
     * @dev Returns first party active bets
     */
    function getFirstPartyActiveBets(address _firstParty) external view returns (uint256[] memory betsIds) {
        betsIds = firstPartyActiveBets[_firstParty];
    }

    /**
     * @dev Returns second party active bets
     */
    function getSecondPartyActiveBets(address _secondParty) external view returns (uint256[] memory betsIds) {
        betsIds = secondPartyActiveBets[_secondParty];
    }

    /**
     * @dev Returns mediator active bets
     */
    function getMediatorActiveBets(address _mediator) external view returns (uint256[] memory betsIds) {
        betsIds = mediatorActiveBets[_mediator];
    }

    /**
     * @dev Returns bet ID calculated from constant bet properties
     */
    function calculateBetId(
        string memory _metadata,
        address _firstParty,
        uint256 _firstBetValue,
        uint256 _secondBetValue,
        uint256 _secondPartyTimeframe,
        uint256 _resultTimeframe
    ) public pure returns (uint256 betId) {
        betId = uint256(
            keccak256(
                abi.encode(
                    _metadata,
                    _firstParty,
                    _firstBetValue,
                    _secondBetValue,
                    _secondPartyTimeframe,
                    _resultTimeframe
                )
            )
        );
    }

    /**
     * @dev Check if bet exists
     */
    function isBetExists(uint256 _betId) public view returns (bool isExists) {
        isExists = bets[_betId].firstParty != address(0);
    }

    /**
     * @dev Returns fee value from bet values
     */
    function calculateFee(uint256 _firstBetValue, uint256 _secondBetValue) public view returns (uint256 fee) {
        fee = _firstBetValue.add(_secondBetValue).mul(feePercentage).div(FEE_PERCENTAGE_DIVISION);
    }

    /**
     * @dev Returns mediator fee value
     */
    function calculateMediatorFee(uint256 _betId) public view returns (uint256 mediatorFeeValue) {
        Bet storage bet = bets[_betId];
        mediatorFeeValue = bet.firstBetValue.add(bet.secondBetValue).mul(bet.mediatorFee).div(MEDIATOR_FEE_DIVISION);
    }

    // Admin functionality

    /**
     * @dev Set new min bet value
     */
    function setMinBetValue(uint256 _minBetValue) external onlyOwner {
        minBetValue = _minBetValue;
    }

    /**
     * @dev Set new fee percentage
     */
    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= FEE_PERCENTAGE_DIVISION, "Bad fee");
        feePercentage = _feePercentage;
    }

    /**
     * @dev Set new default mediator fee
     */
    function setDefaultMediatorFee(uint256 _defaultMediatorFee) external onlyOwner {
        require(_defaultMediatorFee <= MEDIATOR_FEE_DIVISION, "Bad mediator fee");
        defaultMediatorFee = _defaultMediatorFee;
    }

    /**
     * @dev Set new default mediator
     */
    function setDefaultMediator(address payable _defaultMediator) external onlyOwner {
        require(_defaultMediator != address(0) && !_defaultMediator.isContract(), "Bad mediator");
        defaultMediator = _defaultMediator;
    }

    /**
     * @dev Set new mediation time limit
     */
    function setMediationTimeLimit(uint256 _mediationTimeLimit) external onlyOwner {
        require(_mediationTimeLimit > 0, "Bad mediationTimeLimit");
        mediationTimeLimit = _mediationTimeLimit;
    }

    /**
     * @dev Pause the contract. This will disable new bet creation functionality
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract. This will enable new bet creation functionality
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Withdraws collected fee
     */
    function withdrawFee() external onlyOwner {
        require(collectedFee > 0, "No fee to withdraw");
        msg.sender.transfer(collectedFee);
    }

    // Users functionality

    /**
     * @dev Creates new bet with specified characteristics. msg.sender will be set as the first party,
     *      so creation needs to be payed with first party bet value + fee.
     */
    function createBet(
        string memory _metadata,
        address payable _secondParty,
        address payable _mediator,
        uint256 _mediatorFee,
        uint256 _firstBetValue,
        uint256 _secondBetValue,
        uint256 _secondPartyTimeframe,
        uint256 _resultTimeframe
    ) external payable whenNotPaused onlyNotContract nonReentrant returns (uint256 betId) {
        require(_firstBetValue >= minBetValue && _secondBetValue >= minBetValue, "Too small bet value");
        require(_secondPartyTimeframe > now, "2nd party timeframe < now");
        require(_resultTimeframe > now, "Result timeframe < now");
        require(_resultTimeframe > _secondPartyTimeframe, "Result < 2nd party timeframe");
        require(
            msg.sender != _secondParty &&
                msg.sender != _mediator &&
                (_secondParty != _mediator || _secondParty == address(0)),
            "Bad mediator or second party"
        );
        uint256 fee = calculateFee(_firstBetValue, _secondBetValue);
        require(msg.value == _firstBetValue.add(fee), "Bad eth value");
        collectedFee = collectedFee.add(fee);

        betId = calculateBetId(
            _metadata,
            msg.sender,
            _firstBetValue,
            _secondBetValue,
            _secondPartyTimeframe,
            _resultTimeframe
        );
        require(!isBetExists(betId), "Bet already exists");

        Bet storage newBet = bets[betId];
        newBet.metadata = _metadata;
        newBet.firstParty = msg.sender;
        newBet.secondParty = _secondParty;

        if (_mediator == address(0) || _mediator == defaultMediator) {
            newBet.mediator = defaultMediator;
            newBet.mediatorFee = defaultMediatorFee;
        } else {
            newBet.mediator = _mediator;
            require(_mediatorFee <= MEDIATOR_FEE_DIVISION, "Bad mediator fee");
            newBet.mediatorFee = _mediatorFee;
        }
        newBet.firstBetValue = _firstBetValue;
        newBet.secondBetValue = _secondBetValue;
        newBet.secondPartyTimeframe = _secondPartyTimeframe;
        newBet.resultTimeframe = _resultTimeframe;

        firstPartyActiveBets[msg.sender].push(betId);
        firstPartyActiveBetsIndexes[msg.sender][betId] = firstPartyActiveBets[msg.sender].length.sub(1);

        emit NewBetCreated(
            betId,
            newBet.firstParty,
            newBet.secondParty,
            newBet.metadata,
            newBet.mediator,
            newBet.mediatorFee,
            newBet.firstBetValue,
            newBet.secondBetValue,
            newBet.secondPartyTimeframe,
            newBet.resultTimeframe
        );
    }

    /**
     * @dev Second party participating function. Cancels bet if party 2 is late for participating
     */
    function participate(uint256 _betId)
        external
        payable
        onlyExistingBet(_betId)
        onlyNotContract
        nonReentrant
        returns (bool success)
    {
        Bet storage bet = bets[_betId];
        require(bet.state == BetStates.WaitingParty2, "Party 2 already joined");
        require(msg.sender != bet.firstParty && msg.sender != bet.mediator, "You are first party or mediator");
        require(bet.secondParty == address(0) || bet.secondParty == msg.sender, "Private bet");
        require(msg.value == bet.secondBetValue, "Bad eth value");

        if (bet.secondPartyTimeframe > now) {
            success = true;
            bet.secondParty = msg.sender;
            bet.state = BetStates.WaitingFirstVote;

            secondPartyActiveBets[msg.sender].push(_betId);
            secondPartyActiveBetsIndexes[msg.sender][_betId] = secondPartyActiveBets[msg.sender].length.sub(1);

            emit SecondPartyParticipated(_betId, bet.firstParty, bet.secondParty);
        } else {
            success = false;
            cancelBet(_betId, BetCancellationReasons.Party2Timeout);
            msg.sender.transfer(msg.value);
        }
    }

    /**
     * @dev First and second partie's function for setting answer.
     *      If answer waiting time has expired and nobody set the answer then bet cancels.
     *      If one party didn't set the answer before timeframe the bet waits for mediator.
     */
    function vote(uint256 _betId, Answers _answer) external onlyExistingBet(_betId) {
        Bet storage bet = bets[_betId];

        require(_answer != Answers.Unset, "Wrong answer");
        require(
            bet.state == BetStates.WaitingFirstVote || bet.state == BetStates.WaitingSecondVote,
            "Bet isn't waiting for votes"
        );
        require(msg.sender == bet.firstParty || msg.sender == bet.secondParty, "You aren't participating");

        if (bet.resultTimeframe < now) {
            if (bet.state == BetStates.WaitingFirstVote) {
                cancelBet(_betId, BetCancellationReasons.VotesTimeout);
                return;
            } else {
                bet.state = BetStates.WaitingMediator;

                addMediatorActiveBet(bet.mediator, _betId);

                emit WaitingMediator(_betId, bet.mediator);
                return;
            }
        }

        if (bet.firstParty == msg.sender && bet.firstPartyAnswer == Answers.Unset) {
            bet.firstPartyAnswer = _answer;
        } else if (bet.secondParty == msg.sender && bet.secondPartyAnswer == Answers.Unset) {
            bet.secondPartyAnswer = _answer;
        } else {
            revert("You can't change your answer");
        }
        emit Voted(_betId, msg.sender, _answer);

        if (bet.state == BetStates.WaitingFirstVote) {
            bet.state = BetStates.WaitingSecondVote;
            return;
        } else {
            if (bet.firstPartyAnswer != bet.secondPartyAnswer) {
                bet.state = BetStates.WaitingMediator;

                addMediatorActiveBet(bet.mediator, _betId);

                emit WaitingMediator(_betId, bet.mediator);
                return;
            } else {
                finishBet(_betId, bet.firstPartyAnswer, BetFinishReasons.AnswersMatched);
            }
        }
    }

    /**
     * @dev Mediator's setting an answer function. If mediating time has expired
     *      then bet will be cancelled
     */
    function mediate(uint256 _betId, Answers _answer) external onlyExistingBet(_betId) {
        Bet storage bet = bets[_betId];
        require(_answer != Answers.Unset, "Wrong answer");
        require(bet.state == BetStates.WaitingMediator, "Bet isn't waiting for mediator");
        require(bet.mediator == msg.sender, "You can't mediate this bet");

        if (now > bet.resultTimeframe && now.sub(bet.resultTimeframe) > mediationTimeLimit) {
            cancelBet(_betId, BetCancellationReasons.MediatorTimeout);
            return;
        }

        payToMediator(_betId);
        finishBet(_betId, _answer, BetFinishReasons.MediatorFinished);
    }

    // Management handlers

    /**
     * @dev Checks secondPartyTimeframe. Cancels bet if party 2 is late for participating
     */
    function party2TimeoutHandler(uint256 _betId) external onlyExistingBet(_betId) {
        Bet storage bet = bets[_betId];
        require(bet.state == BetStates.WaitingParty2, "Bet isn't waiting for party 2");
        require(bet.secondPartyTimeframe <= now, "There is no timeout");
        cancelBet(_betId, BetCancellationReasons.Party2Timeout);
    }

    /**
     * @dev Checks bet's resultTimeframe. If answer waiting time has expired and nobody set the answer then bet cancels.
     *      If one party didn't set the answer before timeframe the bet waits for mediator.
     */
    function votesTimeoutHandler(uint256 _betId) external onlyExistingBet(_betId) {
        Bet storage bet = bets[_betId];
        require(
            bet.state == BetStates.WaitingFirstVote || bet.state == BetStates.WaitingSecondVote,
            "Bet isn't waiting for votes"
        );
        require(bet.resultTimeframe < now, "There is no timeout");

        if (bet.state == BetStates.WaitingFirstVote) {
            cancelBet(_betId, BetCancellationReasons.VotesTimeout);
            return;
        } else {
            bet.state = BetStates.WaitingMediator;

            addMediatorActiveBet(bet.mediator, _betId);

            emit WaitingMediator(_betId, bet.mediator);
            return;
        }
    }

    /**
     * @dev Checks mediator timeframe (resultTimeframe + mediationTimeLimit) and cancels bet if time has expired
     */
    function mediatorTimeoutHandler(uint256 _betId) external onlyExistingBet(_betId) {
        Bet storage bet = bets[_betId];
        require(bet.state == BetStates.WaitingMediator, "Bet isn't waiting for mediator");
        require(now > bet.resultTimeframe && now.sub(bet.resultTimeframe) > mediationTimeLimit, "There is no timeout");
        cancelBet(_betId, BetCancellationReasons.MediatorTimeout);
    }

    //Internals

    /**
     * @dev Finish bet and pay to the winner or cancel if tie
     */
    function finishBet(
        uint256 _betId,
        Answers _answer,
        BetFinishReasons _reason
    ) internal {
        Bet storage bet = bets[_betId];
        address payable firstParty = bet.firstParty;
        address payable mediator = bet.mediator;
        address payable secondParty = bet.secondParty;
        uint256 firstBetValue = bet.firstBetValue;
        uint256 secondBetValue = bet.secondBetValue;
        address payable winner;
        uint256 mediatorFeeValue = 0;
        if (_reason == BetFinishReasons.MediatorFinished) {
            mediatorFeeValue = calculateMediatorFee(_betId);

            deleteMediatorActiveBet(mediator, _betId);
        }
        if (_answer == Answers.FirstPartyWins) {
            winner = firstParty;
        } else if (_answer == Answers.SecondPartyWins) {
            winner = secondParty;
        } else {
            if (_reason == BetFinishReasons.MediatorFinished) {
                cancelBet(_betId, BetCancellationReasons.MediatorCancelled);
            } else {
                cancelBet(_betId, BetCancellationReasons.Tie);
            }
            return;
        }

        delete bets[_betId];

        deleteFirstPartyActiveBet(firstParty, _betId);
        deleteSecondPartyActiveBet(secondParty, _betId);

        winner.transfer(firstBetValue.add(secondBetValue).sub(mediatorFeeValue));
        emit Finished(_betId, winner, _reason, firstBetValue.add(secondBetValue).sub(mediatorFeeValue));
        emit Completed(firstParty, secondParty, mediator, _betId);
    }

    /**
     * @dev Cancel bet and return money to the parties.
     */
    function cancelBet(uint256 _betId, BetCancellationReasons _reason) internal {
        Bet storage bet = bets[_betId];
        uint256 mediatorFeeValue = 0;
        address payable mediator = bet.mediator;

        if (_reason == BetCancellationReasons.MediatorCancelled) {
            mediatorFeeValue = calculateMediatorFee(_betId);
        }

        if (_reason == BetCancellationReasons.MediatorTimeout) {
            deleteMediatorActiveBet(mediator, _betId);
        }

        address payable firstParty = bet.firstParty;
        address payable secondParty = bet.secondParty;
        bool isSecondPartyParticipating = bet.state != BetStates.WaitingParty2;
        uint256 firstBetValue = bet.firstBetValue;
        uint256 secondBetValue = bet.secondBetValue;

        delete bets[_betId];
        uint256 firstPartyMediatorFeeValue = mediatorFeeValue.div(2);

        firstParty.transfer(firstBetValue.sub(firstPartyMediatorFeeValue));

        deleteFirstPartyActiveBet(firstParty, _betId);

        if (isSecondPartyParticipating) {
            secondParty.transfer(secondBetValue.sub(mediatorFeeValue.sub(firstPartyMediatorFeeValue)));
            deleteSecondPartyActiveBet(secondParty, _betId);
        }
        emit Cancelled(_betId, _reason);
        emit Completed(firstParty, secondParty, mediator, _betId);
    }

    /**
     * @dev Add new active bet to mediator
     */
    function addMediatorActiveBet(address _mediator, uint256 _betId) internal {
        mediatorActiveBets[_mediator].push(_betId);
        mediatorActiveBetsIndexes[_mediator][_betId] = mediatorActiveBets[_mediator].length.sub(1);
    }

    /**
     * @dev Delete active bet from mediator's active bet's
     */
    function deleteMediatorActiveBet(address _mediator, uint256 _betId) internal {
        if (mediatorActiveBets[_mediator].length == 0) return;
        uint256 index = mediatorActiveBetsIndexes[_mediator][_betId];
        delete mediatorActiveBetsIndexes[_mediator][_betId];
        uint256 lastIndex = mediatorActiveBets[_mediator].length.sub(1);
        if (lastIndex != index) {
            uint256 movedBet = mediatorActiveBets[_mediator][lastIndex];
            mediatorActiveBetsIndexes[_mediator][movedBet] = index;
            mediatorActiveBets[_mediator][index] = mediatorActiveBets[_mediator][lastIndex];
        }
        mediatorActiveBets[_mediator].pop();
    }

    /**
     * @dev Delete active bet from first partie's active bet's
     */
    function deleteFirstPartyActiveBet(address _firstParty, uint256 _betId) internal {
        if (firstPartyActiveBets[_firstParty].length == 0) return;
        uint256 index = firstPartyActiveBetsIndexes[_firstParty][_betId];
        delete firstPartyActiveBetsIndexes[_firstParty][_betId];
        uint256 lastIndex = firstPartyActiveBets[_firstParty].length.sub(1);
        if (lastIndex != index) {
            uint256 movedBet = firstPartyActiveBets[_firstParty][lastIndex];
            firstPartyActiveBetsIndexes[_firstParty][movedBet] = index;
            firstPartyActiveBets[_firstParty][index] = firstPartyActiveBets[_firstParty][lastIndex];
        }
        firstPartyActiveBets[_firstParty].pop();
    }

    /**
     * @dev Delete active bet from second partie's active bet's
     */
    function deleteSecondPartyActiveBet(address _secondParty, uint256 _betId) internal {
        if (secondPartyActiveBets[_secondParty].length == 0) return;
        uint256 index = secondPartyActiveBetsIndexes[_secondParty][_betId];
        delete secondPartyActiveBetsIndexes[_secondParty][_betId];
        uint256 lastIndex = secondPartyActiveBets[_secondParty].length.sub(1);
        if (lastIndex != index) {
            uint256 movedBet = secondPartyActiveBets[_secondParty][lastIndex];
            secondPartyActiveBetsIndexes[_secondParty][movedBet] = index;
            secondPartyActiveBets[_secondParty][index] = secondPartyActiveBets[_secondParty][lastIndex];
        }
        secondPartyActiveBets[_secondParty].pop();
    }

    /**
     * @dev Transfers mediator fee to the mediator
     */
    function payToMediator(uint256 _betId) internal {
        Bet storage bet = bets[_betId];
        uint256 value = calculateMediatorFee(_betId);
        bet.mediator.transfer(value);
    }
}
