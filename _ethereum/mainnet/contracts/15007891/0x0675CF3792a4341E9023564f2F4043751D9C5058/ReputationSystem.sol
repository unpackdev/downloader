// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";
import "./SafeMath.sol";
import "./Math.sol";

import "./IReputationSystem.sol";
import "./IContractsRegistry.sol";

import "./AbstractDependant.sol";

import "./Globals.sol";

contract ReputationSystem is IReputationSystem, Initializable, AbstractDependant {
    using SafeMath for uint256;
    using Math for uint256;

    uint8 internal constant REPUTATION_PRECISION = 31; // should not be changed

    uint256 public constant MAXIMUM_REPUTATION = 3 * PRECISION; // 3
    uint256 public constant MINIMUM_REPUTATION = PRECISION / 10; // 0.1

    uint256 public constant PERCENTAGE_OF_TRUSTED_VOTERS = 15 * PRECISION;
    uint256 public constant LEAST_TRUSTED_VOTER_REPUTATION = 20; // 2.0
    uint256 public constant MINIMUM_TRUSTED_VOTERS = 5;

    address public claimVoting;

    uint256 internal _trustedVoterReputationThreshold; // 2.0

    uint256[] internal _roundedReputations; // 0.1 is 1, 3 is 30, 0 is empty

    uint256 internal _votedOnceCount;

    mapping(address => uint256) internal _reputation; // user -> reputation (0.1 * PRECISION to 3.0 * PRECISION)

    event ReputationSet(address user, uint256 newReputation);

    modifier onlyClaimVoting() {
        require(
            claimVoting == msg.sender,
            "ReputationSystem: Caller is not a ClaimVoting contract"
        );
        _;
    }

    function __ReputationSystem_init(address[] calldata team) external initializer {
        _trustedVoterReputationThreshold = 20;
        _roundedReputations = new uint256[](REPUTATION_PRECISION);

        _initTeamReputation(team);
    }

    function _initTeamReputation(address[] memory team) internal {
        for (uint8 i = 0; i < team.length; i++) {
            _setNewReputation(team[i], MAXIMUM_REPUTATION);
        }

        _recalculateTrustedVoterReputationThreshold();
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        claimVoting = _contractsRegistry.getClaimVotingContract();
    }

    function setNewReputation(address voter, uint256 newReputation)
        external
        override
        onlyClaimVoting
    {
        _setNewReputation(voter, newReputation);
        _recalculateTrustedVoterReputationThreshold();
    }

    function _setNewReputation(address voter, uint256 newReputation) internal {
        require(newReputation >= PRECISION.div(10), "ReputationSystem: reputation too low");
        require(newReputation <= PRECISION.mul(3), "ReputationSystem: reputation too high");

        uint256 voterReputation = _reputation[voter];

        if (voterReputation == 0) {
            _votedOnceCount = _votedOnceCount.add(1);
            voterReputation = PRECISION;
        }

        uint256 flooredOldReputation = voterReputation.mul(10).div(PRECISION);

        _reputation[voter] = newReputation;

        uint256 flooredNewReputation = newReputation.mul(10).div(PRECISION);

        emit ReputationSet(voter, newReputation);

        if (flooredOldReputation == flooredNewReputation) {
            return;
        }

        if (_roundedReputations[flooredOldReputation] > 0) {
            _roundedReputations[flooredOldReputation]--;
        }

        _roundedReputations[flooredNewReputation]++;
    }

    function _recalculateTrustedVoterReputationThreshold() internal {
        uint256 trustedVotersAmount =
            Math.max(
                MINIMUM_TRUSTED_VOTERS,
                _votedOnceCount.mul(PERCENTAGE_OF_TRUSTED_VOTERS).div(PERCENTAGE_100)
            );
        uint256 votersAmount;

        for (uint8 i = REPUTATION_PRECISION - 1; i >= LEAST_TRUSTED_VOTER_REPUTATION; i--) {
            uint256 roundedReputationVoters = _roundedReputations[i];
            votersAmount = votersAmount.add(roundedReputationVoters);

            if (votersAmount >= trustedVotersAmount) {
                if (
                    votersAmount >= trustedVotersAmount.mul(3).div(2) &&
                    votersAmount > roundedReputationVoters
                ) {
                    i++;
                }

                _trustedVoterReputationThreshold = i;
                break;
            }

            if (i == LEAST_TRUSTED_VOTER_REPUTATION) {
                _trustedVoterReputationThreshold = LEAST_TRUSTED_VOTER_REPUTATION;
            }
        }
    }

    function getNewReputation(address voter, uint256 percentageWithPrecision)
        external
        view
        override
        returns (uint256)
    {
        uint256 reputationVoter = _reputation[voter];

        return
            getNewReputation(
                reputationVoter == 0 ? PRECISION : reputationVoter,
                percentageWithPrecision
            );
    }

    function getNewReputation(uint256 voterReputation, uint256 percentageWithPrecision)
        public
        pure
        override
        returns (uint256)
    {
        require(
            percentageWithPrecision <= PERCENTAGE_100,
            "ReputationSystem: Percentage can't be more than 100%"
        );
        require(voterReputation >= PRECISION.div(10), "ReputationSystem: reputation too low");
        require(voterReputation <= PRECISION.mul(3), "ReputationSystem: reputation too high");

        if (percentageWithPrecision >= PRECISION.mul(50)) {
            return
                Math.min(
                    MAXIMUM_REPUTATION,
                    voterReputation.add(percentageWithPrecision.div(100).div(20))
                );
        } else {
            uint256 squared = PERCENTAGE_100.sub(percentageWithPrecision.mul(2));
            uint256 fraction = squared.mul(squared).div(2).div(PERCENTAGE_100).div(100);

            return
                fraction < voterReputation
                    ? Math.max(MINIMUM_REPUTATION, voterReputation.sub(fraction))
                    : MINIMUM_REPUTATION;
        }
    }

    function hasVotedOnce(address user) external view override returns (bool) {
        return _reputation[user] > 0;
    }

    /// @dev this function will count voters as trusted that have initial reputation >= 2.0
    /// regardless of how many times have they voted
    function isTrustedVoter(address user) external view override returns (bool) {
        return _reputation[user] >= _trustedVoterReputationThreshold.mul(PRECISION).div(10);
    }

    /// @notice this function returns reputation threshold multiplied by 10**25
    function getTrustedVoterReputationThreshold() external view override returns (uint256) {
        return _trustedVoterReputationThreshold.mul(PRECISION).div(10);
    }

    /// @notice this function returns reputation multiplied by 10**25
    function reputation(address user) external view override returns (uint256) {
        return _reputation[user] == 0 ? PRECISION : _reputation[user];
    }
}
