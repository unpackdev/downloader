// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "./IERC1155.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./SafeCast.sol";
import "./PrimeRewards.sol";

/// @title The EthAndPrimeRewards staking contract
/// @notice Staking contract for The Core. It allows for a fixed ETH
/// rewards distributed evenly across all staked tokens per second.
contract EthAndPrimeRewards is PrimeRewards {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    /// @notice Info of each Deposit.
    /// `rewardDebt` The amount of ETH not entitled to the user.
    struct EthDepositInfo {
        int256 rewardDebt;
    }

    /// @notice Info of each ethPool. EthPoolInfo is independent of PoolInfo.
    /// Contains the start and end timestamps of the rewards
    struct EthPoolInfo {
        uint256 accEthPerShare; // in wei
        uint256 allocPoint;
        uint256 lastRewardTimestamp;
    }

    /// @notice Info of each ethPool.
    EthPoolInfo[] public ethPoolInfo;

    /// @notice Eth amount distributed for given period. ethAmountPerSecond = ethAmount / (ethEndTimestamp - ethStartTimestamp)
    uint256 public ethStartTimestamp; // staking start timestamp.
    uint256 public ethEndTimestamp; // staking end timestamp.
    uint256 public ethAmount; // the amount of ETH to give out as rewards.
    uint256 public ethAmountPerSecond; // the amount of ETH to give out as rewards per second.
    uint256 public constant ethAmountPerSecondPrecision = 1e18; // ethAmountPerSecond is carried around with extra precision to reduce rounding errors

    /// @dev Total allocation points. Must be the sum of all allocation points in all ethPools.
    uint256 public ethTotalAllocPoint;

    /// @notice Deposit info of each user that stakes nft sets.
    // ethPoolID(per set) => user address => deposit info
    mapping(uint256 => mapping(address => EthDepositInfo))
        public ethDepositInfo;

    /// @param _prime The PRIME token contract address.
    /// @param _parallelAlpha The Parallel Alpha contract address.
    constructor(IERC20 _prime, IERC1155 _parallelAlpha)
        PrimeRewards(_prime, _parallelAlpha)
    {}

    /// @notice Add a new tokenIds ethPool. Can only be called by the owner.
    /// DO NOT add the same token id more than once. Rewards will be messed up if you do.
    /// @param _allocPoint AP of the new ethPool.
    /// @param _tokenIds TokenIds for a ParallelAlpha ERC1155 tokens.
    function addPool(uint256 _allocPoint, uint256[] memory _tokenIds)
        public
        override
        onlyOwner
    {
        // Update all ethPools cause allocpoints
        for (uint256 i = 0; i < ethPoolInfo.length; ++i) {
            updateEthPool(i);
        }
        ethTotalAllocPoint += _allocPoint;
        ethPoolInfo.push(
            EthPoolInfo({
                accEthPerShare: 0,
                allocPoint: _allocPoint,
                lastRewardTimestamp: Math.max(
                    block.timestamp,
                    ethStartTimestamp
                )
            })
        );

        PrimeRewards.addPool(_allocPoint, _tokenIds);
        emit LogPoolSetAllocPoint(
            ethPoolInfo.length - 1,
            _allocPoint,
            ethTotalAllocPoint,
            ID_ETH
        );
    }

    // Set remaining eth to distribute between ethEndTimestamp-ethStartTimestamp

    /// @notice Set new cycle/period to distribute rewards between endTimestamp-startTimestamp
    /// evenly per second. ethAmountPerSecond = msg.value / _ethEndTimestamp - _ethStartTimestamp
    /// @param _ethStartTimestamp Timestamp for staking period to start at
    /// @param _ethEndTimestamp Timestamp for staking period to end at
    function setEthPerSecond(
        uint256 _ethStartTimestamp,
        uint256 _ethEndTimestamp
    ) external payable onlyOwner {
        require(
            _ethStartTimestamp < _ethEndTimestamp,
            "endTimestamp cant be less than startTimestamp"
        );
        require(
            block.timestamp < ethStartTimestamp ||
                ethEndTimestamp < block.timestamp,
            "Only updates after ethEndTimestamp or before ethStartTimestamp"
        );
        // Update all ethPools before proceeding, ensure rewards calculated up to this timestamp
        for (uint256 i = 0; i < ethPoolInfo.length; ++i) {
            updateEthPool(i);
            ethPoolInfo[i].lastRewardTimestamp = _ethStartTimestamp;
        }
        ethAmount = msg.value;
        ethStartTimestamp = _ethStartTimestamp;
        ethEndTimestamp = _ethEndTimestamp;
        ethAmountPerSecond =
            (msg.value * ethAmountPerSecondPrecision) /
            (_ethEndTimestamp - _ethStartTimestamp);
        emit LogSetPerSecond(
            msg.value,
            _ethStartTimestamp,
            _ethEndTimestamp,
            ID_ETH
        );
    }

    /// @notice Update ethEndTimestamp, only possible to call this when staking for
    /// a period has already begun and new ethEndTimestamp can't be in the past
    /// @param _ethEndTimestamp New timestamp for staking period to end at
    function setEthEndTimestamp(uint256 _ethEndTimestamp) external onlyOwner {
        require(
            ethStartTimestamp < block.timestamp,
            "staking have not started yet"
        );
        require(block.timestamp < _ethEndTimestamp, "invalid end timestamp");
        for (uint256 i = 0; i < ethPoolInfo.length; ++i) {
            updateEthPool(i);
        }

        // Update ethAmountPerSecond based on the new ethEndTimestamp
        ethStartTimestamp = block.timestamp;
        ethEndTimestamp = _ethEndTimestamp;
        ethAmountPerSecond =
            (ethAmount * ethAmountPerSecondPrecision) /
            (ethEndTimestamp - ethStartTimestamp);
        emit EndTimestampUpdated(_ethEndTimestamp, ID_ETH);
    }

    /// @notice Function for 'Top Ups', adds additional ETH to distribute for remaining time
    /// in the period.
    function addEthAmount() external payable onlyOwner {
        require(
            ethStartTimestamp < block.timestamp &&
                block.timestamp < ethEndTimestamp,
            "Only topups inside a period"
        );
        // Update all ethPools
        for (uint256 i = 0; i < ethPoolInfo.length; ++i) {
            updateEthPool(i);
        }
        // Top up current cycle's ETH
        ethAmount += msg.value;
        ethAmountPerSecond =
            (ethAmount * ethAmountPerSecondPrecision) /
            (ethEndTimestamp - block.timestamp);
        emit RewardIncrease(msg.value, ID_ETH);
    }

    /// @notice Function for 'Top Downs', removes additional ETH to distribute for remaining time
    /// in the period.
    /// @param _removeEthAmount Amount of ETH to remove from the remaining reward pool
    function removeEthAmount(uint256 _removeEthAmount) external onlyOwner {
        require(
            ethStartTimestamp < block.timestamp &&
                block.timestamp < ethEndTimestamp,
            "Only topdowns inside a period"
        );
        // Update all ethPools
        for (uint256 i = 0; i < ethPoolInfo.length; ++i) {
            updateEthPool(i);
        }
        // Top up current cycle's ETH
        _removeEthAmount = Math.min(_removeEthAmount, ethAmount);
        ethAmount -= _removeEthAmount;
        ethAmountPerSecond =
            (ethAmount * ethAmountPerSecondPrecision) /
            (ethEndTimestamp - block.timestamp);

        (bool sent, ) = msg.sender.call{ value: _removeEthAmount }("");
        require(sent, "Failed to send Ether");

        emit RewardDecrease(_removeEthAmount, ID_ETH);
    }

    /// @notice Update the given ethPool's ETH allocation point.  Can only be called by the owner.
    /// @param _pid The index of the ethPool. See `ethPoolInfo`.
    /// @param _allocPoint New AP of the ethPool.
    function setEthPoolAllocPoint(uint256 _pid, uint256 _allocPoint)
        external
        onlyOwner
    {
        // Update all ethPools
        for (uint256 i = 0; i < ethPoolInfo.length; ++i) {
            updateEthPool(i);
        }
        ethTotalAllocPoint =
            ethTotalAllocPoint -
            ethPoolInfo[_pid].allocPoint +
            _allocPoint;
        ethPoolInfo[_pid].allocPoint = _allocPoint;
        emit LogPoolSetAllocPoint(
            _pid,
            _allocPoint,
            ethTotalAllocPoint,
            ID_ETH
        );
    }

    /// @notice View function to see pending ETH on frontend.
    /// @param _pid The index of the ethPool. See `ethPoolInfo`.
    /// @param _user Address of user.
    /// @return pending ETH reward for a given user.
    function pendingEth(uint256 _pid, address _user)
        external
        view
        returns (uint256 pending)
    {
        PoolInfo memory pool = poolInfo[_pid];
        DepositInfo storage deposit_ = depositInfo[_pid][_user];
        EthPoolInfo memory ethPool = ethPoolInfo[_pid];
        EthDepositInfo storage ethDeposit = ethDepositInfo[_pid][_user];
        uint256 accEthPerShare = ethPool.accEthPerShare;
        uint256 totalSupply = pool.totalSupply;

        if (
            ethStartTimestamp <= block.timestamp &&
            ethPool.lastRewardTimestamp < block.timestamp &&
            totalSupply > 0
        ) {
            uint256 updateToTimestamp = Math.min(
                block.timestamp,
                ethEndTimestamp
            );
            uint256 secondsStaked = updateToTimestamp -
                ethPool.lastRewardTimestamp;
            uint256 ethReward = (secondsStaked *
                ethAmountPerSecond *
                ethPool.allocPoint) / ethTotalAllocPoint;
            accEthPerShare += ethReward / totalSupply;
        }
        pending =
            ((deposit_.amount * accEthPerShare).toInt256() -
                ethDeposit.rewardDebt).toUint256() /
            ethAmountPerSecondPrecision;
    }

    /// @notice Update reward variables for all ethPools. Be careful of gas spending!
    /// @param _pids Pool IDs of all to be updated. Make sure to update all active ethPools.
    function massUpdateEthPools(uint256[] calldata _pids) external {
        uint256 len = _pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updateEthPool(_pids[i]);
        }
    }

    /// @notice Update reward variables of the given ethPool.
    /// @param _pid The index of the ethPool. See `ethPoolInfo`.
    function updateEthPool(uint256 _pid) public {
        PoolInfo memory pool = poolInfo[_pid];
        EthPoolInfo storage ethPool = ethPoolInfo[_pid];
        uint256 totalSupply = pool.totalSupply;
        if (
            ethStartTimestamp > block.timestamp ||
            ethPool.lastRewardTimestamp >= block.timestamp ||
            (ethStartTimestamp == 0 && ethEndTimestamp == 0)
        ) {
            return;
        }

        uint256 updateToTimestamp = Math.min(block.timestamp, ethEndTimestamp);
        uint256 secondsStaked = updateToTimestamp - ethPool.lastRewardTimestamp;
        uint256 ethReward = (secondsStaked *
            ethAmountPerSecond *
            ethPool.allocPoint) / ethTotalAllocPoint;
        ethAmount -= ethReward / ethAmountPerSecondPrecision;
        if (totalSupply > 0) {
            ethPool.accEthPerShare += ethReward / totalSupply;
        }
        ethPool.lastRewardTimestamp = updateToTimestamp;
        emit LogUpdatePool(
            _pid,
            ethPool.lastRewardTimestamp,
            totalSupply,
            ethPool.accEthPerShare,
            ID_ETH
        );
    }

    /// @notice Deposit tokens for ETH & PRIME allocation.
    /// @param _pid The index of the ethPool. See `ethPoolInfo`.
    /// @param _amount Amount of tokens to deposit for _pid.
    function deposit(uint256 _pid, uint256 _amount) public virtual override {
        require(_amount > 0, "Specify valid token amount to deposit");
        updateEthPool(_pid);
        EthDepositInfo storage ethDeposit = ethDepositInfo[_pid][msg.sender];

        // Effects
        ethDeposit.rewardDebt += (_amount * ethPoolInfo[_pid].accEthPerShare)
            .toInt256();

        PrimeRewards.deposit(_pid, _amount);
    }

    /// @notice Withdraw tokens.
    /// @param _pid The index of the ethPool. See `ethPoolInfo`.
    /// @param _amount amounts to withdraw from the pool
    function withdraw(uint256 _pid, uint256 _amount) public virtual override {
        updateEthPool(_pid);
        EthDepositInfo storage ethDeposit = ethDepositInfo[_pid][msg.sender];

        // Effects
        ethDeposit.rewardDebt -= (_amount * ethPoolInfo[_pid].accEthPerShare)
            .toInt256();

        PrimeRewards.withdraw(_pid, _amount);
    }

    /// @notice Claim accumulated eth rewards.
    /// @param _pid The index of the ethPool. See `ethPoolInfo`.
    function claimEth(uint256 _pid) public {
        updateEthPool(_pid);
        DepositInfo storage deposit_ = depositInfo[_pid][msg.sender];
        EthDepositInfo storage ethDeposit = ethDepositInfo[_pid][msg.sender];

        int256 accumulatedEth = (deposit_.amount *
            ethPoolInfo[_pid].accEthPerShare).toInt256();
        uint256 _pendingEth = (accumulatedEth - ethDeposit.rewardDebt)
            .toUint256() / ethAmountPerSecondPrecision;

        // Effects
        ethDeposit.rewardDebt = accumulatedEth;

        // Interactions
        if (_pendingEth != 0) {
            (bool sent, ) = msg.sender.call{ value: _pendingEth }("");
            require(sent, "Failed to send Ether");
        }

        emit Claim(msg.sender, _pid, _pendingEth, ID_ETH);
    }

    /// @notice ClaimPrime and ClaimETH a pool
    /// @param _pid Pool IDs of all to be claimed
    function claimEthAndPrime(uint256 _pid) public virtual {
        PrimeRewards.claimPrime(_pid);
        claimEth(_pid);
    }

    /// @notice ClaimPrime multiple ethPools
    /// @param _pids Pool IDs of all to be claimed
    function claimPools(uint256[] calldata _pids) external virtual {
        for (uint256 i = 0; i < _pids.length; ++i) {
            claimEthAndPrime(_pids[i]);
        }
    }

    /// @notice Withdraw and claim prime rewards, update eth reward dept so that user can claim eth after.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _amount Amount of tokenId sets to withdraw.
    function withdrawAndClaimPrime(uint256 _pid, uint256 _amount)
        public
        virtual
        override
    {
        updateEthPool(_pid);
        EthDepositInfo storage ethDeposit = ethDepositInfo[_pid][msg.sender];

        // Effects
        ethDeposit.rewardDebt -= (_amount * ethPoolInfo[_pid].accEthPerShare)
            .toInt256();

        PrimeRewards.withdrawAndClaimPrime(_pid, _amount);
    }

    /// @notice Withdraw and claim prime & eth rewards.
    /// @param _pid The index of the ethPool. See `ethPoolInfo`.
    /// @param _amount tokens amount to withdraw.
    function withdrawAndClaimEthAndPrime(uint256 _pid, uint256 _amount)
        external
        virtual
    {
        // Claim ETH
        updateEthPool(_pid);
        DepositInfo storage deposit_ = depositInfo[_pid][msg.sender];
        EthDepositInfo storage ethDeposit = ethDepositInfo[_pid][msg.sender];

        int256 accumulatedEth = (deposit_.amount *
            ethPoolInfo[_pid].accEthPerShare).toInt256();
        uint256 _pendingEth = (accumulatedEth - ethDeposit.rewardDebt)
            .toUint256() / ethAmountPerSecondPrecision;

        // Effects
        ethDeposit.rewardDebt =
            accumulatedEth -
            (_amount * ethPoolInfo[_pid].accEthPerShare).toInt256();

        if (_pendingEth != 0) {
            (bool sent, ) = msg.sender.call{ value: _pendingEth }("");
            require(sent, "Error sending eth");
        }

        // Withdraw and claim PRIME
        PrimeRewards.withdrawAndClaimPrime(_pid, _amount);
        emit Claim(msg.sender, _pid, _pendingEth, ID_ETH);
    }

    /// @notice Withdraw and forgo rewards. EMERGENCY ONLY.
    /// @param _pid The index of the pool. See `poolInfo`.
    function emergencyWithdraw(uint256 _pid) public virtual override {
        EthDepositInfo storage ethDeposit = ethDepositInfo[_pid][msg.sender];

        // Effects
        ethDeposit.rewardDebt = 0;

        PrimeRewards.emergencyWithdraw(_pid);
    }

    /// @notice Sweep function to transfer ETH out of contract.
    /// @param to address to sweep to
    /// @param amount Amount to withdraw
    function sweepETH(address payable to, uint256 amount) public onlyOwner {
        (bool sent, ) = to.call{ value: amount }("");
        require(sent, "Failed to send Ether");
    }
}
