// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./MathUpgradeable.sol";

import "./IWalletHunters.sol";
import "./AccountingTokenUpgradeable.sol";
import "./RelayRecipientUpgradeable.sol";

contract WalletHunters is
    IWalletHunters,
    AccountingTokenUpgradeable,
    RelayRecipientUpgradeable,
    AccessControlUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct Request {
        address hunter;
        uint256 reward;
        uint256 creationTime;
        uint256 configurationIndex;
        bool discarded;
    }

    struct RequestVoting {
        uint256 votesFor;
        uint256 votesAgainst;
        EnumerableSetUpgradeable.AddressSet voters;
        mapping(address => SheriffVote) votes;
    }

    struct SheriffVote {
        uint256 amount;
        bool voteFor;
    }

    struct Configuration {
        uint256 votingDuration;
        uint256 sheriffsRewardShare;
        uint256 fixedSheriffReward;
        uint256 minimalVotesForRequest;
        uint256 minimalDepositForSheriff;
        uint256 requestReward;
    }

    uint256 public constant MAX_PERCENT = 10000; // 100%
    uint256 public constant SUPER_MAJORITY = 6700; // 67%

    bytes32 public constant MAYOR_ROLE = keccak256("MAYOR_ROLE");
    string private constant ERC20_NAME = "Wallet Hunters, Sheriff Token";
    string private constant ERC20_SYMBOL = "WHST";

    IERC20Upgradeable public stakingToken;

    uint256 public rewardsPool;
    CountersUpgradeable.Counter private _requestCounter;
    mapping(uint256 => Request) private _requests;
    mapping(uint256 => RequestVoting) private _requestVotings;
    mapping(address => EnumerableSetUpgradeable.UintSet)
        private _activeRequests;
    Configuration[] private _configurations;

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), "Must have appropriate role");
        _;
    }

    function initialize(
        address admin_,
        address trustedForwarder_,
        address stakingToken_,
        uint256 votingDuration_,
        uint256 sheriffsRewardShare_,
        uint256 fixedSheriffReward_,
        uint256 minimalVotesForRequest_,
        uint256 minimalDepositForSheriff_,
        uint256 requestReward_
    ) external initializer {
        __WalletHunters_init(
            admin_,
            trustedForwarder_,
            stakingToken_,
            votingDuration_,
            sheriffsRewardShare_,
            fixedSheriffReward_,
            minimalVotesForRequest_,
            minimalDepositForSheriff_,
            requestReward_
        );
    }

    function __WalletHunters_init(
        address admin_,
        address trustedForwarder_,
        address stakingToken_,
        uint256 votingDuration_,
        uint256 sheriffsRewardShare_,
        uint256 fixedSheriffReward_,
        uint256 minimalVotesForRequest_,
        uint256 minimalDepositForSheriff_,
        uint256 requestReward_
    ) internal initializer {
        __AccountingToken_init(ERC20_NAME, ERC20_SYMBOL);
        __RelayRecipientUpgradeable_init();
        __AccessControl_init();

        __WalletHunters_init_unchained(
            admin_,
            trustedForwarder_,
            stakingToken_,
            votingDuration_,
            sheriffsRewardShare_,
            fixedSheriffReward_,
            minimalVotesForRequest_,
            minimalDepositForSheriff_,
            requestReward_
        );
    }

    function __WalletHunters_init_unchained(
        address admin,
        address trustedForwarder_,
        address stakingToken_,
        uint256 votingDuration_,
        uint256 sheriffsRewardShare_,
        uint256 fixedSheriffReward_,
        uint256 minimalVotesForRequest_,
        uint256 minimalDepositForSheriff_,
        uint256 requestReward_
    ) internal initializer {
        require(stakingToken_.isContract(), "StakingToken must be contract");
        require(
            trustedForwarder_.isContract(),
            "StakingToken must be contract"
        );

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MAYOR_ROLE, admin);

        stakingToken = IERC20Upgradeable(stakingToken_);

        super._setTrustedForwarder(trustedForwarder_);

        _updateConfiguration(
            votingDuration_,
            sheriffsRewardShare_,
            fixedSheriffReward_,
            minimalVotesForRequest_,
            minimalDepositForSheriff_,
            requestReward_
        );
    }

    function submitRequest(address hunter) external override returns (uint256) {
        require(_msgSender() == hunter, "Sender must be hunter");

        uint256 id = _requestCounter.current();
        _requestCounter.increment();

        Request storage _request = _requests[id];

        uint256 configurationIndex = _currentConfigurationIndex();

        _request.hunter = hunter;
        _request.reward = _configurations[configurationIndex].requestReward;
        _request.configurationIndex = configurationIndex;
        _request.discarded = false;
        // solhint-disable-next-line not-rely-on-time
        _request.creationTime = block.timestamp;

        // ignore return
        _activeRequests[hunter].add(id);

        emit NewWalletRequest(id, hunter, _request.reward);

        return id;
    }

    function stake(address sheriff, uint256 amount) external override {
        require(sheriff == _msgSender(), "Sender must be sheriff");
        require(amount > 0, "Cannot deposit 0");
        _mint(sheriff, amount);
        stakingToken.safeTransferFrom(sheriff, address(this), amount);
        emit Staked(sheriff, amount);
    }

    function vote(
        address sheriff,
        uint256 requestId,
        bool voteFor
    ) external override {
        require(sheriff == _msgSender(), "Sender must be sheriff");
        require(isSheriff(sheriff), "Sender is not sheriff");
        require(_votingState(requestId), "Voting is finished");
        require(
            _requests[requestId].hunter != sheriff,
            "Sheriff can't be hunter"
        );

        uint256 amount = balanceOf(sheriff);

        require(
            _activeRequests[sheriff].add(requestId),
            "User is already participated"
        );
        require(
            _requestVotings[requestId].voters.add(sheriff),
            "Sheriff is already participated"
        );
        _requestVotings[requestId].votes[sheriff].amount = amount;

        if (voteFor) {
            _requestVotings[requestId].votes[sheriff].voteFor = true;
            _requestVotings[requestId].votesFor =
                _requestVotings[requestId].votesFor +
                amount;
        } else {
            _requestVotings[requestId].votes[sheriff].voteFor = false;
            _requestVotings[requestId].votesAgainst =
                _requestVotings[requestId].votesAgainst +
                amount;
        }

        emit Voted(requestId, sheriff, amount, voteFor);
    }

    function discardRequest(uint256 requestId)
        external
        override
        onlyRole(MAYOR_ROLE)
    {
        require(_votingState(requestId), "Voting is finished");

        _requests[requestId].discarded = true;

        emit RequestDiscarded(requestId);
    }

    function withdraw(address sheriff, uint256 amount) public override {
        require(sheriff == _msgSender(), "Sender must be sheriff");
        require(amount > 0, "Cannot withdraw 0");
        uint256 available = balanceOf(sheriff) - lockedBalance(sheriff);
        require(amount <= available, "Withdraw exceeds balance");
        _burn(sheriff, amount);
        stakingToken.safeTransfer(sheriff, amount);
        emit Withdrawn(sheriff, amount);
    }

    function exit(address sheriff, uint256[] calldata requestIds)
        external
        override
    {
        claimRewards(sheriff, requestIds);
        withdraw(sheriff, balanceOf(sheriff));
    }

    function replenishRewardPool(address from, uint256 amount)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(from == _msgSender(), "Sender must be from address");
        rewardsPool += amount;

        stakingToken.safeTransferFrom(from, address(this), amount);

        emit ReplenishedRewardPool(from, amount);
    }

    function claimRewards(address user, uint256[] calldata requestIds)
        public
        override
    {
        require(user == _msgSender(), "Sender must be user");
        uint256 totalReward = 0;

        for (uint256 i = 0; i < requestIds.length; i++) {
            uint256 requestId = requestIds[i];

            uint256 reward = userReward(user, requestId);

            _activeRequests[user].remove(requestId);

            totalReward = totalReward + reward;
        }

        if (totalReward > 0) {
            _transferReward(user, totalReward);
        }

        emit UserRewardPaid(user, requestIds, totalReward);
    }

    function claimHunterReward(address hunter, uint256[] calldata requestIds)
        external
        override
    {
        require(hunter == _msgSender(), "Sender must be hunter");
        uint256 totalReward = 0;

        for (uint256 i = 0; i < requestIds.length; i++) {
            uint256 requestId = requestIds[i];

            uint256 reward = hunterReward(hunter, requestId);
            _activeRequests[hunter].remove(requestId);

            totalReward = totalReward + reward;
        }

        if (totalReward > 0) {
            _transferReward(hunter, totalReward);
        }

        emit HunterRewardPaid(hunter, requestIds, totalReward);
    }

    function claimSheriffRewards(address sheriff, uint256[] calldata requestIds)
        external
        override
    {
        require(sheriff == _msgSender(), "Sender must be sheriff");
        uint256 totalReward = 0;

        for (uint256 i = 0; i < requestIds.length; i++) {
            uint256 requestId = requestIds[i];

            uint256 reward = sheriffReward(sheriff, requestId);
            _activeRequests[sheriff].remove(requestId);

            totalReward = totalReward + reward;
        }

        if (totalReward > 0) {
            _transferReward(sheriff, totalReward);
        }

        emit SheriffRewardPaid(sheriff, requestIds, totalReward);
    }

    function updateConfiguration(
        uint256 _votingDuration,
        uint256 _sheriffsRewardShare,
        uint256 _fixedSheriffReward,
        uint256 _minimalVotesForRequest,
        uint256 _minimalDepositForSheriff,
        uint256 _requestReward
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateConfiguration(
            _votingDuration,
            _sheriffsRewardShare,
            _fixedSheriffReward,
            _minimalVotesForRequest,
            _minimalDepositForSheriff,
            _requestReward
        );
    }

    function configuration()
        external
        view
        override
        returns (
            uint256 votingDuration,
            uint256 sheriffsRewardShare,
            uint256 fixedSheriffReward,
            uint256 minimalVotesForRequest,
            uint256 minimalDepositForSheriff,
            uint256 requestReward
        )
    {
        Configuration storage _configuration =
            _configurations[_currentConfigurationIndex()];

        votingDuration = _configuration.votingDuration;
        sheriffsRewardShare = _configuration.sheriffsRewardShare;
        fixedSheriffReward = _configuration.fixedSheriffReward;
        minimalVotesForRequest = _configuration.minimalVotesForRequest;
        minimalDepositForSheriff = _configuration.minimalDepositForSheriff;
        requestReward = _configuration.requestReward;
    }

    function configurationAt(uint256 index)
        external
        view
        returns (
            uint256 votingDuration,
            uint256 sheriffsRewardShare,
            uint256 fixedSheriffReward,
            uint256 minimalVotesForRequest,
            uint256 minimalDepositForSheriff,
            uint256 requestReward
        )
    {
        require(
            index <= _currentConfigurationIndex(),
            "Configuration doesn't exist"
        );
        Configuration storage _configuration = _configurations[index];

        votingDuration = _configuration.votingDuration;
        sheriffsRewardShare = _configuration.sheriffsRewardShare;
        fixedSheriffReward = _configuration.fixedSheriffReward;
        minimalVotesForRequest = _configuration.minimalVotesForRequest;
        minimalDepositForSheriff = _configuration.minimalDepositForSheriff;
        requestReward = _configuration.requestReward;
    }

    function _currentConfigurationIndex() internal view returns (uint256) {
        return _configurations.length - 1;
    }

    function _updateConfiguration(
        uint256 _votingDuration,
        uint256 _sheriffsRewardShare,
        uint256 _fixedSheriffReward,
        uint256 _minimalVotesForRequest,
        uint256 _minimalDepositForSheriff,
        uint256 _requestReward
    ) internal {
        require(
            _votingDuration >= 10 minutes && _votingDuration <= 1 weeks,
            "Voting duration too long"
        );
        require(
            _sheriffsRewardShare > 0 && _sheriffsRewardShare < MAX_PERCENT,
            "Sheriff share too much"
        );

        _configurations.push(
            Configuration({
                votingDuration: _votingDuration,
                sheriffsRewardShare: _sheriffsRewardShare,
                fixedSheriffReward: _fixedSheriffReward,
                minimalVotesForRequest: _minimalVotesForRequest,
                minimalDepositForSheriff: _minimalDepositForSheriff,
                requestReward: _requestReward
            })
        );

        emit ConfigurationChanged(
            _votingDuration,
            _sheriffsRewardShare,
            _fixedSheriffReward,
            _minimalVotesForRequest,
            _minimalDepositForSheriff,
            _requestReward
        );
    }

    function walletProposalsLength() external view override returns (uint256) {
        return _requestCounter.current();
    }

    function walletProposals(uint256 startRequestId, uint256 pageSize)
        external
        view
        override
        returns (WalletProposal[] memory)
    {
        require(
            startRequestId + pageSize <= _requestCounter.current(),
            "Read index out of bounds"
        );

        WalletProposal[] memory result = new WalletProposal[](pageSize);

        for (uint256 i = 0; i < pageSize; i++) {
            _walletProposal(startRequestId + i, result[i]);
        }

        return result;
    }

    function walletProposal(uint256 requestId)
        public
        view
        override
        returns (WalletProposal memory)
    {
        require(requestId < _requestCounter.current(), "Request doesn't exist");
        WalletProposal memory proposal;

        _walletProposal(requestId, proposal);

        return proposal;
    }

    function _walletProposal(uint256 requestId, WalletProposal memory proposal)
        internal
        view
    {
        proposal.requestId = requestId;

        proposal.hunter = _requests[requestId].hunter;
        proposal.reward = _requests[requestId].reward;
        proposal.creationTime = _requests[requestId].creationTime;

        uint256 configurationIndex = _requests[requestId].configurationIndex;

        proposal.finishTime =
            _requests[requestId].creationTime +
            _configurations[configurationIndex].votingDuration;

        proposal.sheriffsRewardShare = _configurations[configurationIndex]
            .sheriffsRewardShare;
        proposal.fixedSheriffReward = _configurations[configurationIndex]
            .fixedSheriffReward;

        proposal.votesFor = _requestVotings[requestId].votesFor;
        proposal.votesAgainst = _requestVotings[requestId].votesAgainst;

        proposal.claimedReward = !_activeRequests[_requests[requestId].hunter]
            .contains(requestId);
        proposal.state = _walletState(requestId);
    }

    function getVotesLength(uint256 requestId)
        external
        view
        override
        returns (uint256)
    {
        return _requestVotings[requestId].voters.length();
    }

    function getVotes(
        uint256 requestId,
        uint256 startIndex,
        uint256 pageSize
    ) external view override returns (WalletVote[] memory) {
        require(
            startIndex + pageSize <= _requestVotings[requestId].voters.length(),
            "Read index out of bounds"
        );

        WalletVote[] memory result = new WalletVote[](pageSize);

        for (uint256 i = 0; i < pageSize; i++) {
            address voter =
                _requestVotings[requestId].voters.at(startIndex + i);
            _getVote(requestId, voter, result[i]);
        }

        return result;
    }

    function getVote(uint256 requestId, address sheriff)
        external
        view
        override
        returns (WalletVote memory)
    {
        WalletVote memory _vote;

        _getVote(requestId, sheriff, _vote);

        return _vote;
    }

    function _transferReward(address destination, uint256 amount) internal {
        require(amount <= rewardsPool, "Don't enough tokens in reward pool");

        rewardsPool -= amount;

        stakingToken.safeTransfer(destination, amount);
    }

    function _getVote(
        uint256 requestId,
        address sheriff,
        WalletVote memory _vote
    ) internal view {
        require(requestId < _requestCounter.current(), "Request doesn't exist");

        _vote.requestId = requestId;
        _vote.sheriff = sheriff;

        _vote.amount = _requestVotings[requestId].votes[sheriff].amount;
        _vote.voteFor = _requestVotings[requestId].votes[sheriff].voteFor;
    }

    function userRewards(address user)
        external
        view
        override
        returns (uint256)
    {
        uint256 totalReward = 0;

        for (uint256 i = 0; i < _activeRequests[user].length(); i++) {
            uint256 requestId = _activeRequests[user].at(i);

            if (_votingState(requestId)) {
                // voting is not finished
                continue;
            }

            uint256 reward = userReward(user, requestId);

            totalReward = totalReward + reward;
        }

        return totalReward;
    }

    function userReward(address user, uint256 requestId)
        public
        view
        override
        returns (uint256)
    {
        uint256 reward;
        if (_requests[requestId].hunter == user) {
            reward = hunterReward(user, requestId);
        } else {
            reward = sheriffReward(user, requestId);
        }

        return reward;
    }

    function hunterReward(address hunter, uint256 requestId)
        public
        view
        override
        returns (uint256)
    {
        require(!_votingState(requestId), "Voting is not finished");
        require(
            hunter == _requests[requestId].hunter,
            "Hunter isn't valid for request"
        );
        require(
            _activeRequests[hunter].contains(requestId),
            "Already rewarded"
        );

        if (!_isEnoughVotes(requestId) || _requests[requestId].discarded) {
            return 0;
        }

        if (_walletApproved(requestId)) {
            uint256 sheriffsRewardShare =
                _configurations[_requests[requestId].configurationIndex]
                    .sheriffsRewardShare;

            return
                (_requests[requestId].reward *
                    (MAX_PERCENT - sheriffsRewardShare)) / MAX_PERCENT;
        } else {
            return 0;
        }
    }

    function sheriffReward(address sheriff, uint256 requestId)
        public
        view
        override
        returns (uint256)
    {
        require(!_votingState(requestId), "Voting is not finished");
        require(
            _requestVotings[requestId].votes[sheriff].amount > 0,
            "Sheriff doesn't vote"
        );
        require(
            _activeRequests[sheriff].contains(requestId),
            "Already rewarded"
        );

        if (!_isEnoughVotes(requestId) || _requests[requestId].discarded) {
            return 0;
        }

        bool walletApproved = _walletApproved(requestId);

        if (
            walletApproved &&
            _requestVotings[requestId].votes[sheriff].voteFor
        ) {
            uint256 reward = _requests[requestId].reward;
            uint256 votes = _requestVotings[requestId].votes[sheriff].amount;
            uint256 totalVotes = _requestVotings[requestId].votesFor;
            uint256 sheriffsRewardShare =
                _configurations[_requests[requestId].configurationIndex]
                    .sheriffsRewardShare;
            uint256 fixedSheriffReward =
                _configurations[_requests[requestId].configurationIndex]
                    .fixedSheriffReward;

            uint256 actualReward =
                (((reward * votes) / totalVotes) * sheriffsRewardShare) /
                    MAX_PERCENT;

            return MathUpgradeable.max(actualReward, fixedSheriffReward);
        } else if (
            !walletApproved &&
            !_requestVotings[requestId].votes[sheriff].voteFor
        ) {
            return
                _configurations[_requests[requestId].configurationIndex]
                    .fixedSheriffReward;
        } else {
            return 0;
        }
    }

    function setTrustedForwarder(address trustedForwarder)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        super._setTrustedForwarder(trustedForwarder);
    }

    function activeRequests(
        address user,
        uint256 startIndex,
        uint256 pageSize
    ) external view override returns (uint256[] memory) {
        require(
            startIndex + pageSize <= _activeRequests[user].length(),
            "Read index out of bounds"
        );

        uint256[] memory result = new uint256[](pageSize);

        for (uint256 i = 0; i < pageSize; i++) {
            result[i] = _activeRequests[user].at(startIndex + i);
        }

        return result;
    }

    function activeRequest(address user, uint256 index)
        external
        view
        override
        returns (uint256)
    {
        return _activeRequests[user].at(index);
    }

    function activeRequestsLength(address user)
        external
        view
        override
        returns (uint256)
    {
        return _activeRequests[user].length();
    }

    function isSheriff(address sheriff) public view override returns (bool) {
        return
            balanceOf(sheriff) >=
            _configurations[_currentConfigurationIndex()]
                .minimalDepositForSheriff;
    }

    function lockedBalance(address user)
        public
        view
        override
        returns (uint256 locked)
    {
        locked = 0;

        for (uint256 i = 0; i < _activeRequests[user].length(); i++) {
            uint256 requestId = _activeRequests[user].at(i);
            if (!_votingState(requestId)) {
                // voting finished
                continue;
            }

            uint256 votes = _requestVotings[requestId].votes[user].amount;
            if (votes > locked) {
                locked = votes;
            }
        }
    }

    function _walletState(uint256 requestId) internal view returns (State) {
        if (_requests[requestId].discarded) {
            return State.DISCARDED;
        }

        if (_votingState(requestId)) {
            return State.ACTIVE;
        }

        if (_isEnoughVotes(requestId) && _walletApproved(requestId)) {
            return State.APPROVED;
        } else {
            return State.DECLINED;
        }
    }

    function _isEnoughVotes(uint256 requestId) internal view returns (bool) {
        uint256 totalVotes =
            _requestVotings[requestId].votesFor +
                _requestVotings[requestId].votesAgainst;

        uint256 minimalVotesForRequest =
            _configurations[_requests[requestId].configurationIndex]
                .minimalVotesForRequest;

        return totalVotes >= minimalVotesForRequest;
    }

    function _walletApproved(uint256 requestId) internal view returns (bool) {
        uint256 totalVotes =
            _requestVotings[requestId].votesFor +
                _requestVotings[requestId].votesAgainst;

        return
            (_requestVotings[requestId].votesFor * MAX_PERCENT) / totalVotes >
            SUPER_MAJORITY;
    }

    function _votingState(uint256 requestId) internal view returns (bool) {
        require(requestId < _requestCounter.current(), "Request doesn't exist");

        // solhint-disable-next-line not-rely-on-time
        uint256 votingDuration =
            _configurations[_requests[requestId].configurationIndex]
                .votingDuration;

        return
            block.timestamp <
            _requests[requestId].creationTime + votingDuration &&
            !_requests[requestId].discarded;
    }

    function _msgSender()
        internal
        view
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address)
    {
        return super._msgSender();
    }

    function _msgData()
        internal
        view
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return super._msgData();
    }
}
