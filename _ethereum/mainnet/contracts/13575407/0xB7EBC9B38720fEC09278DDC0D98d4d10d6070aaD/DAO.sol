// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./IPLBTStaking.sol";
import "./IDAO.sol";
import "./IUniswapV2Router02.sol";
import "./ERC20FriendlyRewardModule.sol";
import "./PoolFactory.sol";
import "./IPool.sol";

///@title DAO contract
contract DAO is IDAO, AccessControl {
    using SafeERC20 for IERC20;

    /// status of vote
    enum Decision {
        none,
        votedFor,
        votedAgainst
    }

    /// type of proposal types
    enum ChangesType {
        none,
        strategy,
        allocation,
        quorum,
        majority,
        treasury,
        cancel
    }

    /// state of proposal
    enum Status {
        none,
        proposal,
        finished,
        voting
    }

    /// struct represents a vote
    struct Vote {
        // amount of tokens in vote
        uint256 amount;
        // voting decision
        Decision decision;
    }

    /// struct for storing proposal
    struct Voting {
        // voting id
        uint256 id;
        // in support of votes
        uint256 votesFor;
        // against votes
        uint256 votesAgainst;
        // when started
        uint256 startTime;
        // voting may execute only after voting ended
        uint256 endTime;
        // this time increases if this voting is being cancelled
        uint256 finishTime;
        // time when changes come in power
        uint256 implementationTime;
        // creator address
        address creator;
        // address of proposal creator
        ChangesType changesType;
        // proposal status
        Status status;
        // indicator showing if proposal was cancelled
        bool wasCancelled;
        // bytecode to run on the finishvote
        bytes data;
    }

    /// represents allocation percentage
    struct Allocation {
        uint8 plbtStakers;
        uint8 osomStakers;
        uint8 lpStakers;
        uint8 buyback;
    }

    /// represents amount of tokens in percentage put on investing strategies
    struct Strategy {
        uint8 autopilot;
        uint8 uniswap;
        uint8 aave;
        uint8 anchor;
    }

    ///@dev emmited when new proposal created
    ///@param creator address of proposal creator
    ///@param key hash passed to event in order to match with backend, for storing proposal descriptions
    ///@param id id of proposal
    ///@param startTime time when voting on proposal starts
    ///@param endTime time when voting on proposal ends
    event ProposalAdded(
        address indexed creator,
        bytes32 key,
        uint256 indexed id,
        uint256 startTime,
        uint256 endTime
    );
    ///@dev emmited when proposal transitioned to main voting status
    ///@param id id of proposal
    ///@param startTime time when main voting starts
    ///@param endTime time when main voting ends
    event VotingBegan(uint256 indexed id, uint256 startTime, uint256 endTime);

    ///@dev emmited when voting is finished
    ///@param id id of finished proposal
    ///@param executed shows if finish was successfully executed
    ///@param votesFor with how many tokens voted for proposal
    ///@param votesAgainst with how many tokens voted against proposal
    event Finished(
        uint256 indexed id,
        bool indexed executed,
        uint256 votesFor,
        uint256 votesAgainst
    );

    ///@dev emmited when someone voted on proposal
    ///@param voter address of voter
    ///@param id id of proposal
    ///@param decision shows if voted for or against
    ///@param amount amount of tokens voted with
    event CastedOnProposal(
        address indexed voter,
        uint256 indexed id,
        bool decision,
        uint256 amount
    );

    ///@dev emmited when someone voted in main voting
    ///@param voter address of voter
    ///@param id id of proposal
    ///@param decision shows if voted for or against
    ///@param amount amount of tokens voted with
    event CastedOnVoting(
        address indexed voter,
        uint256 indexed id,
        bool decision,
        uint256 amount
    );

    ///@dev modifier used for restricted function execution
    modifier onlyDAO() {
        require(
            msg.sender == address(this),
            "DAO: only dao can call this function."
        );
        _;
    }

    /// role of treasury holder
    bytes32 public TREASURY_ROLE = keccak256("TREASURY_ROLE");
    /// threshold for proposal to pass
    uint256 public proposalMajority;
    ///threshold for voting to pass
    uint256 public votingMajority;
    /// threshold for proposal to become valid
    uint256 public proposalQuorum;
    /// threshold for voting to become valid
    uint256 public votingQuorum;
    /// debating period duration
    uint256 public votingPeriod;
    /// voting count
    uint256 public votingsCount;
    /// regular timelock
    uint256 public regularTimelock;
    /// cancel timelock
    uint256 public cancelTimelock;
    /// Allocation
    Allocation public allocation;
    /// Strategy
    Strategy public strategy;
    /// Treasury owner
    address treasury;
    /// for percent calculations
    uint256 private precision = 1e6;
    /// staking contracts
    IPLBTStaking private staking;
    /// tokens
    IERC20 private plbt;
    IERC20 private weth;
    IERC20 private wbtc;
    /// Router
    IUniswapV2Router02 router;
    ///pool address
    address public pool;
    ///GYSR Pool
    address public gysr;

    ///OSOM address
    address OSOM;
    ///array of function selectors
    bytes4[6] selectors = [
        this.changeStrategy.selector,
        this.changeAllocation.selector,
        this.changeQuorum.selector,
        this.changeMajority.selector,
        this.changeTreasury.selector,
        this.cancelVoting.selector
    ];
    /// active proposals
    uint256[10] public proposals;
    /// initialized
    bool private initialized;

    mapping(uint256 => Voting) public votings;
    /// storing votes from a certain address for voting
    mapping(uint256 => mapping(address => Vote)) public votingDecisions;
    /// current voting
    uint256 public activeVoting;
    /// current cancel
    uint256 public activeCancellation;

    ///@param _proposalMajority initial percent of proposal majority of votes to become valid
    ///@param _votingMajority initial percent of main voting majority of votes to become valid
    ///@param _proposalQuorum initial percent of proposal quorum
    ///@param _votingQuorum initial percent of main voting quorum
    ///@param _votingPeriod initial voting period time
    ///@param _regularTimelock initial timelock period
    ///@param _cancelTimelock initial cancel timelock period
    ///@param _allocation initial allocation config
    ///@param _strategy initial strategy config
    constructor(
        uint256 _proposalMajority,
        uint256 _votingMajority,
        uint256 _proposalQuorum,
        uint256 _votingQuorum,
        uint256 _votingPeriod,
        uint256 _regularTimelock,
        uint256 _cancelTimelock,
        Allocation memory _allocation,
        Strategy memory _strategy
    ) {
        proposalMajority = _proposalMajority;
        votingMajority = _votingMajority;
        proposalQuorum = _proposalQuorum;
        votingQuorum = _votingQuorum;
        votingPeriod = _votingPeriod;
        regularTimelock = _regularTimelock;
        cancelTimelock = _cancelTimelock;
        allocation = _allocation;
        strategy = _strategy;
        _setupRole(DEFAULT_ADMIN_ROLE, address(this));
        _setRoleAdmin(TREASURY_ROLE, DEFAULT_ADMIN_ROLE);
    }

    ///@dev initializing DAO with settings
    ///@param _router SushiSwap router address
    ///@param _treasury address of the treasury holder
    ///@param _stakingAddr address of staking
    ///@param _plbt Polybius token address
    ///@param _weth address of wEth
    ///@param _wbtc address of wBTC
    ///@param _poolFactory address of GYSR pool factory
    ///@param _stakingFactory address of GYSR staking module Factory
    ///@param _rewardFactory address of GYSR reward module factory
    ///@param _slpAddress address of PLBT-wETH LP token address
    ///@param _OSOM address of OSOM
    function initialize(
        address _router,
        address _treasury,
        address _stakingAddr,
        address _plbt,
        address _weth,
        address _wbtc,
        address _poolFactory,
        address _stakingFactory,
        address _rewardFactory,
        address _slpAddress,
        address _OSOM
    ) external {
        require(!initialized, "DAO: Already initialized.");
        treasury = _treasury;
        _setupRole(TREASURY_ROLE, treasury);
        staking = IPLBTStaking(_stakingAddr);
        plbt = IERC20(_plbt);
        weth = IERC20(_weth);
        wbtc = IERC20(_wbtc);
        PoolFactory factory = PoolFactory(_poolFactory);
        bytes memory stakingdata = (abi.encode(_slpAddress));
        bytes memory rewarddata = (abi.encode(_plbt, 10**18, 2592000));
        pool = factory.create(
            _stakingFactory,
            _rewardFactory,
            stakingdata,
            rewarddata
        );
        gysr = IPool(pool).rewardModule();
        OSOM = _OSOM;
        router = IUniswapV2Router02(_router);
        _setupRole(TREASURY_ROLE, treasury);
        initialized = true;
    }

    ///@dev distributing fund to parties and staking contracts, and buying back PLBT from Sushiswap pool
    ///@param toStakersWETH amount of wETH to distribute to PLBTStakers
    ///@param toStakersWBTC amount of wBTC to distribute to PLBTStakers
    ///@param toLPStakers amount of PLBT to distribute to LPStakers on GYSR
    ///@param toOSOMWETH amount of wETH to distribute to PLBTStakers on OSOM
    ///@param toOSOMWBTC amount of wBTC to distribute to PLBTStakers on OSOM
    ///@param toBuyback amount of wETH to swap for PLBT
    function distribute(
        uint256 toStakersWETH,
        uint256 toStakersWBTC,
        uint256 toLPStakers,
        uint256 toOSOMWETH,
        uint256 toOSOMWBTC,
        uint256 toBuyback
    ) external onlyRole(TREASURY_ROLE) {
        if (toStakersWETH != 0 && toStakersWBTC != 0) {
            weth.safeTransferFrom(treasury, address(staking), toStakersWETH);
            wbtc.safeTransferFrom(treasury, address(staking), toStakersWBTC);
            staking.setReward(toStakersWETH, toStakersWBTC);
        }
        if (toLPStakers != 0) {
            plbt.safeTransferFrom(treasury, address(this), toLPStakers);
            plbt.approve(gysr, toLPStakers);
            ERC20FriendlyRewardModule(gysr).fund(toLPStakers, 2592000);
        }

        if (toOSOMWETH != 0 && toOSOMWBTC != 0) {
            weth.safeTransferFrom(treasury, OSOM, toOSOMWETH);
            wbtc.safeTransferFrom(treasury, OSOM, toOSOMWBTC);
        }
        if (toBuyback != 0) {
            uint256 total = plbt.balanceOf(address(this));
            weth.safeTransferFrom(treasury, address(this), toBuyback);
            address[] memory path = new address[](2);
            path[0] = address(weth);
            path[1] = address(plbt);
            uint256[] memory amounts = router.getAmountsOut(toBuyback, path);
            weth.approve(address(router), amounts[0]);
            router.swapTokensForExactTokens(
                amounts[1],
                amounts[0],
                path,
                address(this),
                block.timestamp + 600
            );
            uint256 current = plbt.balanceOf(address(this));
            uint256 burn = current - total;
            plbt.safeTransfer(address(0), burn);
        }
    }

    function changeOSOM(address _address) external onlyRole(TREASURY_ROLE) {
        require(_address != address(0), "DAO: can't set zero-address");
        OSOM = _address;
    }

    ///@dev function which matches function selector with bytecode
    ///@param _changesType shows which function selector is expected
    ///@param _data bytecode to match
    modifier matchChangesTypes(ChangesType _changesType, bytes memory _data) {
        require(
            _changesType != ChangesType.none,
            "DAO: addProposal bad arguments."
        );
        bytes4 outBytes4;
        assembly {
            outBytes4 := mload(add(_data, 0x20))
        }

        require(
            outBytes4 == selectors[uint256(_changesType) - 1],
            "DAO: bytecode is wrong"
        );
        _;
    }

    ///@dev function which will be called on Finish; changes proposal or main voting quorums
    ///@param or shows what quorum to change
    ///@param _quorum new quorum percent value
    function changeQuorum(bool or, uint256 _quorum) public onlyDAO {
        or ? votingQuorum = _quorum : proposalQuorum = _quorum;
    }

    ///@dev function which will be called on Finish; changes proposal or main voting Majority
    ///@param or shows what Majority to change
    ///@param _majority new Majority percent value
    function changeMajority(bool or, uint256 _majority) public onlyDAO {
        or ? votingMajority = _majority : proposalMajority = _majority;
    }

    ///@dev function which will be called on Finish of cancellation voting
    ///@param id id of main voting
    function cancelVoting(uint256 id) public onlyDAO {
        votings[id].status = Status.finished;
    }

    ///@dev function which will be called on Finish; changes allocation parameters
    ///@param _allocation new allocation config
    function changeAllocation(Allocation memory _allocation) public onlyDAO {
        allocation = _allocation;
    }

    ///@dev function which will be called on Finish; changes strategy parameters
    ///@param _strategy new strategy config
    function changeStrategy(Strategy memory _strategy) public onlyDAO {
        strategy = _strategy;
    }

    ///@dev function which will be called on Finish; changes treasury holder address
    ///@param _treasury new treasury holder address
    function changeTreasury(address _treasury) public onlyDAO {
        revokeRole(TREASURY_ROLE, treasury);
        treasury = _treasury;
        grantRole(TREASURY_ROLE, treasury);
        staking.changeTreasury(_treasury);
    }

    ///@dev check if proposal passed quorum and majority thresholds
    ///@param proposal proposal sent to validate
    function validate(Voting memory proposal) private view returns (bool) {
        uint256 total = proposal.votesFor + proposal.votesAgainst;
        if (total == 0) {
            return false;
        }
        bool quorum;
        uint256 supply = plbt.totalSupply() - plbt.balanceOf(address(0));
        bool majority;
        if (proposal.status == Status.voting) {
            quorum = ((total * precision) / supply) > votingQuorum;
            majority = (proposal.votesFor * precision) / total > votingMajority;
        } else {
            quorum = ((total * precision) / supply) > proposalQuorum;
            majority =
                (proposal.votesFor * precision) / total > proposalMajority;
        }
        return majority && quorum;
    }

    ///@dev picks next proposal out of proposal pool
    function pickProposal() private view returns (uint256 id, bool check) {
        if (votings[activeVoting].status == Status.voting) {
            return (0, false);
        }
        uint256 temp = 0;
        Voting memory proposal;
        for (uint256 i = 0; i < proposals.length; i++) {
            proposal = votings[proposals[i]];
            if (proposal.status == Status.proposal && validate(proposal)) {
                (temp == 0 || proposal.startTime < votings[temp].startTime)
                    ? temp = proposal.id
                    : 0;
            }
        }
        if (temp != 0 && validate(votings[temp])) {
            return (temp, true);
        }
        return (0, false);
    }

    ///@dev send proposal to main voting round
    ///@param id id of proposal
    function sendProposalToVoting(uint256 id) private {
        Voting storage proposal = votings[id];
        proposal.status = Status.voting;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingPeriod;
        proposal.finishTime = proposal.endTime + regularTimelock;
        activeVoting = id;
        emit VotingBegan(proposal.id, proposal.startTime, proposal.endTime);
    }

    ///@dev adds proposal to proposal pool
    ///@param _changesType type of proposal
    ///@param _data executable bytecode to execute on Finish
    ///@param id key for matching frontend request with this contract logs
    function addProposal(
        ChangesType _changesType,
        bytes memory _data,
        bytes32 id
    ) public matchChangesTypes(_changesType, _data) {
        bool cancel = _changesType == ChangesType.cancel;
        require(
            !(cancel && votings[activeCancellation].status == Status.voting),
            "Cancel Voting already exists"
        );
        if (cancel) {
            Voting storage voting = votings[activeVoting];
            require(
                voting.wasCancelled == false && voting.status == Status.voting,
                "DAO: Can't cancel twice."
            );
            require(
                voting.endTime < block.timestamp &&
                    voting.finishTime > block.timestamp,
                "DAO: can only cancel during timelock"
            );
            voting.finishTime = block.timestamp + cancelTimelock;
            voting.wasCancelled = true;
        }
        votingsCount++;
        Voting memory proposal = Voting({
            id: votingsCount,
            votesFor: 0,
            votesAgainst: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            finishTime: 0,
            implementationTime: 0,
            creator: msg.sender,
            changesType: _changesType,
            status: Status.proposal,
            wasCancelled: false,
            data: _data
        });
        votings[votingsCount] = proposal;
        if (cancel) {
            activeCancellation = votingsCount;
            votings[activeCancellation].status = Status.voting;
            votings[activeCancellation].finishTime = votings[activeCancellation]
                .endTime;

            emit ProposalAdded(
                msg.sender,
                id,
                votingsCount,
                proposal.startTime,
                proposal.endTime
            );
            return;
        }
        bool proposalAdded = false;
        bool check;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (
                votings[proposals[i]].status != Status.proposal ||
                proposals[i] == 0
            ) {
                check = true;
            } else {
                if (
                    votings[proposals[i]].endTime <= block.timestamp &&
                    votings[proposals[i]].status == Status.proposal
                ) {
                    check = !(validate(votings[proposals[i]]));
                }
            }
            if (check) {
                proposals[i] = proposal.id;
                proposalAdded = true;
                break;
            }
        }
        require(proposalAdded, "DAO: proposals list is full");

        emit ProposalAdded(
            msg.sender,
            id,
            votingsCount,
            proposal.startTime,
            proposal.endTime
        );
    }

    ///@dev participate in main voting round
    ///@param id id of proposal
    ///@param amount amount of tokens to vote with
    ///@param decision shows if voted for or against
    function participateInVoting(
        uint256 id,
        uint256 amount,
        bool decision
    ) external {
        // check if proposal is active
        bool check = votings[id].status == Status.voting &&
            votings[id].endTime >= block.timestamp;
        require(check, "DAO: voting ended");
        // check if voted
        Vote storage vote = votingDecisions[id][msg.sender];
        require(
            vote.decision == Decision.none && vote.amount == 0,
            "DAO: you have already voted"
        );
        // check if msg.sender has available tokens
        uint256 possible = getAvailableTokens(msg.sender);
        require(amount > 0 && amount <= possible, "DAO: incorrect amount");
        Voting storage voting = votings[id];
        vote.amount += amount;
        if (decision) {
            voting.votesFor += amount;
            vote.decision = Decision.votedFor;
        } else {
            voting.votesAgainst += amount;
            vote.decision = Decision.votedAgainst;
        }
        emit CastedOnVoting(msg.sender, id, decision, amount);
    }

    ///@dev participate in proposal
    ///@param id id of proposal
    ///@param amount amount of tokens to vote with
    ///@param decision shows if voted for or against
    function participateInProposal(
        uint256 id,
        uint256 amount,
        bool decision
    ) external {
        // check if proposal is active
        bool check = votings[id].status == Status.proposal &&
            votings[id].endTime >= block.timestamp;
        require(check, "DAO: proposal ended");
        // check if voted
        Voting storage proposal = votings[id];
        Vote storage vote = votingDecisions[proposal.id][msg.sender];
        require(
            vote.decision == Decision.none && vote.amount == 0,
            "DAO: you have already voted"
        );
        // check if msg.sender has available tokens
        uint256 possible = getAvailableTokens(msg.sender);
        require(amount > 0 && amount <= possible, "DAO: incorrect amount");
        vote.amount += amount;
        if (decision) {
            proposal.votesFor += amount;
            vote.decision = Decision.votedFor;
        } else {
            proposal.votesAgainst += amount;
            vote.decision = Decision.votedAgainst;
        }
        votings[proposal.id] = proposal;
        (uint256 picked, bool found) = pickProposal();
        if (found) {
            sendProposalToVoting(picked);
        }
        emit CastedOnProposal(msg.sender, id, decision, amount);
    }

    ///@dev to finish main voting round and run changes on success
    ///@param id id of proposal to finish
    function finishVoting(uint256 id) public {
        Voting storage voting = votings[id];
        require(
            (voting.status == Status.voting),
            "DAO: the result of the vote has already been completed,"
        );
        require(
            block.timestamp > (voting.finishTime),
            "DAO: Voting can't be finished yet."
        );
        bool result = validate(voting);
        if (result && voting.changesType != ChangesType.cancel) {
            (bool success, ) = address(this).call{value: 0}(voting.data);
            voting.implementationTime = block.timestamp;
        }
        if (voting.changesType == ChangesType.cancel) {
            if (result) {
                address(this).call{value: 0}(voting.data);
            } else {
                bytes memory data = voting.data;
                uint256 id_;
                assembly {
                    let sig := mload(add(data, add(4, 0)))
                    id_ := mload(add(data, 36))
                }
                votings[id_].finishTime = votings[id_].endTime;
                finishVoting(id_);
            }
        }
        voting.status = Status.finished;
        (uint256 picked, bool found) = pickProposal();
        if (found) {
            sendProposalToVoting(picked);
        }
        emit Finished(id, result, voting.votesFor, voting.votesAgainst);
    }

    ///@dev used for situations, when previously passed proposal wasn't finished and proposal pool is full
    ///@param finishId id of proposal to finish
    ///@param _changesType type of proposal
    ///@param _data executable bytecode to execute on Finish
    ///@param id key for matching frontend request with this contract logs
    function finishAndAddProposal(
        uint256 finishId,
        ChangesType _changesType,
        bytes calldata _data,
        bytes32 id
    ) external {
        finishVoting(finishId);
        addProposal(_changesType, _data, id);
    }

    ///@dev get all locked tokens for address `staker`, so user cannot unstake or vote with tokens used in proposals
    ///@param staker address of staker
    function getLockedTokens(address staker)
        public
        view
        override
        returns (uint256 locked)
    {
        for (uint256 i = 0; i < proposals.length; i++) {
            if (
                (votings[proposals[i]].endTime > block.timestamp ||
                    validate(votings[proposals[i]])) &&
                votings[proposals[i]].status == Status.proposal
            ) locked += votingDecisions[proposals[i]][staker].amount;
        }
        if (
            votings[activeVoting].status == Status.voting &&
            votings[activeVoting].finishTime > block.timestamp
        ) {
            locked += votingDecisions[activeVoting][staker].amount;
        }
        if (
            votings[activeCancellation].status == Status.voting &&
            votings[activeCancellation].finishTime > block.timestamp
        ) {
            locked += votingDecisions[activeCancellation][staker].amount;
        }
        return locked;
    }

    ///@dev get available tokens for address `staker`, so user cannot unstake or vote with tokens used in proposals
    ///@param staker address of staker
    function getAvailableTokens(address staker)
        public
        view
        override
        returns (uint256 available)
    {
        uint256 locked = getLockedTokens(staker);
        uint256 staked = staking.getStakedTokens(staker);
        available = staked - locked;
        return available;
    }

    ///@dev returns all proposals from pool
    function getAllProposals() external view returns (Voting[] memory) {
        Voting[] memory proposalsList = new Voting[](10); // allocate array memory
        for (uint256 i = 0; i < proposals.length; i++) {
            {
                proposalsList[i] = votings[proposals[i]];
            }
        }
        return proposalsList;
    }

    ///@dev returns all votings
    ///@return array of proposals from pool
    function getAllVotings() external view returns (Voting[] memory) {
        Voting[] memory votingsList = new Voting[](votingsCount); // allocate array memory
        for (uint256 i = 0; i < votingsCount; i++) {
            {
                votingsList[i] = votings[i + 1];
            }
        }
        return votingsList;
    }

    ///@dev returns proposal info with additional information for frontend
    ///@return proposal struct
    ///@return creatorAmountStaked amount of staked tokens by proposal creator
    ///@return quorum
    ///@return majority
    function getActiveVoting()
        external
        view
        returns (
            Voting memory,
            uint256 creatorAmountStaked,
            uint256,
            uint256
        )
    {
        creatorAmountStaked = staking.getStakedTokens(
            votings[activeVoting].creator
        );
        return (
            votings[activeVoting],
            creatorAmountStaked,
            votingQuorum,
            votingMajority
        );
    }

    ///@dev returns proposal info with additional information for frontend
    ///@return proposal struct
    ///@return creatorAmountStaked amount of staked tokens by proposal creator
    ///@return quorum
    ///@return majority
    function getActiveCancellation()
        external
        view
        returns (
            Voting memory,
            uint256 creatorAmountStaked,
            uint256,
            uint256
        )
    {
        creatorAmountStaked = staking.getStakedTokens(
            votings[activeCancellation].creator
        );
        return (
            votings[activeCancellation],
            creatorAmountStaked,
            votingQuorum,
            votingMajority
        );
    }

    ///@dev returns proposal info with additional information for frontend
    ///@param user address of the user
    ///@return proposal struct
    ///@return vote struct
    ///@return available amount of available for voting tokens by `user`
    ///@return creatorAmountStaked amount of staked tokens by proposal creator
    ///@return quorum
    ///@return majority
    function getActiveVoting(address user)
        external
        view
        returns (
            Voting memory,
            Vote memory,
            uint256 available,
            uint256 creatorAmountStaked,
            uint256,
            uint256
        )
    {
        available = getAvailableTokens(user);
        creatorAmountStaked = staking.getStakedTokens(
            votings[activeVoting].creator
        );
        return (
            votings[activeVoting],
            votingDecisions[activeVoting][user],
            creatorAmountStaked,
            available,
            votingQuorum,
            votingMajority
        );
    }

    ///@dev returns proposal info with additional information for frontend
    ///@param user address of the user
    ///@return proposal struct
    ///@return vote struct
    ///@return available amount of available for voting tokens by `user`
    ///@return creatorAmountStaked amount of staked tokens by proposal creator
    ///@return quorum
    ///@return majority
    function getActiveCancellation(address user)
        external
        view
        returns (
            Voting memory,
            Vote memory,
            uint256 available,
            uint256 creatorAmountStaked,
            uint256,
            uint256
        )
    {
        available = getAvailableTokens(user);
        creatorAmountStaked = staking.getStakedTokens(
            votings[activeCancellation].creator
        );
        return (
            votings[activeCancellation],
            votingDecisions[activeCancellation][user],
            creatorAmountStaked,
            available,
            votingQuorum,
            votingMajority
        );
    }

    ///@dev returns proposal info with additional information for frontend
    ///@param id id of proposal
    ///@return proposal struct
    ///@return creatorAmountStaked amount of staked tokens by proposal creator
    ///@return quorum
    ///@return majority
    function getProposalInfo(uint256 id)
        external
        view
        returns (
            Voting memory,
            uint256 creatorAmountStaked,
            uint256,
            uint256
        )
    {
        creatorAmountStaked = staking.getStakedTokens(votings[id].creator);
        return (
            votings[id],
            creatorAmountStaked,
            votings[id].status == Status.proposal
                ? proposalQuorum
                : votingQuorum,
            votings[id].status == Status.proposal
                ? proposalMajority
                : votingMajority
        );
    }

    ///@dev returns proposal info with additional information for frontend
    ///@param id id of proposal
    ///@param user address of the user
    ///@return proposal struct
    ///@return vote struct
    ///@return available amount of available for voting tokens by `user`
    ///@return creatorAmountStaked amount of staked tokens by proposal creator
    ///@return quorum
    ///@return majority
    function getProposalInfo(uint256 id, address user)
        external
        view
        returns (
            Voting memory,
            Vote memory,
            uint256 available,
            uint256 creatorAmountStaked,
            uint256,
            uint256
        )
    {
        available = getAvailableTokens(user);
        creatorAmountStaked = staking.getStakedTokens(votings[id].creator);
        return (
            votings[id],
            votingDecisions[id][user],
            creatorAmountStaked,
            available,
            votings[id].status == Status.proposal
                ? proposalQuorum
                : votingQuorum,
            votings[id].status == Status.proposal
                ? proposalMajority
                : votingMajority
        );
    }

    ///@dev returns DAO configuration parameters
    ///@return allocation config
    ///@return strategy config
    ///@return proposal majority
    ///@return main voting round majority
    ///@return proposal quorum
    ///@return main voting round quorum
    function InfoDAO()
        external
        view
        returns (
            Allocation memory,
            Strategy memory,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            allocation,
            strategy,
            proposalMajority,
            votingMajority,
            proposalQuorum,
            votingQuorum
        );
    }
}
