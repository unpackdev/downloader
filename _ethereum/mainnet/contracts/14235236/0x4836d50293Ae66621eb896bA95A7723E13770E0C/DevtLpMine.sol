// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeCast.sol";

contract DevtLpMine is Ownable {
    using SafeERC20 for ERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    uint256 public constant LIFECYCLE = 90 days;

    // DevtLp token addr
    ERC20 public immutable devt;
    ERC20 public immutable dvt;

    uint256 public endTimestamp;
    uint256 public dvtPerSecond;
    uint256 public totalRewardsEarned;

    //Cumulative revenue per lp token
    uint256 public accDvtPerShare;
    uint256 public devtTotalDeposits;
    uint256 public lastRewardTimestamp;

    struct UserInfo {
        uint256 depositAmount;
        int256 rewardDebt;
        bool isDeposit;
    }

    /// @notice user => UserInfo
    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 amount);
    event LogUpdateRewards(
        uint256 indexed lastRewardTimestamp,
        uint256 lpSupply,
        uint256 accDvtPerShare
    );

   

    /// @notice update totalRewardsEarned, update cumulative profit per lp token
    function updateRewards() private {
        if (
            block.timestamp > lastRewardTimestamp &&
            lastRewardTimestamp < endTimestamp &&
            endTimestamp != 0
        ) {
            uint256 lpSupply = devtTotalDeposits;
            if (lpSupply > 0) {
                uint256 timeDelta;
                if (block.timestamp > endTimestamp) {
                    timeDelta = endTimestamp - lastRewardTimestamp;
                    lastRewardTimestamp = endTimestamp;
                } else {
                    timeDelta = block.timestamp - lastRewardTimestamp;
                    lastRewardTimestamp = block.timestamp;
                }
                uint256 dvtReward = timeDelta * dvtPerSecond;
                totalRewardsEarned += dvtReward;
                accDvtPerShare += (dvtReward * 1 ether) / lpSupply;
            }
            emit LogUpdateRewards(
                lastRewardTimestamp,
                lpSupply,
                accDvtPerShare
            );
        }
    }

    constructor(
        address _devt,
        address _dvt,
        address _owner
    ) {
        require(_devt != address(0) && _dvt != address(0) && _owner != address(0), "set address is zero");
        devt = ERC20(_devt);
        dvt = ERC20(_dvt);
        transferOwnership(_owner);
    }

    /// @notice Initialize variables
    function init() external onlyOwner {
        require(endTimestamp == 0, "Cannot init again");
        uint256 rewardsAmount; 
        rewardsAmount = dvt.balanceOf(address(this));
        require(rewardsAmount > 0, "No rewards sent");

        dvtPerSecond = rewardsAmount / LIFECYCLE;
        endTimestamp = block.timestamp + LIFECYCLE;
        lastRewardTimestamp = block.timestamp;

    }

    /// @notice Get the user's cumulative revenue as of the current time
    function pendingRewards(address _user)
        external
        view
        returns (uint256 pending)
    {
        UserInfo storage user = userInfo[_user];
        uint256 _accDvtPerShare = accDvtPerShare;
        uint256 lpSupply = devtTotalDeposits;
        if (block.timestamp > lastRewardTimestamp && dvtPerSecond != 0) {
            uint256 timeDelta;
            if (block.timestamp > endTimestamp) {
                timeDelta = endTimestamp - lastRewardTimestamp;
            } else {
                timeDelta = block.timestamp - lastRewardTimestamp;
            }
            uint256 dvtReward = timeDelta * dvtPerSecond;
            _accDvtPerShare += (dvtReward * 1 ether) / lpSupply;
        }

        pending = (((user.depositAmount * _accDvtPerShare) / 1 ether).toInt256() -
            user.rewardDebt).toUint256();
    }
    /// @notice Pledge devt
    function deposit(uint256 _amount) external {
        updateRewards();
        require(endTimestamp != 0, "Not initialized");
        require(block.timestamp < endTimestamp, "Will not deposit after end");
        devtTotalDeposits += _amount;

        if(userInfo[msg.sender].isDeposit){
            userInfo[msg.sender].depositAmount +=_amount;
            userInfo[msg.sender].rewardDebt += ((_amount * accDvtPerShare) / 1 ether).toInt256();
        } else {
            userInfo[msg.sender] = UserInfo(
            _amount,
            ((_amount * accDvtPerShare) / 1 ether).toInt256(),
            true
        );
        }
        

        devt.safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, _amount);
    }

    /// @notice Withdraw the principal and income
    function withdraw() external {
        updateRewards();
        UserInfo storage user = userInfo[msg.sender];

        require(user.depositAmount > 0, "Position does not exists");    

        devtTotalDeposits -= user.depositAmount;

        int256 accumulatedDvt = ((user.depositAmount * accDvtPerShare) / 1 ether)
            .toInt256();
        uint256 _pendingDvt = (accumulatedDvt - user.rewardDebt).toUint256();

        devt.safeTransfer(msg.sender, user.depositAmount);

        // Withdrawal income
        if (_pendingDvt != 0) {
            dvt.safeTransfer(msg.sender, _pendingDvt);
        }
        emit Harvest(msg.sender, _pendingDvt);
        emit Withdraw(msg.sender, user.depositAmount);
         delete userInfo[msg.sender];
       
    }
}
