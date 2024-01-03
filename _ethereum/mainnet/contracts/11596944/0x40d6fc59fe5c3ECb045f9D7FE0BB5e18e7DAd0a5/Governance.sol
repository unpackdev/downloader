pragma solidity ^0.6.11;

import "./SafeMath.sol";
import "./Pausable.sol";
import "./IConfig.sol";
import "./IStaking.sol";
import "./Configurable.sol";
import "./Config.sol";
import "./AnkrDeposit.sol";

contract Governance is Pausable, AnkrDeposit {
    using SafeMath for uint256;

    event ConfigurationChanged(bytes32 indexed key, uint256 oldValue, uint256 newValue);
    event Vote(address indexed holder, bytes32 indexed ID, bytes32 vote, uint256 votes);
    event Propose(address indexed proposer, bytes32 proposeID, string topic, string content, uint span);
    event ProposalFinished(bytes32 indexed proposeID, bool result, uint256 yes, uint256 no);

    IConfig private configContract;
    IStaking private depositContract;

    bytes32 internal constant _spanLo_ = "Gov#spanLo";
    bytes32 internal constant _spanHi_ = "Gov#spanHi";
    bytes32 internal constant _proposalMinimumThreshold_ = "Gov#minimumDepositThreshold";

    bytes32 internal constant _startBlock_ = "Gov#startBlock";

    bytes32 internal constant _proposeTopic_ = "Gov#proposeTopic";
    bytes32 internal constant _proposeContent_ = "Gov#proposeContent";

    bytes32 internal constant _proposeEndAt_ = "Gov#ProposeEndAt";
    bytes32 internal constant _proposeStartAt_ = "Gov#ProposeStartAt";
    bytes32 internal constant _proposeTimelock_ = "Gov#ProposeTimelock";

    bytes32 internal constant _proposeCountLimit_ = "Gov#ProposeCountLimit";

    bytes32 internal constant _proposerLastProposeAt_ = "Gov#ProposerLastProposeAt";
    bytes32 internal constant _proposerProposeCountInMonth_ = "Gov#ProposeCountInMonth";

    bytes32 internal constant _proposer_ = "Gov#proposer";
    bytes32 internal constant _proposerHasActiveProposal_ = "Gov#hasActiveProposal";

    bytes32 internal constant _totalProposes_ = "Gov#proposer";
    bytes32 internal constant _minimumVoteAcceptance_ = "Gov#minimumVoteAcceptance";

    bytes32 internal constant _proposeID_ = "Gov#proposeID";
    bytes32 internal constant _proposeStatus_ = "Gov#proposeStatus";

    bytes32 internal constant _votes_ = "Gov#votes";
    bytes32 internal constant _voteCount_ = "Gov#voteCount";

    uint256 internal constant PROPOSE_STATUS_WAITING = 0;
    uint256 internal constant PROPOSE_STATUS_VOTING = 1;
    uint256 internal constant PROPOSE_STATUS_FAIL = 2;
    uint256 internal constant PROPOSE_STATUS_PASS = 3;
    uint256 internal constant PROPOSE_STATUS_CANCELED = 4;

    uint256 internal constant MONTH = 2592000;

    bytes32 internal constant VOTE_YES = "VOTE_YES";
    bytes32 internal constant VOTE_NO = "VOTE_NO";
    bytes32 internal constant VOTE_CANCEL = "VOTE_CANCEL";

    uint256 internal constant DIVISOR = 1 ether;

    function initialize(address ankrContract, address globalPoolContract, address aethContract) public initializer {
        __Ownable_init();
        deposit_init(ankrContract, globalPoolContract, aethContract);

        // minimum ankrs deposited needed for voting
        changeConfiguration(_proposalMinimumThreshold_, 5000000 ether);

        changeConfiguration("PROVIDER_MINIMUM_ANKR_STAKING", 100000 ether);
        changeConfiguration("PROVIDER_MINIMUM_ETH_TOP_UP", 0.1 ether);
        changeConfiguration("PROVIDER_MINIMUM_ETH_STAKING", 2 ether);
        changeConfiguration("REQUESTER_MINIMUM_POOL_STAKING", 500 finney);
        changeConfiguration("EXIT_BLOCKS", 24);

        changeConfiguration(_proposeCountLimit_, 2);

        // 2 days
        changeConfiguration(_proposeTimelock_, 60 * 60 * 24 * 2);

        changeConfiguration(_spanLo_, 24 * 60 * 60 * 3);
        // 3 days
        changeConfiguration(_spanHi_, 24 * 60 * 60 * 7);
        // 7 days
    }

    function propose(uint256 _timeSpan, string memory _topic, string memory _content) public {
        deposit();
        require(_timeSpan >= getConfig(_spanLo_), "Gov#propose: Timespan lower than limit");
        require(_timeSpan <= getConfig(_spanHi_), "Gov#propose: Timespan greater than limit");

        uint256 proposalMinimum = getConfig(_proposalMinimumThreshold_);
        address sender = msg.sender;
        uint256 senderInt = uint(sender);

        require(getConfig(_proposerHasActiveProposal_, sender) == 0, "Gov#propose: You have an active proposal");

        setConfig(_proposerHasActiveProposal_, sender, 1);

        require(depositsOf(sender) >= proposalMinimum, "Gov#propose: Not enough balance");

        // proposer can create 2 proposal in a month
        uint256 lastProposeAt = getConfig(_proposerLastProposeAt_, senderInt);
        if (now.sub(lastProposeAt) < MONTH) {
            // get new count in this month
            uint256 proposeCountInMonth = getConfig(_proposerProposeCountInMonth_, senderInt).add(1);
            require(proposeCountInMonth <= getConfig(_proposeCountLimit_), "Gov#propose: Cannot create more proposals this month");
            setConfig(_proposerProposeCountInMonth_, senderInt, proposeCountInMonth);
        }
        else {
            setConfig(_proposerProposeCountInMonth_, senderInt, 1);
        }
        // set last propose at for proposer
        setConfig(_proposerLastProposeAt_, senderInt, now);

        uint256 totalProposes = getConfig(_totalProposes_);
        bytes32 _proposeID = bytes32(senderInt ^ totalProposes ^ block.number);
        uint256 idInteger = uint(_proposeID);

        setConfig(_totalProposes_, totalProposes.add(1));

        // set started block
        setConfig(_startBlock_, idInteger, block.number);
        // set sender
        setConfigAddress(_proposer_, idInteger, sender);
        // set
        setConfigString(_proposeTopic_, idInteger, _topic);
        setConfigString(_proposeContent_, idInteger, _content);

        // proposal will start after #timelock# days
        uint256 endsAt = _timeSpan.add(getConfig(_proposeTimelock_)).add(now);

        setConfig(_proposeEndAt_, idInteger, endsAt);
        setConfig(_proposeStatus_, idInteger, PROPOSE_STATUS_WAITING);

        setConfig(_proposeStartAt_, idInteger, now);

        // add new lock to user
        _addNewLockToUser(sender, proposalMinimum, endsAt, senderInt ^ idInteger);

        // set proposal status (pending)
        emit Propose(sender, _proposeID, _topic, _content, _timeSpan);
        __vote(_proposeID, VOTE_YES, false);
    }

    function vote(bytes32 _ID, bytes32 _vote) public {
        deposit();
        uint256 ID = uint256(_ID);
        uint256 status = getConfig(_proposeStatus_, ID);
        uint256 startAt = getConfig(_proposeStartAt_, ID);
        // if propose status is waiting and enough time passed, change status
        if (status == PROPOSE_STATUS_WAITING && now.sub(startAt) >= getConfig(_proposeTimelock_)) {
            setConfig(_proposeStatus_, ID, PROPOSE_STATUS_VOTING);
            status = PROPOSE_STATUS_VOTING;
        }
        require(status == PROPOSE_STATUS_VOTING, "Gov#__vote: Propose status is not VOTING");
        require(getConfigAddress(_proposer_, ID) != msg.sender, "Gov#__vote: Proposers cannot vote their own proposals") ;

        __vote(_ID, _vote, true);
    }

    string public go;

    function __vote(bytes32 _ID, bytes32 _vote, bool _lockTokens) internal {

        uint256 ID = uint256(_ID);
        address _holder = msg.sender;

        uint256 _holderID = uint(_holder) ^ uint(ID);
        uint256 endsAt = getConfig(_proposeEndAt_, ID);

        if (now < endsAt) {
            // previous vote type
            bytes32 voted = bytes32(getConfig(_votes_, _holderID));
            require(voted == 0x0 || _vote == VOTE_CANCEL, "Gov#__vote: You already voted to this proposal");
            // previous vote count
            uint256 voteCount = getConfig(_voteCount_, _holderID);

            uint256 ID_voted = uint256(_ID ^ voted);
            // if this is a cancelling operation, set vote count to 0 for user and remove votes
            if ((voted == VOTE_YES || voted == VOTE_NO) && _vote == VOTE_CANCEL) {
                setConfig(_votes_, ID_voted, getConfig(_votes_, ID_voted).sub(voteCount));
                setConfig(_voteCount_, _holderID, 0);

                setConfig(_votes_, _holderID, uint256(_vote));
                emit Vote(_holder, _ID, _vote, 0);
                return;
            }
            else if (_vote == VOTE_YES || _vote == VOTE_NO) {
                uint256 ID_vote = uint256(_ID ^ _vote);
                // get total stakes from deposit contract
                uint256 staked = depositsOf(_holder);

                // add new lock to user
                if (_lockTokens) {
                    _addNewLockToUser(_holder, staked, endsAt, _holderID);
                }

                setConfig(_votes_, ID_vote, getConfig(_votes_, ID_vote).add(staked.div(DIVISOR)));
                setConfig(_votes_, _holderID, uint256(_vote));
                emit Vote(_holder, _ID, _vote, staked);
            }
        }
    }

    //0xc7bc95c2
    function getVotes(bytes32 _ID, bytes32 _vote) public view returns (uint256) {
        return getConfig(_votes_, uint256(_ID ^ _vote));
    }

    function finishProposal(bytes32 _ID) public {
        uint256 ID = uint256(_ID);
        require(getConfig(_proposeEndAt_, ID) <= now, "Gov#finishProposal: There is still time for proposal");
        uint256 status = getConfig(_proposeStatus_, ID);
        require(status == PROPOSE_STATUS_VOTING || status == PROPOSE_STATUS_WAITING, "Gov#finishProposal: You cannot finish proposals that already finished");

        _finishProposal(_ID);
    }

    function _finishProposal(bytes32 _ID) internal returns (bool result) {
        uint256 ID = uint256(_ID);
        uint256 yes = 0;
        uint256 no = 0;

        (result, yes, no,,,,,) = proposal(_ID);

        setConfig(_proposeStatus_, ID, result ? PROPOSE_STATUS_PASS : PROPOSE_STATUS_FAIL);

        setConfig(_proposerHasActiveProposal_, getConfigAddress(_proposer_, ID), 0);

        emit ProposalFinished(_ID, result, yes, no);
    }

    function proposal(bytes32 _ID) public view returns (
        bool result,
        uint256 yes,
        uint256 no,
        string memory topic,
        string memory content,
        uint256 status,
        uint256 startTime,
        uint256 endTime
    ) {
        uint256 idInteger = uint(_ID);
        yes = getConfig(_votes_, uint256(_ID ^ VOTE_YES));
        no = getConfig(_votes_, uint256(_ID ^ VOTE_NO));

        result = yes > no && yes.add(no) > getConfig(_minimumVoteAcceptance_);

        topic = getConfigString(_proposeTopic_, idInteger);
        content = getConfigString(_proposeContent_, idInteger);

        endTime = getConfig(_proposeEndAt_, idInteger);
        startTime = getConfig(_proposeStartAt_, idInteger);

        status = getConfig(_proposeStatus_, idInteger);
        if (status == PROPOSE_STATUS_WAITING && now.sub(getConfig(_proposeStartAt_, idInteger)) >= getConfig(_proposeTimelock_)) {
            status = PROPOSE_STATUS_VOTING;
        }
    }

    function changeConfiguration(bytes32 key, uint256 value) public onlyOperator {
        uint256 oldValue = config[key];
        if (oldValue != value) {
            config[key] = value;
            emit ConfigurationChanged(key, oldValue, value);
        }
    }

    function cancelProposal(bytes32 _ID, string memory _reason) public onlyOwner {
        uint256 ID = uint(_ID);
        require(getConfig(_proposeStatus_, ID) == PROPOSE_STATUS_WAITING, "Gov#cancelProposal: Only waiting proposals can be canceled");
        address sender = msg.sender;
        // set status cancel
        setConfig(_proposeStatus_, ID, PROPOSE_STATUS_CANCELED);
        // remove from propose count for month
        setConfig(_proposerProposeCountInMonth_, ID, getConfig(_proposerProposeCountInMonth_, ID).sub(1));
        // remove locked amount
        setConfig(_lockTotal_, sender, getConfig(_lockTotal_, sender).sub(getConfig(_lockAmount_, uint(sender) ^ ID)));
        // set locked amount to zero for this proposal
        setConfig(_lockAmount_, uint(sender) ^ ID, 0);
    }
}
