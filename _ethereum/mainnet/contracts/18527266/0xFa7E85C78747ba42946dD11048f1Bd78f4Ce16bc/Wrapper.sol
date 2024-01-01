// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma abicoder v2;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

import "./IAdapter.sol";

contract Wrapper is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IERC20;

    // The address of the wrapper factory
    address public immutable WRAPPER_FACTORY;

    // Whether it is initialized
    bool public isInitialized;

    // Accrued token per share
    uint256 public accTokenPerShare;

    // The timestamp when reward token mining starts
    uint256 public startTimestamp;

    // The timestamp when reward token mining ends
    uint256 public endTimestamp;

    // The timestamp of the last reward token update
    uint256 public lastRewardTimestamp;

    // reward tokens created per second
    uint256 public rewardPerSecond;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    // The staked token
    IERC20Metadata public stakedToken;

    // The reward token
    IERC20Metadata public rewardToken;

    // The adapter address
    address payable public adapterAddr;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 rewardDebt;
    }

    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event NewStartAndEndTimestamp(uint256 oldStartTimestamp, uint256 newStartTimestamp, uint256 oldEndTimestamp, uint256 newEndTimestamp, uint256 rewardPerSecond);
    event Restart(uint256 startTimestamp, uint256 endTimestamp, uint256 rewardPerSecond);
    event NewRewardPerSecond(uint256 oldRewardPerSecond, uint256 newRewardPerSecond, uint256 startTimestamp, uint256 endTimestamp);
    event NewPoolLimit(uint256 poolLimitPerUser);
    event RewardsStop(uint256 blockNumber);
    event TokenRecovery(address indexed token, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event DepositAndExpend(address indexed user, uint256 amount, uint256 endTimestamp);
    event MintThenDeposit(address indexed user, uint256 amount, uint256 amount0, uint256 amount1);
    event WithdrawThenBurn(address indexed user, uint256 amount, uint256 amount0, uint256 amount1);
    event AdapterUpdated(address indexed user, address indexed newAdapterAddr);

    /**
     * @notice Constructor
     */
    constructor() {
        WRAPPER_FACTORY = msg.sender;
    }

    /*
     * @notice Initialize the contract
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     * @param _rewardPerSecond: reward per second (in rewardToken)
     * @param _startTimestamp: start timestamp
     * @param _endTimestamp: end timestamp
     * @param _admin: admin address with ownership
     */
    function initialize(
        IERC20Metadata _stakedToken,
        IERC20Metadata _rewardToken,
        uint256 _rewardPerSecond,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        address _admin
    ) external {
        require(!isInitialized, "Already initialized");
        require(msg.sender == WRAPPER_FACTORY, "Not factory");
        require(_startTimestamp < _endTimestamp, "New startTimestamp must be lower than new endTimestamp");
        require(block.timestamp < _startTimestamp, "New startTimestamp must be higher than current timestamp");

        // Make this contract initialized
        isInitialized = true;

        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        rewardPerSecond = _rewardPerSecond;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;

        uint256 decimalsRewardToken = uint256(rewardToken.decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");

        PRECISION_FACTOR = uint256(10**(uint256(30) - decimalsRewardToken));
        require(PRECISION_FACTOR * rewardPerSecond / (10**decimalsRewardToken) >= 100_000_000, "rewardPerSecond must be larger");

        // Set the lastRewardBlock as the startTimestamp
        lastRewardTimestamp = startTimestamp;

        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(_admin);
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to deposit (in stakeToken)
     */
    function deposit(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        _updatePool();

        if (user.amount > 0) {
            uint256 pending = (user.amount * accTokenPerShare) / PRECISION_FACTOR - user.rewardDebt;
            if (pending > 0) {
                rewardToken.safeTransfer(msg.sender, pending);
            }
        }

        if (_amount > 0) {
            uint256 _amountBefore = IERC20Metadata(stakedToken).balanceOf(address(this));
            stakedToken.safeTransferFrom(msg.sender, address(this), _amount);
            uint256 _amountAfter = IERC20Metadata(stakedToken).balanceOf(address(this));
            _amount = _amountAfter - _amountBefore;
            user.amount = user.amount + _amount;
        }

        user.rewardDebt = (user.amount * accTokenPerShare) / PRECISION_FACTOR;

        emit Deposit(msg.sender, _amount);
    }

    /*
     * @notice Deposit reward tokens and expand end timestamp
     * @param _amount: amount to deposit (in stakeToken)
     */
    function depositRewardAndExpend(uint256 _amount) external nonReentrant {
        require(block.timestamp < endTimestamp, "Pool should not ended");

        uint256 _rewardAmountBefore = IERC20Metadata(rewardToken).balanceOf(address(this));
        IERC20Metadata(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _rewardAmountAfter = IERC20Metadata(rewardToken).balanceOf(address(this));
        uint256 _rewardAmount = _rewardAmountAfter - _rewardAmountBefore;

        uint256 newEndTimestamp = endTimestamp + _rewardAmount / rewardPerSecond;

        require(endTimestamp < newEndTimestamp, "New endTimestamp must be larger than old endTimestamp");

        endTimestamp = newEndTimestamp;

        emit DepositAndExpend(msg.sender, _rewardAmount, endTimestamp);
    }

    /*
     * @notice Mint then deposit staked tokens and collect reward tokens (if any)
     * @param _amount0: token0 amount to deposit (in token0)
     * @param _amount1: token0 amount to deposit (in token1)
     * @param _data: payload data from FE side
     */
    function mintThenDeposit(uint256 _amount0, uint _amount1, bytes calldata _data) external nonReentrant {
        require(adapterAddr != address(0), "Adapter address should not be empty");

        UserInfo storage user = userInfo[msg.sender];

        _updatePool();

        if (user.amount > 0) {
            uint256 pending = (user.amount * accTokenPerShare) / PRECISION_FACTOR - user.rewardDebt;
            if (pending > 0) {
                rewardToken.safeTransfer(msg.sender, pending);
            }
        }

        if (_amount0 > 0) {
            address token0 = IAdapter(adapterAddr).token0();
            IERC20(token0).safeTransferFrom(msg.sender, address(this), _amount0);
            IERC20(token0).forceApprove(adapterAddr, _amount0);
        }

        if (_amount1 > 0) {
            address token1 = IAdapter(adapterAddr).token1();
            IERC20(token1).safeTransferFrom(msg.sender, address(this), _amount1);
            IERC20(token1).forceApprove(adapterAddr, _amount1);
        }

        // call adapter
        uint256 _amountBefore = IERC20Metadata(stakedToken).balanceOf(address(this));
        IAdapter(adapterAddr).deposit(_amount0, _amount1, msg.sender, _data);
        uint256 _amountAfter = IERC20Metadata(stakedToken).balanceOf(address(this));
        uint256 _amount = _amountAfter - _amountBefore;

        if (_amount > 0) {
            user.amount = user.amount + _amount;
        }

        user.rewardDebt = (user.amount * accTokenPerShare) / PRECISION_FACTOR;

        emit MintThenDeposit(msg.sender, _amount, _amount0, _amount1);
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Amount to withdraw too high");

        _updatePool();

        uint256 pending = (user.amount * accTokenPerShare) / PRECISION_FACTOR - user.rewardDebt;

        if (_amount > 0) {
            user.amount = user.amount - _amount;
            stakedToken.safeTransfer(msg.sender, _amount);
        }

        if (pending > 0) {
            rewardToken.safeTransfer(msg.sender, pending);
        }

        user.rewardDebt = (user.amount * accTokenPerShare) / PRECISION_FACTOR;

        emit Withdraw(msg.sender, _amount);
    }

    /*
     * @notice Withdraw then burn staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     * @param _data: payload data from FE side
     */
    function withdrawThenBurn(uint256 _amount, bytes calldata _data) external nonReentrant {
        require(adapterAddr != address(0), "Adapter address should not be empty");

        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Amount to withdraw too high");

        _updatePool();

        uint256 pending = (user.amount * accTokenPerShare) / PRECISION_FACTOR - user.rewardDebt;

        uint256 _amount0;
        uint256 _amount1;

        if (_amount > 0) {
            user.amount = user.amount - _amount;

            IERC20(stakedToken).forceApprove(adapterAddr, _amount);

            // call adapter
            (_amount0, _amount1) = IAdapter(adapterAddr).withdraw(_amount, msg.sender, _data);
        }

        if (pending > 0) {
            rewardToken.safeTransfer(msg.sender, pending);
        }

        user.rewardDebt = (user.amount * accTokenPerShare) / PRECISION_FACTOR;

        emit WithdrawThenBurn(msg.sender, _amount, _amount0, _amount1);
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToTransfer = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        if (amountToTransfer > 0) {
            stakedToken.safeTransfer(msg.sender, amountToTransfer);
        }

        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        rewardToken.safeTransfer(msg.sender, _amount);
    }

    /**
    * @notice Allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @dev Callable by owner
     */
    function recoverToken(address _token) external onlyOwner {
        require(_token != address(stakedToken), "Operations: Cannot recover staked token");
        require(_token != address(rewardToken), "Operations: Cannot recover reward token");

        uint256 balance = IERC20Metadata(_token).balanceOf(address(this));
        require(balance != 0, "Operations: Cannot recover zero balance");

        IERC20Metadata(_token).safeTransfer(msg.sender, balance);

        emit TokenRecovery(_token, balance);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner
     */
    function stopReward() external onlyOwner {
        endTimestamp = block.timestamp;
        emit RewardsStop(endTimestamp);
    }

    /*
     * @notice Update reward per block, if campaign is ended, admin can call restart and update rewardPerSecond there
     * @dev Only callable by owner.
     * @param _rewardPerSecond: the reward per second
     */
    function updateRewardPerSecond(uint256 _rewardPerSecond) external onlyOwner {
        require(block.timestamp < endTimestamp, "Pool should not ended");
        uint256 decimalsRewardToken = uint256(rewardToken.decimals());
        require(PRECISION_FACTOR * _rewardPerSecond / (10**decimalsRewardToken) >= 100_000_000, "rewardPerSecond must be larger");

        _updatePool();

        emit NewRewardPerSecond(rewardPerSecond, _rewardPerSecond, startTimestamp, endTimestamp);

        rewardPerSecond = _rewardPerSecond;
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @dev This function is only callable by owner.
     * @param _startTimestamp: the new start timestamp
     * @param _endTimestamp: the new end timestamp
     */
    function updateStartAndEndTimestamp(uint256 _startTimestamp, uint256 _endTimestamp) external onlyOwner {
        require(block.timestamp < startTimestamp, "Pool has started");
        require(_startTimestamp < _endTimestamp, "New startTimestamp must be lower than new endTimestamp");
        require(block.timestamp < _startTimestamp, "New startTimestamp must be higher than current timestamp");

        emit NewStartAndEndTimestamp(startTimestamp, _startTimestamp, endTimestamp, _endTimestamp, rewardPerSecond);

        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;

        // Set the lastRewardTimestamp as the startTimestamp
        lastRewardTimestamp = startTimestamp;
    }

    /**
     * @notice It allows the admin to update adapter address
     * @dev This function is only callable by owner.
     * @param _adapterAddr: the address of new adapter
     */
    function updateAdapterAddress(address _adapterAddr) external onlyOwner {
        require(_adapterAddr != address(0), "Adapter address should not be empty");
        adapterAddr = payable(_adapterAddr);
        emit AdapterUpdated(msg.sender, _adapterAddr);
    }

    /**
     * @notice It allows the admin to restart
     * @dev This function is only callable by owner.
     * @param _startTimestamp: the new start timestamp
     * @param _endTimestamp: the new end timestamp
     * @param _rewardPerSecond: the new rewardPerSecond
     */
    function restart(uint256 _startTimestamp, uint256 _endTimestamp, uint256 _rewardPerSecond) external onlyOwner {
        require(block.timestamp > endTimestamp, "Pool should be ended");
        require(block.timestamp < _startTimestamp, "New startTimestamp must be higher than current timestamp");
        require(_startTimestamp < _endTimestamp, "New startTimestamp must be lower than new endTimestamp");

        uint256 decimalsRewardToken = uint256(rewardToken.decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");

        PRECISION_FACTOR = uint256(10**(uint256(30) - decimalsRewardToken));
        require(PRECISION_FACTOR * _rewardPerSecond / (10**decimalsRewardToken) >= 100_000_000, "rewardPerSecond must be larger");

        _updatePool();

        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        rewardPerSecond = _rewardPerSecond;

        // Set the lastRewardTimestamp as the startTimestamp
        lastRewardTimestamp = startTimestamp;

        emit Restart(_startTimestamp, _endTimestamp, _rewardPerSecond);
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));
        if (block.timestamp > lastRewardTimestamp && stakedTokenSupply != 0) {
            uint256 multiplier = _getMultiplier(lastRewardTimestamp, block.timestamp);
            uint256 cakeReward = multiplier * rewardPerSecond;
            uint256 adjustedTokenPerShare = accTokenPerShare + (cakeReward * PRECISION_FACTOR) / stakedTokenSupply;
            return (user.amount * adjustedTokenPerShare) / PRECISION_FACTOR - user.rewardDebt;
        } else {
            return (user.amount * accTokenPerShare) / PRECISION_FACTOR - user.rewardDebt;
        }
    }

    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if (block.timestamp <= lastRewardTimestamp) {
            return;
        }

        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));

        if (stakedTokenSupply == 0) {
            lastRewardTimestamp = block.timestamp;
            return;
        }

        uint256 multiplier = _getMultiplier(lastRewardTimestamp, block.timestamp);
        uint256 cakeReward = multiplier * rewardPerSecond;
        accTokenPerShare = accTokenPerShare + (cakeReward * PRECISION_FACTOR) / stakedTokenSupply;
        lastRewardTimestamp = block.timestamp;
    }

    /*
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     */
    function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to <= endTimestamp) {
            return _to - _from;
        } else if (_from >= endTimestamp) {
            return 0;
        } else {
            return endTimestamp - _from;
        }
    }
}