// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "./ReentrancyGuard.sol";
import "./PrimeRewards.sol";
import "./Math.sol";

/// @title The TimedCacheEthAndPrimeRewards staking contract
/// @notice Staking contract for Masterpieces. It allows for a fixed PRIME token
/// rewards distributed evenly across all staked tokens per second.
contract TimedCacheEthAndPrimeRewards is PrimeRewards, ReentrancyGuard {
    /// @notice Vesting Info per user per pool/Masterpiece
    struct VestingInfo {
        uint256 lastDepositTimestamp;
    }

    /// @notice Eth Info of each pool.
    /// Contains the total amount of Eth rewarded and total amount of Eth claimed.
    struct EthPoolInfo {
        uint256 ethReward;
        uint256 ethClaimed;
    }

    /// @notice Pool id to Masterpiece
    mapping(uint256 => EthPoolInfo) public ethPoolInfo;
    /// @notice Vesting info for each user that stakes a Masterpiece
    /// poolID(per masterpiece) => user address => vesting info
    mapping(uint256 => mapping(address => VestingInfo)) public vestingInfo;

    /// @notice Minimum number of vesting seconds per ETH
    uint256 public ethVestingPeriod;

    event EthRewardsAdded(uint256[] _tokenIds, uint256[] _ethRewards);
    event EthRewardsSet(uint256[] _tokenIds, uint256[] _ethRewards);
    event VestingPeriodUpdated(
        uint256 vestingPeriod,
        uint256 indexed currencyId
    );

    /// @param _prime The PRIME token contract address.
    /// @param _parallelAlpha The Parallel Alpha contract address.
    constructor(IERC20 _prime, IERC1155 _parallelAlpha)
        PrimeRewards(_prime, _parallelAlpha)
    {}

    /// @notice Set the vestingPeriod
    /// @param _ethVestingPeriod Minimum number of vesting seconds per ETH
    function setEthVestingPeriod(uint256 _ethVestingPeriod) external onlyOwner {
        ethVestingPeriod = _ethVestingPeriod;
        emit VestingPeriodUpdated(_ethVestingPeriod, ID_ETH);
    }

    /// @notice Add ETH rewards for the specified Masterpiece pools
    /// @param _pids List of specified pools/Masterpieces
    /// @param _ethRewards List of ETH values for corresponding _pids
    function addEthRewards(uint256[] memory _pids, uint256[] memory _ethRewards)
        external
        payable
        onlyOwner
    {
        require(
            _pids.length == _ethRewards.length,
            "token ids and eth rewards lengths aren't the same"
        );
        uint256 totalEthRewards = 0;
        for (uint256 i = 0; i < _pids.length; i++) {
            uint256 pid = _pids[i];
            uint256 ethReward = _ethRewards[i];
            ethPoolInfo[pid].ethReward += ethReward;
            totalEthRewards += ethReward;
        }
        require(msg.value >= totalEthRewards, "Not enough eth sent");
        emit EthRewardsAdded(_pids, _ethRewards);
    }

    /// @notice Set ETH rewards for the specified Masterpiece pools
    /// @param _pids List of specified pools/Masterpieces
    /// @param _ethRewards List of ETH values for corresponding _pids
    function setEthRewards(uint256[] memory _pids, uint256[] memory _ethRewards)
        public
        payable
        onlyOwner
    {
        require(
            _pids.length == _ethRewards.length,
            "token ids and eth rewards lengths aren't the same"
        );
        uint256 currentTotalEth = 0;
        uint256 newTotalEth = 0;
        for (uint256 i = 0; i < _pids.length; i++) {
            uint256 pid = _pids[i];
            uint256 ethReward = _ethRewards[i];
            EthPoolInfo storage _ethPoolInfo = ethPoolInfo[pid];
            // new eth reward - old eth reward
            currentTotalEth += _ethPoolInfo.ethReward;
            newTotalEth += ethReward;
            _ethPoolInfo.ethReward = ethReward;
        }
        if (newTotalEth > currentTotalEth) {
            require(
                msg.value >= (newTotalEth - currentTotalEth),
                "Not enough eth sent"
            );
        }
        emit EthRewardsSet(_pids, _ethRewards);
    }

    /// @notice View function to see pending ETH on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending ETH reward for a given user.
    function pendingEth(uint256 _pid, address _user)
        external
        view
        returns (uint256 pending)
    {
        DepositInfo storage _deposit = depositInfo[_pid][_user];
        EthPoolInfo storage _ethPoolInfo = ethPoolInfo[_pid];
        VestingInfo storage _vesting = vestingInfo[_pid][_user];

        if (_ethPoolInfo.ethClaimed < _ethPoolInfo.ethReward) {
            uint256 remainingRewards = _ethPoolInfo.ethReward -
                _ethPoolInfo.ethClaimed;

            uint256 vestedAmount = _deposit.amount *
                (((block.timestamp - _vesting.lastDepositTimestamp) * 1 ether) /
                    ethVestingPeriod);

            pending = Math.min(vestedAmount, remainingRewards);
        }
    }

    /// @notice Deposit nfts for PRIME allocation.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _amount Amount of prime sets to deposit for _pid.
    function deposit(uint256 _pid, uint256 _amount) public override {
        VestingInfo storage _vesting = vestingInfo[_pid][msg.sender];

        _vesting.lastDepositTimestamp = block.timestamp;

        PrimeRewards.deposit(_pid, _amount);
    }

    /// @notice Claim eth for transaction sender.
    /// @param _pid Token id to claim.
    function claimEth(uint256 _pid) public nonReentrant {
        DepositInfo memory _deposit = depositInfo[_pid][msg.sender];
        EthPoolInfo storage _ethPoolInfo = ethPoolInfo[_pid];
        VestingInfo storage _vesting = vestingInfo[_pid][msg.sender];
        require(
            _ethPoolInfo.ethClaimed < _ethPoolInfo.ethReward,
            "Already claimed all eth"
        );

        uint256 remainingRewards = _ethPoolInfo.ethReward -
            _ethPoolInfo.ethClaimed;

        uint256 vestedAmount = _deposit.amount *
            (((block.timestamp - _vesting.lastDepositTimestamp) * 1 ether) /
                ethVestingPeriod);

        uint256 pendingEthReward = Math.min(vestedAmount, remainingRewards);
        _ethPoolInfo.ethClaimed += pendingEthReward;
        _vesting.lastDepositTimestamp = block.timestamp;

        if (pendingEthReward > 0) {
            (bool sent, ) = msg.sender.call{ value: pendingEthReward }("");
            require(sent, "Failed to send Ether");
        }
        emit Claim(msg.sender, _pid, pendingEthReward, ID_ETH);
    }

    /// @notice Claim eth and PRIME for transaction sender.
    /// @param _pid Pool id to claim.
    function claimPrimeAndEth(uint256 _pid) public {
        claimPrime(_pid);
        claimEth(_pid);
    }

    /// @notice Claim multiple pools
    /// @param _pids Pool IDs of all to be claimed
    function claimPoolsPrimeAndEth(uint256[] calldata _pids) external {
        for (uint256 i = 0; i < _pids.length; ++i) {
            claimPrimeAndEth(_pids[i]);
        }
    }

    /// @notice Withdraw Masterpiece and claim eth for transaction sender.
    /// @param _pid Token id to withdraw.
    /// @param _amount Amount to withdraw.
    function withdrawAndClaimEth(uint256 _pid, uint256 _amount) external {
        claimEth(_pid);
        withdraw(_pid, _amount);
    }

    /// @notice Withdraw Masterpiece and claim eth and prime for transaction sender.
    /// @param _pid Token id to withdraw.
    /// @param _amount Amount to withdraw.
    function withdrawAndClaimPrimeAndEth(uint256 _pid, uint256 _amount)
        external
    {
        claimEth(_pid);
        withdrawAndClaimPrime(_pid, _amount);
    }

    /// @notice Sweep function to transfer ETH out of contract.
    /// @param to address to sweep to
    /// @param amount Amount to withdraw
    function sweepETH(address payable to, uint256 amount) external onlyOwner {
        (bool sent, ) = to.call{ value: amount }("");
        require(sent, "Failed to send Ether");
    }
}
