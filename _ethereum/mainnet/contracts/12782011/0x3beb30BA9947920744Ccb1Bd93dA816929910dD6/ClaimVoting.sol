// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./EnumerableSet.sol";
import "./ERC20.sol";

import "./DecimalsConverter.sol";

import "./IContractsRegistry.sol";
import "./IPriceFeed.sol";
import "./IClaimVoting.sol";
import "./IPolicyBookRegistry.sol";
import "./IReputationSystem.sol";
import "./IReinsurancePool.sol";
import "./IPolicyBook.sol";

import "./IVBMI.sol";

import "./AbstractDependant.sol";

import "./Globals.sol";

contract ClaimVoting is IClaimVoting, Initializable, AbstractDependant {
    using SafeMath for uint256;
    using Math for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    IPriceFeed public priceFeed;

    IERC20 public bmiToken;
    IReinsurancePool public reinsurancePool;
    IVBMI public vBMI;
    IClaimingRegistry public claimingRegistry;
    IPolicyBookRegistry public policyBookRegistry;
    IReputationSystem public reputationSystem;

    uint256 public stblDecimals;

    uint256 public constant PERCENTAGE_50 = 50 * PRECISION;

    uint256 public constant APPROVAL_PERCENTAGE = 66 * PRECISION;
    uint256 public constant PENALTY_THRESHOLD = 11 * PRECISION;
    uint256 public constant QUORUM = 10 * PRECISION;
    uint256 public constant CALCULATION_REWARD_PER_DAY = PRECISION;

    // claim index -> info
    mapping(uint256 => VotingResult) internal _votings;

    // voter -> claim indexes
    mapping(address => EnumerableSet.UintSet) internal _myNotCalculatedVotes;

    // voter -> voting indexes
    mapping(address => EnumerableSet.UintSet) internal _myVotes;

    // voter -> claim index -> vote index
    mapping(address => mapping(uint256 => uint256)) internal _allVotesToIndex;

    // vote index -> voting instance
    mapping(uint256 => VotingInst) internal _allVotesByIndexInst;

    EnumerableSet.UintSet internal _allVotesIndexes;

    uint256 private _voteIndex;

    event AnonymouslyVoted(uint256 claimIndex);
    event VoteExposed(uint256 claimIndex, address voter, uint256 suggestedClaimAmount);
    event VoteCalculated(uint256 claimIndex, address voter, VoteStatus status);
    event RewardsForVoteCalculationSent(address voter, uint256 bmiAmount);
    event RewardsForClaimCalculationSent(address calculator, uint256 bmiAmount);
    event ClaimCalculated(uint256 claimIndex, address calculator);

    modifier onlyPolicyBook() {
        require(policyBookRegistry.isPolicyBook(msg.sender), "CV: Not a PolicyBook");
        _;
    }

    function _isVoteAwaitingCalculation(uint256 index) internal view returns (bool) {
        uint256 claimIndex = _allVotesByIndexInst[index].claimIndex;

        return (_allVotesByIndexInst[index].status == VoteStatus.EXPOSED_PENDING &&
            !claimingRegistry.isClaimPending(claimIndex));
    }

    function _isVoteAwaitingExposure(uint256 index) internal view returns (bool) {
        uint256 claimIndex = _allVotesByIndexInst[index].claimIndex;

        return (_allVotesByIndexInst[index].status == VoteStatus.ANONYMOUS_PENDING &&
            claimingRegistry.isClaimExposablyVotable(claimIndex));
    }

    function _isVoteExpired(uint256 index) internal view returns (bool) {
        uint256 claimIndex = _allVotesByIndexInst[index].claimIndex;

        return (_allVotesByIndexInst[index].status == VoteStatus.ANONYMOUS_PENDING &&
            !claimingRegistry.isClaimVotable(claimIndex));
    }

    function __ClaimVoting_init() external initializer {
        _voteIndex = 1;
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        priceFeed = IPriceFeed(_contractsRegistry.getPriceFeedContract());
        claimingRegistry = IClaimingRegistry(_contractsRegistry.getClaimingRegistryContract());
        policyBookRegistry = IPolicyBookRegistry(
            _contractsRegistry.getPolicyBookRegistryContract()
        );
        reputationSystem = IReputationSystem(_contractsRegistry.getReputationSystemContract());
        reinsurancePool = IReinsurancePool(_contractsRegistry.getReinsurancePoolContract());
        vBMI = IVBMI(_contractsRegistry.getVBMIContract());
        bmiToken = IERC20(_contractsRegistry.getBMIContract());

        stblDecimals = ERC20(_contractsRegistry.getUSDTContract()).decimals();
    }

    /// @notice this function needs user's BMI approval of this address (check policybook)
    function initializeVoting(
        address claimer,
        address policyBookAddress,
        string calldata evidenceURI,
        uint256 coverTokens,
        uint256 reinsuranceTokensAmount,
        bool appeal
    ) external override onlyPolicyBook {
        require(coverTokens > 0, "CV: Claimer has no coverage");

        // this checks claim duplicate && appeal logic
        uint256 claimIndex =
            claimingRegistry.submitClaim(
                claimer,
                policyBookAddress,
                evidenceURI,
                coverTokens,
                appeal
            );

        uint256 onePercentInBMIToLock =
            priceFeed.howManyBMIsInUSDT(
                DecimalsConverter.convertFrom18(coverTokens.div(100), stblDecimals)
            );

        bmiToken.transferFrom(claimer, address(this), onePercentInBMIToLock); // needed approval

        reinsuranceTokensAmount = Math.min(reinsuranceTokensAmount, coverTokens.div(100));

        _votings[claimIndex].withdrawalAmount = coverTokens;
        _votings[claimIndex].lockedBMIAmount = onePercentInBMIToLock;
        _votings[claimIndex].reinsuranceTokensAmount = reinsuranceTokensAmount;
    }

    /// @dev check in BMIStaking when withdrawing, if true -> can withdraw
    function canWithdraw(address user) external view override returns (bool) {
        return _myNotCalculatedVotes[user].length() == 0;
    }

    /// @dev check when anonymously voting, if true -> can vote
    function canVote(address user) public view override returns (bool) {
        uint256 notCalculatedLength = _myNotCalculatedVotes[user].length();

        for (uint256 i = 0; i < notCalculatedLength; i++) {
            if (
                _isVoteAwaitingCalculation(
                    _allVotesToIndex[user][_myNotCalculatedVotes[user].at(i)]
                )
            ) {
                return false;
            }
        }

        return true;
    }

    function countVotes(address user) external view override returns (uint256) {
        return _myVotes[user].length();
    }

    function voteStatus(uint256 index) public view override returns (VoteStatus) {
        require(_allVotesIndexes.contains(index), "CV: Vote doesn't exist");

        if (_isVoteAwaitingCalculation(index)) {
            return VoteStatus.AWAITING_CALCULATION;
        } else if (_isVoteAwaitingExposure(index)) {
            return VoteStatus.AWAITING_EXPOSURE;
        } else if (_isVoteExpired(index)) {
            return VoteStatus.EXPIRED;
        }

        return _allVotesByIndexInst[index].status;
    }

    /// @dev use with claimingRegistry.countPendingClaims()
    function whatCanIVoteFor(uint256 offset, uint256 limit)
        external
        view
        override
        returns (uint256 _claimsCount, PublicClaimInfo[] memory _votablesInfo)
    {
        uint256 to = (offset.add(limit)).min(claimingRegistry.countPendingClaims()).max(offset);
        bool trustedVoter = reputationSystem.isTrustedVoter(msg.sender);

        _claimsCount = 0;

        _votablesInfo = new PublicClaimInfo[](to - offset);

        for (uint256 i = offset; i < to; i++) {
            uint256 index = claimingRegistry.pendingClaimIndexAt(i);

            if (
                _allVotesToIndex[msg.sender][index] == 0 &&
                claimingRegistry.claimOwner(index) != msg.sender &&
                claimingRegistry.isClaimAnonymouslyVotable(index) &&
                (!claimingRegistry.isClaimAppeal(index) || trustedVoter)
            ) {
                IClaimingRegistry.ClaimInfo memory claimInfo = claimingRegistry.claimInfo(index);

                _votablesInfo[_claimsCount].claimIndex = index;
                _votablesInfo[_claimsCount].claimer = claimInfo.claimer;
                _votablesInfo[_claimsCount].policyBookAddress = claimInfo.policyBookAddress;
                _votablesInfo[_claimsCount].evidenceURI = claimInfo.evidenceURI;
                _votablesInfo[_claimsCount].appeal = claimInfo.appeal;
                _votablesInfo[_claimsCount].claimAmount = claimInfo.claimAmount;
                _votablesInfo[_claimsCount].time = claimInfo.dateSubmitted;

                _votablesInfo[_claimsCount].time = _votablesInfo[_claimsCount]
                    .time
                    .add(claimingRegistry.anonymousVotingDuration(index))
                    .sub(block.timestamp);

                _claimsCount++;
            }
        }
    }

    /// @dev use with claimingRegistry.countClaims()
    function allClaims(uint256 offset, uint256 limit)
        external
        view
        override
        returns (AllClaimInfo[] memory _allClaimsInfo)
    {
        uint256 to = (offset.add(limit)).min(claimingRegistry.countClaims()).max(offset);

        _allClaimsInfo = new AllClaimInfo[](to - offset);

        for (uint256 i = offset; i < to; i++) {
            uint256 index = claimingRegistry.claimIndexAt(i);

            IClaimingRegistry.ClaimInfo memory claimInfo = claimingRegistry.claimInfo(index);

            _allClaimsInfo[i - offset].publicClaimInfo.claimIndex = index;
            _allClaimsInfo[i - offset].publicClaimInfo.claimer = claimInfo.claimer;
            _allClaimsInfo[i - offset].publicClaimInfo.policyBookAddress = claimInfo
                .policyBookAddress;
            _allClaimsInfo[i - offset].publicClaimInfo.evidenceURI = claimInfo.evidenceURI;
            _allClaimsInfo[i - offset].publicClaimInfo.appeal = claimInfo.appeal;
            _allClaimsInfo[i - offset].publicClaimInfo.claimAmount = claimInfo.claimAmount;
            _allClaimsInfo[i - offset].publicClaimInfo.time = claimInfo.dateSubmitted;

            _allClaimsInfo[i - offset].finalVerdict = claimInfo.status;

            if (
                _allClaimsInfo[i - offset].finalVerdict == IClaimingRegistry.ClaimStatus.ACCEPTED
            ) {
                _allClaimsInfo[i - offset].finalClaimAmount = _votings[index]
                    .votedAverageWithdrawalAmount;
            }

            if (claimingRegistry.canClaimBeCalculatedByAnyone(index)) {
                _allClaimsInfo[i - offset].bmiCalculationReward = _getBMIRewardForCalculation(
                    index
                );
            }
        }
    }

    /// @dev use with claimingRegistry.countPolicyClaimerClaims()
    function myClaims(uint256 offset, uint256 limit)
        external
        view
        override
        returns (MyClaimInfo[] memory _myClaimsInfo)
    {
        uint256 to =
            (offset.add(limit)).min(claimingRegistry.countPolicyClaimerClaims(msg.sender)).max(
                offset
            );

        _myClaimsInfo = new MyClaimInfo[](to - offset);

        for (uint256 i = offset; i < to; i++) {
            uint256 index = claimingRegistry.claimOfOwnerIndexAt(msg.sender, i);

            IClaimingRegistry.ClaimInfo memory claimInfo = claimingRegistry.claimInfo(index);

            _myClaimsInfo[i - offset].index = index;
            _myClaimsInfo[i - offset].policyBookAddress = claimInfo.policyBookAddress;
            _myClaimsInfo[i - offset].evidenceURI = claimInfo.evidenceURI;
            _myClaimsInfo[i - offset].appeal = claimInfo.appeal;
            _myClaimsInfo[i - offset].claimAmount = claimInfo.claimAmount;
            _myClaimsInfo[i - offset].finalVerdict = claimInfo.status;

            if (_myClaimsInfo[i - offset].finalVerdict == IClaimingRegistry.ClaimStatus.ACCEPTED) {
                _myClaimsInfo[i - offset].finalClaimAmount = _votings[index]
                    .votedAverageWithdrawalAmount;
            } else if (
                _myClaimsInfo[i - offset].finalVerdict ==
                IClaimingRegistry.ClaimStatus.AWAITING_CALCULATION
            ) {
                _myClaimsInfo[i - offset].bmiCalculationReward = _getBMIRewardForCalculation(
                    index
                );
            }
        }
    }

    /// @dev use with countVotes()
    function myVotes(uint256 offset, uint256 limit)
        external
        view
        override
        returns (MyVoteInfo[] memory _myVotesInfo)
    {
        uint256 to = (offset.add(limit)).min(_myVotes[msg.sender].length()).max(offset);

        _myVotesInfo = new MyVoteInfo[](to - offset);

        for (uint256 i = offset; i < to; i++) {
            VotingInst storage myVote = _allVotesByIndexInst[_myVotes[msg.sender].at(i)];

            uint256 index = myVote.claimIndex;

            IClaimingRegistry.ClaimInfo memory claimInfo = claimingRegistry.claimInfo(index);

            _myVotesInfo[i - offset].allClaimInfo.publicClaimInfo.claimIndex = index;
            _myVotesInfo[i - offset].allClaimInfo.publicClaimInfo.claimer = claimInfo.claimer;
            _myVotesInfo[i - offset].allClaimInfo.publicClaimInfo.policyBookAddress = claimInfo
                .policyBookAddress;
            _myVotesInfo[i - offset].allClaimInfo.publicClaimInfo.evidenceURI = claimInfo
                .evidenceURI;
            _myVotesInfo[i - offset].allClaimInfo.publicClaimInfo.appeal = claimInfo.appeal;
            _myVotesInfo[i - offset].allClaimInfo.publicClaimInfo.claimAmount = claimInfo
                .claimAmount;
            _myVotesInfo[i - offset].allClaimInfo.publicClaimInfo.time = claimInfo.dateSubmitted;

            _myVotesInfo[i - offset].allClaimInfo.finalVerdict = claimInfo.status;

            if (
                _myVotesInfo[i - offset].allClaimInfo.finalVerdict ==
                IClaimingRegistry.ClaimStatus.ACCEPTED
            ) {
                _myVotesInfo[i - offset].allClaimInfo.finalClaimAmount = _votings[index]
                    .votedAverageWithdrawalAmount;
            }

            _myVotesInfo[i - offset].suggestedAmount = myVote.suggestedAmount;
            _myVotesInfo[i - offset].status = voteStatus(_myVotes[msg.sender].at(i));

            if (_myVotesInfo[i - offset].status == VoteStatus.ANONYMOUS_PENDING) {
                _myVotesInfo[i - offset].time = claimInfo
                    .dateSubmitted
                    .add(claimingRegistry.anonymousVotingDuration(index))
                    .sub(block.timestamp);
            } else if (_myVotesInfo[i - offset].status == VoteStatus.AWAITING_EXPOSURE) {
                _myVotesInfo[i - offset].encryptedVote = myVote.encryptedVote;
                _myVotesInfo[i - offset].time = claimInfo
                    .dateSubmitted
                    .add(claimingRegistry.votingDuration(index))
                    .sub(block.timestamp);
            }
        }
    }

    /// @dev use with countVotes()
    function myVotesUpdates(uint256 offset, uint256 limit)
        external
        view
        override
        returns (
            uint256 _votesUpdatesCount,
            uint256[] memory _claimIndexes,
            VotesUpdatesInfo memory _myVotesUpdatesInfo
        )
    {
        uint256 to = (offset.add(limit)).min(_myVotes[msg.sender].length()).max(offset);
        _votesUpdatesCount = 0;

        _claimIndexes = new uint256[](to - offset);

        uint256 stblAmount;
        uint256 bmiAmount;
        uint256 bmiPenaltyAmount;
        uint256 newReputation;

        for (uint256 i = offset; i < to; i++) {
            uint256 claimIndex = _allVotesByIndexInst[_myVotes[msg.sender].at(i)].claimIndex;

            if (
                _myNotCalculatedVotes[msg.sender].contains(claimIndex) &&
                _isVoteAwaitingCalculation(_allVotesToIndex[msg.sender][claimIndex])
            ) {
                _claimIndexes[_votesUpdatesCount] = claimIndex;
                uint256 oldReputation = reputationSystem.reputation(msg.sender);

                if (
                    _votings[claimIndex].votedYesPercentage >= PERCENTAGE_50 &&
                    _allVotesByIndexInst[_allVotesToIndex[msg.sender][claimIndex]]
                        .suggestedAmount >
                    0
                ) {
                    (stblAmount, bmiAmount, newReputation) = _calculateMajorityYesVote(
                        claimIndex,
                        msg.sender,
                        oldReputation
                    );

                    _myVotesUpdatesInfo.reputationChange += int256(
                        newReputation.sub(oldReputation)
                    );
                } else if (
                    _votings[claimIndex].votedYesPercentage < PERCENTAGE_50 &&
                    _allVotesByIndexInst[_allVotesToIndex[msg.sender][claimIndex]]
                        .suggestedAmount ==
                    0
                ) {
                    (bmiAmount, newReputation) = _calculateMajorityNoVote(
                        claimIndex,
                        msg.sender,
                        oldReputation
                    );

                    _myVotesUpdatesInfo.reputationChange += int256(
                        newReputation.sub(oldReputation)
                    );
                } else {
                    (bmiPenaltyAmount, newReputation) = _calculateMinorityVote(
                        claimIndex,
                        msg.sender,
                        oldReputation
                    );

                    _myVotesUpdatesInfo.reputationChange -= int256(
                        oldReputation.sub(newReputation)
                    );
                    _myVotesUpdatesInfo.stakeChange -= int256(bmiPenaltyAmount);
                }

                _myVotesUpdatesInfo.bmiReward = _myVotesUpdatesInfo.bmiReward.add(bmiAmount);
                _myVotesUpdatesInfo.stblReward = _myVotesUpdatesInfo.stblReward.add(stblAmount);

                _votesUpdatesCount++;
            }
        }
    }

    function _calculateAverages(
        uint256 claimIndex,
        uint256 stakedBMI,
        uint256 suggestedClaimAmount,
        uint256 reputationWithPrecision,
        bool votedFor
    ) internal {
        VotingResult storage info = _votings[claimIndex];

        if (votedFor) {
            uint256 votedPower = info.votedYesStakedBMIAmountWithReputation;
            uint256 voterPower = stakedBMI.mul(reputationWithPrecision);
            uint256 totalPower = votedPower.add(voterPower);

            uint256 votedSuggestedPrice = info.votedAverageWithdrawalAmount.mul(votedPower);
            uint256 voterSuggestedPrice = suggestedClaimAmount.mul(voterPower);

            info.votedAverageWithdrawalAmount = votedSuggestedPrice.add(voterSuggestedPrice).div(
                totalPower
            );
            info.votedYesStakedBMIAmountWithReputation = totalPower;
        } else {
            info.votedNoStakedBMIAmountWithReputation = info
                .votedNoStakedBMIAmountWithReputation
                .add(stakedBMI.mul(reputationWithPrecision));
        }

        info.allVotedStakedBMIAmount = info.allVotedStakedBMIAmount.add(stakedBMI);
    }

    function _modifyExposedVote(
        address voter,
        uint256 claimIndex,
        uint256 suggestedClaimAmount,
        uint256 stakedBMI,
        bool accept
    ) internal {
        uint256 index = _allVotesToIndex[voter][claimIndex];

        _myNotCalculatedVotes[voter].add(claimIndex);

        _allVotesByIndexInst[index].finalHash = 0;
        delete _allVotesByIndexInst[index].encryptedVote;

        _allVotesByIndexInst[index].suggestedAmount = suggestedClaimAmount;
        _allVotesByIndexInst[index].stakedBMIAmount = stakedBMI;
        _allVotesByIndexInst[index].accept = accept;
        _allVotesByIndexInst[index].status = VoteStatus.EXPOSED_PENDING;
    }

    function _addAnonymousVote(
        address voter,
        uint256 claimIndex,
        bytes32 finalHash,
        string memory encryptedVote
    ) internal {
        _myVotes[voter].add(_voteIndex);

        _allVotesByIndexInst[_voteIndex].claimIndex = claimIndex;
        _allVotesByIndexInst[_voteIndex].finalHash = finalHash;
        _allVotesByIndexInst[_voteIndex].encryptedVote = encryptedVote;
        _allVotesByIndexInst[_voteIndex].voter = voter;
        _allVotesByIndexInst[_voteIndex].voterReputation = reputationSystem.reputation(voter);
        // No need to set default ANONYMOUS_PENDING status

        _allVotesToIndex[voter][claimIndex] = _voteIndex;
        _allVotesIndexes.add(_voteIndex);

        _voteIndex++;
    }

    function anonymouslyVoteBatch(
        uint256[] calldata claimIndexes,
        bytes32[] calldata finalHashes,
        string[] calldata encryptedVotes
    ) external override {
        require(canVote(msg.sender), "CV: There are awaiting votes");
        require(
            claimIndexes.length == finalHashes.length &&
                claimIndexes.length == encryptedVotes.length,
            "CV: Length mismatches"
        );

        for (uint256 i = 0; i < claimIndexes.length; i++) {
            uint256 claimIndex = claimIndexes[i];

            require(
                claimingRegistry.isClaimAnonymouslyVotable(claimIndex),
                "CV: Anonymous voting is over"
            );
            require(
                claimingRegistry.claimOwner(claimIndex) != msg.sender,
                "CV: Voter is the claimer"
            );
            require(
                !claimingRegistry.isClaimAppeal(claimIndex) ||
                    reputationSystem.isTrustedVoter(msg.sender),
                "CV: Not a trusted voter"
            );
            require(
                _allVotesToIndex[msg.sender][claimIndex] == 0,
                "CV: Already voted for this claim"
            );

            _addAnonymousVote(msg.sender, claimIndex, finalHashes[i], encryptedVotes[i]);

            emit AnonymouslyVoted(claimIndex);
        }
    }

    function exposeVoteBatch(
        uint256[] calldata claimIndexes,
        uint256[] calldata suggestedClaimAmounts,
        bytes32[] calldata hashedSignaturesOfClaims
    ) external override {
        require(
            claimIndexes.length == suggestedClaimAmounts.length &&
                claimIndexes.length == hashedSignaturesOfClaims.length,
            "CV: Length mismatches"
        );

        uint256 stakedBMI = vBMI.balanceOf(msg.sender); // use canWithdaw function in vBMI staking

        require(stakedBMI > 0, "CV: 0 staked BMI");

        for (uint256 i = 0; i < claimIndexes.length; i++) {
            uint256 claimIndex = claimIndexes[i];
            uint256 voteIndex = _allVotesToIndex[msg.sender][claimIndex];

            require(_allVotesIndexes.contains(voteIndex), "CV: Vote doesn't exist");
            require(_isVoteAwaitingExposure(voteIndex), "CV: Vote is not awaiting");

            bytes32 finalHash =
                keccak256(
                    abi.encodePacked(
                        hashedSignaturesOfClaims[i],
                        _allVotesByIndexInst[voteIndex].encryptedVote,
                        suggestedClaimAmounts[i]
                    )
                );

            require(_allVotesByIndexInst[voteIndex].finalHash == finalHash, "CV: Data mismatches");
            require(
                _votings[claimIndex].withdrawalAmount >= suggestedClaimAmounts[i],
                "CV: Amount succeds coverage"
            );

            bool voteFor = (suggestedClaimAmounts[i] > 0);

            _calculateAverages(
                claimIndex,
                stakedBMI,
                suggestedClaimAmounts[i],
                _allVotesByIndexInst[voteIndex].voterReputation,
                voteFor
            );

            _modifyExposedVote(
                msg.sender,
                claimIndex,
                suggestedClaimAmounts[i],
                stakedBMI,
                voteFor
            );

            emit VoteExposed(claimIndex, msg.sender, suggestedClaimAmounts[i]);
        }
    }

    function _getRewardRatio(
        uint256 claimIndex,
        address voter,
        uint256 votedStakedBMIAmountWithReputation
    ) internal view returns (uint256) {
        uint256 voteIndex = _allVotesToIndex[voter][claimIndex];

        uint256 voterBMI = _allVotesByIndexInst[voteIndex].stakedBMIAmount;
        uint256 voterReputation = _allVotesByIndexInst[voteIndex].voterReputation;

        return
            voterBMI.mul(voterReputation).mul(PERCENTAGE_100).div(
                votedStakedBMIAmountWithReputation
            );
    }

    function _calculateMajorityYesVote(
        uint256 claimIndex,
        address voter,
        uint256 oldReputation
    )
        internal
        view
        returns (
            uint256 _stblAmount,
            uint256 _bmiAmount,
            uint256 _newReputation
        )
    {
        VotingResult storage info = _votings[claimIndex];

        uint256 voterRatio =
            _getRewardRatio(claimIndex, voter, info.votedYesStakedBMIAmountWithReputation);

        if (claimingRegistry.claimStatus(claimIndex) == IClaimingRegistry.ClaimStatus.ACCEPTED) {
            // calculate STBL reward tokens sent to the voter (from reinsurance)
            _stblAmount = info.reinsuranceTokensAmount.mul(voterRatio).div(PERCENTAGE_100);
        } else {
            // calculate BMI reward tokens sent to the voter (from 1% locked)
            _bmiAmount = info.lockedBMIAmount.mul(voterRatio).div(PERCENTAGE_100);
        }

        _newReputation = reputationSystem.getNewReputation(oldReputation, info.votedYesPercentage);
    }

    function _calculateMajorityNoVote(
        uint256 claimIndex,
        address voter,
        uint256 oldReputation
    ) internal view returns (uint256 _bmiAmount, uint256 _newReputation) {
        VotingResult storage info = _votings[claimIndex];

        uint256 voterRatio =
            _getRewardRatio(claimIndex, voter, info.votedNoStakedBMIAmountWithReputation);

        // calculate BMI reward tokens sent to the voter (from 1% locked)
        _bmiAmount = info.lockedBMIAmount.mul(voterRatio).div(PERCENTAGE_100);

        _newReputation = reputationSystem.getNewReputation(
            oldReputation,
            PERCENTAGE_100.sub(info.votedYesPercentage)
        );
    }

    function _calculateMinorityVote(
        uint256 claimIndex,
        address voter,
        uint256 oldReputation
    ) internal view returns (uint256 _bmiPenalty, uint256 _newReputation) {
        uint256 minorityPercentageWithPrecision =
            Math.min(
                _votings[claimIndex].votedYesPercentage,
                PERCENTAGE_100.sub(_votings[claimIndex].votedYesPercentage)
            );

        if (minorityPercentageWithPrecision < PENALTY_THRESHOLD) {
            // calculate confiscated staked stkBMI tokens sent to reinsurance pool
            _bmiPenalty = Math.min(
                vBMI.balanceOf(voter),
                _allVotesByIndexInst[_allVotesToIndex[voter][claimIndex]]
                    .stakedBMIAmount
                    .mul(PENALTY_THRESHOLD.sub(minorityPercentageWithPrecision))
                    .div(PERCENTAGE_100)
            );
        }

        _newReputation = reputationSystem.getNewReputation(
            oldReputation,
            minorityPercentageWithPrecision
        );
    }

    function calculateVoterResultBatch(uint256[] calldata claimIndexes) external override {
        uint256 reputation = reputationSystem.reputation(msg.sender);

        for (uint256 i = 0; i < claimIndexes.length; i++) {
            uint256 claimIndex = claimIndexes[i];

            require(claimingRegistry.claimExists(claimIndex), "CV: Claim doesn't exist");

            uint256 voteIndex = _allVotesToIndex[msg.sender][claimIndex];

            require(_allVotesIndexes.contains(voteIndex), "CV: Vote doesn't exist");
            require(voteIndex != 0, "CV: No vote on this claim");
            require(_isVoteAwaitingCalculation(voteIndex), "CV: Vote is not awaiting");

            uint256 stblAmount;
            uint256 bmiAmount;
            VoteStatus status;

            if (
                _votings[claimIndex].votedYesPercentage >= PERCENTAGE_50 &&
                _allVotesByIndexInst[voteIndex].suggestedAmount > 0
            ) {
                (stblAmount, bmiAmount, reputation) = _calculateMajorityYesVote(
                    claimIndex,
                    msg.sender,
                    reputation
                );

                reinsurancePool.withdrawSTBLTo(msg.sender, stblAmount);
                bmiToken.transfer(msg.sender, bmiAmount);

                emit RewardsForVoteCalculationSent(msg.sender, bmiAmount);

                status = VoteStatus.MAJORITY;
            } else if (
                _votings[claimIndex].votedYesPercentage < PERCENTAGE_50 &&
                _allVotesByIndexInst[voteIndex].suggestedAmount == 0
            ) {
                (bmiAmount, reputation) = _calculateMajorityNoVote(
                    claimIndex,
                    msg.sender,
                    reputation
                );

                bmiToken.transfer(msg.sender, bmiAmount);

                emit RewardsForVoteCalculationSent(msg.sender, bmiAmount);

                status = VoteStatus.MAJORITY;
            } else {
                (bmiAmount, reputation) = _calculateMinorityVote(
                    claimIndex,
                    msg.sender,
                    reputation
                );

                vBMI.slashUserTokens(msg.sender, bmiAmount);

                status = VoteStatus.MINORITY;
            }

            _allVotesByIndexInst[voteIndex].status = status;
            _myNotCalculatedVotes[msg.sender].remove(claimIndex);

            emit VoteCalculated(claimIndex, msg.sender, status);
        }

        reputationSystem.setNewReputation(msg.sender, reputation);
    }

    function _getBMIRewardForCalculation(uint256 claimIndex) internal view returns (uint256) {
        uint256 lockedBMIs = _votings[claimIndex].lockedBMIAmount;
        uint256 timeElapsed =
            claimingRegistry.claimSubmittedTime(claimIndex).add(
                claimingRegistry.anyoneCanCalculateClaimResultAfter(claimIndex)
            );

        if (claimingRegistry.canClaimBeCalculatedByAnyone(claimIndex)) {
            timeElapsed = block.timestamp.sub(timeElapsed);
        } else {
            timeElapsed = timeElapsed.sub(block.timestamp);
        }

        return
            Math.min(
                lockedBMIs,
                lockedBMIs.mul(timeElapsed.mul(CALCULATION_REWARD_PER_DAY.div(1 days))).div(
                    PERCENTAGE_100
                )
            );
    }

    function _sendRewardsForCalculationTo(uint256 claimIndex, address calculator) internal {
        uint256 reward = _getBMIRewardForCalculation(claimIndex);

        _votings[claimIndex].lockedBMIAmount = _votings[claimIndex].lockedBMIAmount.sub(reward);

        bmiToken.transfer(calculator, reward);

        emit RewardsForClaimCalculationSent(calculator, reward);
    }

    function calculateVotingResultBatch(uint256[] calldata claimIndexes) external override {
        uint256 totalSupplyVBMI = vBMI.totalSupply();

        for (uint256 i = 0; i < claimIndexes.length; i++) {
            uint256 claimIndex = claimIndexes[i];
            address claimer = claimingRegistry.claimOwner(claimIndex);

            // claim existence is checked in claimStatus function
            require(
                claimingRegistry.claimStatus(claimIndex) ==
                    IClaimingRegistry.ClaimStatus.AWAITING_CALCULATION,
                "CV: Claim is not awaiting"
            );
            require(
                claimingRegistry.canClaimBeCalculatedByAnyone(claimIndex) || claimer == msg.sender,
                "CV: Not allowed to calculate"
            );

            _sendRewardsForCalculationTo(claimIndex, msg.sender);

            emit ClaimCalculated(claimIndex, msg.sender);

            uint256 allVotedVBMI = _votings[claimIndex].allVotedStakedBMIAmount;

            // if no votes or not an appeal and voted < 10% supply of vBMI
            if (
                allVotedVBMI == 0 ||
                ((totalSupplyVBMI == 0 ||
                    totalSupplyVBMI.mul(QUORUM).div(PERCENTAGE_100) > allVotedVBMI) &&
                    !claimingRegistry.isClaimAppeal(claimIndex))
            ) {
                // reject & use locked BMI for rewards
                claimingRegistry.rejectClaim(claimIndex);
            } else {
                uint256 votedYesPower = _votings[claimIndex].votedYesStakedBMIAmountWithReputation;
                uint256 votedNoPower = _votings[claimIndex].votedNoStakedBMIAmountWithReputation;
                uint256 totalPower = votedYesPower.add(votedNoPower);

                _votings[claimIndex].votedYesPercentage = votedYesPower.mul(PERCENTAGE_100).div(
                    totalPower
                );

                if (_votings[claimIndex].votedYesPercentage >= APPROVAL_PERCENTAGE) {
                    // approve + send STBL & return locked BMI to the claimer
                    claimingRegistry.acceptClaim(claimIndex);

                    bmiToken.transfer(claimer, _votings[claimIndex].lockedBMIAmount);
                } else {
                    // reject & use locked BMI for rewards
                    claimingRegistry.rejectClaim(claimIndex);
                }
            }

            IPolicyBook(claimingRegistry.claimPolicyBook(claimIndex)).commitClaim(
                claimer,
                _votings[claimIndex].votedAverageWithdrawalAmount,
                block.timestamp,
                claimingRegistry.claimStatus(claimIndex) // ACCEPTED, REJECTED_CAN_APPEAL, REJECTED
            );
        }
    }
}
