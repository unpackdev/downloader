// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IStaking.sol";
import "./IPresalePurchases.sol";

contract MetacadeStaking is IStaking {
    using SafeERC20 for IERC20;

    IERC20 public token;
    IPresalePurchases public presale;

    /// @notice Interest that should be accrued to the user as a reward
    /// @dev It is represented as a regular blockchain number with 2 decimal places (10000 is 100.00%)
    uint256 public immutable interestRate;

    uint256 public immutable stakingStart;
    uint256 public immutable stakingEnd;
    uint256 public immutable withdrawalStart;
    uint256 public immutable stakingPoolLimit;

    uint256 public stakingPool;
    mapping(address => uint256) public userDeposits;
    mapping(address => bool) public hasWithdrawn;

    constructor(
        address _token,
        address _presale,
        uint256 _stakingStart,
        uint256 _stakingPeriod,
        uint256 _lockPeriod,
        uint256 _stakingPoolLimit,
        uint256 _interestRange
    ) {
        token = IERC20(_token);
        presale = IPresalePurchases(_presale);
        stakingStart = _stakingStart;
        stakingEnd = _stakingStart + _stakingPeriod;
        withdrawalStart = _stakingStart + _stakingPeriod + _lockPeriod;
        interestRate = _interestRange;
        stakingPoolLimit = _stakingPoolLimit;
    }

    /// @dev Deposit tokens to be locked until the end of the locking period
    /// @param _amount The amount of tokens to deposit
    function stake(uint256 _amount) public {
        if (block.timestamp < stakingStart || block.timestamp >= stakingEnd) revert InvalidTimePeriod();
        if (!presale.hasClaimed(msg.sender) && presale.userDeposits(msg.sender) == 0) revert NotPresaleParticipant();
        if (stakingPool + _amount > stakingPoolLimit) revert ExceedsStakingLimit(stakingPoolLimit - stakingPool);

        userDeposits[msg.sender] += _amount;
        stakingPool += _amount;

        token.safeTransferFrom(msg.sender, address(this), _amount);

        emit Staked(msg.sender, _amount, block.timestamp);
    }

    /// @dev Withdraw tokens after the end of the locking period or during the deposit period
    function withdraw() public {
        if (block.timestamp < withdrawalStart) revert InvalidTimePeriod();
        if (hasWithdrawn[msg.sender]) revert AlreadyWithdrawn();
        if (userDeposits[msg.sender] == 0) revert NoStake();

        uint256 tokensToTransfer = userDeposits[msg.sender] + (userDeposits[msg.sender] * interestRate / 10000);

        hasWithdrawn[msg.sender] = true;

        token.safeTransfer(msg.sender, tokensToTransfer);

        emit Withdrawn(msg.sender, tokensToTransfer, block.timestamp);
    }
}
