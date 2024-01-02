// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "IERC20Metadata.sol";
import "Initializable.sol";
import "EnumerableSet.sol";

import "ILockingVault.sol";

import "DataTypes.sol";
import "ScaledMath.sol";
import "VotingPowerHistory.sol";

import "ImmutableOwner.sol";
import "LiquidityMining.sol";
import "BaseDelegatingVault.sol";

contract LockedVault is
    Initializable,
    BaseDelegatingVault,
    ILockingVault,
    ImmutableOwner,
    LiquidityMining
{
    using ScaledMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using VotingPowerHistory for VotingPowerHistory.History;

    string internal constant _VAULT_TYPE = "LockedVault";

    IERC20 public immutable underlying;
    uint256 internal withdrawalWaitDuration;

    // Mapping of a user's address to their pending withdrawal ids.
    mapping(address => EnumerableSet.UintSet) internal userPendingWithdrawalIds;

    mapping(uint256 => DataTypes.PendingWithdrawal) internal pendingWithdrawals;

    uint256 internal nextWithdrawalId;

    // Total supply of shares locked in the vault that are not queued for withdrawal
    uint256 public totalSupply;

    uint8 internal immutable _underlyingDecimals;

    constructor(
        address _owner,
        address _underlying,
        address _rewardsToken,
        address _daoTreasury
    ) ImmutableOwner(_owner) LiquidityMining(_rewardsToken, _daoTreasury) {
        underlying = IERC20(_underlying);
        _underlyingDecimals = IERC20Metadata(_underlying).decimals();
    }

    function initialize(
        uint256 _withdrawalWaitDuration
    ) external virtual initializer {
        __LockedVault_initialize(_withdrawalWaitDuration);
    }

    function startMining(
        address rewardsFrom,
        uint256 amount,
        uint256 endTime
    ) external override onlyOwner {
        _startMining(rewardsFrom, amount, endTime);
    }

    function stopMining() external override onlyOwner {
        _stopMining();
    }

    function setWithdrawalWaitDuration(uint256 _duration) external onlyOwner {
        withdrawalWaitDuration = _duration;
    }

    function deposit(uint256 _amount) external {
        deposit(_amount, msg.sender);
    }

    function deposit(uint256 _tokenAmount, address _delegate) public {
        require(_delegate != address(0), "no delegation to 0");
        require(_tokenAmount > 0, "cannot deposit zero amount");

        underlying.transferFrom(msg.sender, address(this), _tokenAmount);

        VotingPowerHistory.Record memory current = history.currentRecord(
            msg.sender
        );

        // internal accounting is done with 18 decimals
        uint256 scaledAmount = _tokenAmount.changeScale(
            _underlyingDecimals,
            18
        );
        history.updateVotingPower(
            msg.sender,
            current.baseVotingPower + scaledAmount,
            current.multiplier,
            current.netDelegatedVotes
        );
        if (_delegate != address(0) && _delegate != msg.sender) {
            _delegateVote(msg.sender, _delegate, scaledAmount);
        }
        totalSupply += scaledAmount;
        _stake(msg.sender, scaledAmount);

        emit Deposit(msg.sender, _delegate, _tokenAmount);
    }

    function initiateWithdrawal(
        uint256 _vaultTokenAmount,
        address _delegate
    ) external returns (uint256) {
        require(_vaultTokenAmount >= 0, "invalid withdrawal amount");

        VotingPowerHistory.Record memory currentVotingPower = history
            .currentRecord(msg.sender);

        bool undelegating = _delegate != address(0) && _delegate != msg.sender;

        // NOTE: voting power in locked vault always has a multiplier of 1e18 (default on initialization) and is never updated
        // therefore, we do not need to worry about it in the calculation of the condition below
        require(
            currentVotingPower.baseVotingPower >= _vaultTokenAmount &&
                (undelegating ||
                    currentVotingPower.baseVotingPower -
                        history.delegatedVotingPower(msg.sender) >=
                    _vaultTokenAmount),
            "not enough to undelegate"
        );
        history.updateVotingPower(
            msg.sender,
            currentVotingPower.baseVotingPower - _vaultTokenAmount,
            currentVotingPower.multiplier,
            currentVotingPower.netDelegatedVotes
        );
        if (undelegating) {
            _undelegateVote(msg.sender, _delegate, _vaultTokenAmount);
        }
        totalSupply -= _vaultTokenAmount;
        _unstake(msg.sender, _vaultTokenAmount);

        DataTypes.PendingWithdrawal memory withdrawal = DataTypes
            .PendingWithdrawal({
                id: nextWithdrawalId,
                withdrawableAt: block.timestamp + withdrawalWaitDuration,
                amount: _vaultTokenAmount,
                to: msg.sender,
                delegate: _delegate
            });
        pendingWithdrawals[withdrawal.id] = withdrawal;
        userPendingWithdrawalIds[msg.sender].add(withdrawal.id);
        nextWithdrawalId++;

        emit WithdrawalQueued(
            withdrawal.id,
            withdrawal.to,
            withdrawal.delegate,
            withdrawal.withdrawableAt,
            withdrawal.amount
        );

        return withdrawal.id;
    }

    function withdraw(uint256 withdrawalId) external {
        DataTypes.PendingWithdrawal memory pending = pendingWithdrawals[
            withdrawalId
        ];
        require(pending.to == msg.sender, "matching withdrawal does not exist");
        require(
            pending.withdrawableAt <= block.timestamp,
            "no valid pending withdrawal"
        );

        uint256 underlyingTokenAmount = pending.amount.changeScale(
            18,
            _underlyingDecimals
        );

        underlying.transfer(pending.to, underlyingTokenAmount);

        delete pendingWithdrawals[withdrawalId];
        userPendingWithdrawalIds[pending.to].remove(withdrawalId);

        emit WithdrawalCompleted(withdrawalId, pending.to, pending.amount);
    }

    function getRawVotingPower(
        address _user,
        uint256 timestamp
    ) public view override returns (uint256) {
        return history.getVotingPower(_user, timestamp);
    }

    function getTotalRawVotingPower()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return totalSupply;
    }

    function listPendingWithdrawals(
        address _user
    ) external view returns (DataTypes.PendingWithdrawal[] memory) {
        EnumerableSet.UintSet storage ids = userPendingWithdrawalIds[_user];
        DataTypes.PendingWithdrawal[]
            memory pending = new DataTypes.PendingWithdrawal[](ids.length());
        for (uint256 i = 0; i < ids.length(); i++) {
            pending[i] = pendingWithdrawals[ids.at(i)];
        }
        return pending;
    }

    function getVaultType() external pure returns (string memory) {
        return _VAULT_TYPE;
    }

    function __LockedVault_initialize(
        uint256 _withdrawalWaitDuration
    ) internal {
        withdrawalWaitDuration = _withdrawalWaitDuration;
        globalCheckpoint();
    }
}
