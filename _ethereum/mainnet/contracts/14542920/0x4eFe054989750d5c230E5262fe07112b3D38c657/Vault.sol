pragma solidity ^0.6.0;

import "./BaseVaultV2.sol";
import "./VaultWithAutoStake.sol";
import "./VaultWithFees.sol";
import "./VaultWithReferralProgram.sol";

/// @title CVXVault
/// @notice Vault for staking of CVX and receive rewards in cvxCRV
contract Vault is
    BaseVaultV2,
    VaultWithAutoStake,
    VaultWithFees,
    VaultWithReferralProgram
{
    constructor(string memory _name, string memory _symbol)
        public
        BaseVaultV2(_name, _symbol)
    {}

    function configure(
        address _initialToken,
        address _initialController,
        address _governance,
        uint256 _rewardsDuration,
        address _tokenToAutostake,
        address _votingStakingRewards,
        bool _enableFees,
        address _depositFeeWallet,
        address _referralProgram,
        address _treasury,
        address[] memory _rewardsTokens,
        string memory _namePostfix,
        string memory _symbolPostfix
    ) public onlyOwner initializer {
        _configureVaultWithAutoStake(_tokenToAutostake, _votingStakingRewards);
        _configureVaultWithFees(_depositFeeWallet, _enableFees);
        _configureVaultWithReferralProgram(_referralProgram, _treasury);
        _configure(
            _initialToken,
            _initialController,
            _governance,
            _rewardsDuration,
            _rewardsTokens,
            _namePostfix,
            _symbolPostfix
        );
    }

    function _deposit(address _from, uint256 _amount)
        internal
        override
        returns (uint256)
    {
        _amount = _getFeesOnDeposit(stakingToken, _amount);
        super._deposit(_from, _amount);
        _registerUserInReferralProgramIfNeeded(_from);
        return _amount;
    }

    function _getReward(
        bool _claimUnderlying,
        address _for,
        address _rewardToken,
        address _stakingToken
    )
        internal
        override
    {
        if (_claimUnderlying) {
            _controller.getRewardStrategy(_stakingToken);
        }
        _controller.claim(_stakingToken, _rewardToken);
        uint256 reward = rewards[_for][_rewardToken];
        if (reward > 0) {
            rewards[_for][_rewardToken] = 0;
            reward = _getFeesOnClaimForToken(_for, _rewardToken, reward);
            _autoStakeForOrSendTo(_rewardToken, reward, _for);
        }
        emit RewardPaid(_rewardToken, _for, reward);
    }
}
