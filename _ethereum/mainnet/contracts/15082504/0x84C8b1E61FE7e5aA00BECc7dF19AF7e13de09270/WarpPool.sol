// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./IBentPool.sol";
import "./IBentCVX.sol";
import "./IBentLocker.sol";
import "./IBentCVXStaking.sol";
import "./IBentCVXConverter.sol";

contract WarpPool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event Deposit(address user, uint256 amount, address onBehalf);
    event Withdraw(address user, uint256 amount, address recipient);
    event Claim(address user, uint256 amount, address recipient);

    string public name;
    address public immutable lpToken;
    address public immutable bentPool;
    address public immutable bent;
    address public immutable bentLocker;
    address public immutable bentCVX;
    address public immutable bentCVXStaking;
    address public immutable bentCVXConverter;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    uint256 public rewardTokenCount;
    mapping(uint256 => address) public rewardTokens;
    mapping(address => bool) public isRewardToken;

    uint256 internal accRewardPerShare;
    mapping(address => uint256) internal userRewardDebt;
    mapping(address => uint256) internal userPendingRewards;

    mapping(uint256 => uint256) public bentCVXPerDay; // (timestamp / day) => new bentCVX, for APY calculation
    mapping(uint256 => uint256) public bentPerDay; // (timestamp / day) => new bent, for tracking (not used for APY calculation, it's permanent lock)

    constructor(
        address _bentPool,
        address _bent,
        address _bentLocker,
        address _bentCVX,
        address _bentCVXStaking,
        address _bentCVXConverter,
        string memory _name
    ) Ownable() ReentrancyGuard() {
        name = _name;
        bentPool = _bentPool;
        bent = _bent;
        bentLocker = _bentLocker;
        bentCVX = _bentCVX;
        bentCVXStaking = _bentCVXStaking;
        bentCVXConverter = _bentCVXConverter;
        lpToken = IBentPool(_bentPool).lpToken();
    }

    function addRewardTokens(address[] memory _rewardTokens) public onlyOwner {
        uint256 length = _rewardTokens.length;
        for (uint256 i = 0; i < length; ++i) {
            require(!isRewardToken[_rewardTokens[i]], "already exists");
            rewardTokens[rewardTokenCount + i] = _rewardTokens[i];
            isRewardToken[_rewardTokens[i]] = true;
        }
        rewardTokenCount += length;
    }

    function removeRewardToken(uint256 _index) external onlyOwner {
        require(_index < rewardTokenCount, "invalid index");

        isRewardToken[rewardTokens[_index]] = false;
        delete rewardTokens[_index];
    }

    function totalBentCVX() public view returns (uint256) {
        return IBentCVXStaking(bentCVXStaking).balanceOf(address(this));
    }

    function deposit(uint256 _amount, address _onBehalf) external {
        IERC20(lpToken).safeTransferFrom(msg.sender, address(this), _amount);

        _withdrawReward(_onBehalf);
        _mint(_onBehalf, _amount);
        _updateUserRewardDebt(_onBehalf);

        // deposit into bent pool
        IERC20(lpToken).safeApprove(bentPool, _amount);
        IBentPool(bentPool).deposit(_amount);

        emit Deposit(msg.sender, _amount, _onBehalf);
    }

    function withdraw(uint256 _amount, address _recipient) external {
        require(balanceOf[msg.sender] >= _amount, "invalid amount");

        _withdrawReward(msg.sender);
        _burn(msg.sender, _amount);
        _updateUserRewardDebt(msg.sender);

        // withdraw from Bent pool
        IBentPool(bentPool).withdraw(_amount);
        IERC20(lpToken).safeTransfer(_recipient, _amount);

        emit Withdraw(msg.sender, _amount, _recipient);
    }

    function claim(address _recipient) external {
        _withdrawReward(msg.sender);

        uint256 claimAmount = userPendingRewards[msg.sender];
        if (claimAmount > 0) {
            // unstake BentCVX
            IBentCVXStaking(bentCVXStaking).withdraw(claimAmount);
            // transfer BentCVX
            IERC20(bentCVX).safeTransfer(_recipient, claimAmount);
            userPendingRewards[msg.sender] = 0;
        }

        _updateUserRewardDebt(msg.sender);

        emit Claim(msg.sender, claimAmount, _recipient);
    }

    function compound() external {
        // harvest all rewards
        harvestAllRewards();

        // swap rewards(except Bent) to BentCVX
        swapRewardToBentCVX();

        // stake rewards into BentCVXStaking & weBENT
        stakeRewards();
    }

    function harvestAllRewards() public {
        // claim Bent pool
        // try IBentPool(bentPool).harvest() {} catch {}
        IBentPool(bentPool).harvest();

        // claim BentCVX staking
        try IBentCVXStaking(bentCVXStaking).claimAll() {} catch {}

        // claim weBENT
        try IBentLocker(bentLocker).claimAll() {} catch {}
    }

    function swapRewardToBentCVX() public {
        for (uint256 i = 0; i < rewardTokenCount; i++) {
            if (rewardTokens[i] != address(0)) {
                uint256 amount = IERC20(rewardTokens[i]).balanceOf(
                    address(this)
                );

                if (amount > 0) {
                    IERC20(rewardTokens[i]).safeApprove(
                        bentCVXConverter,
                        amount
                    );
                    IBentCVXConverter(bentCVXConverter).convertToBentCVX(
                        rewardTokens[i],
                        amount,
                        0
                    );
                }
            }
        }
    }

    function stakeRewards() public {
        // stake BentCVX
        uint256 bentCVXBalance = IERC20(bentCVX).balanceOf(address(this));
        if (bentCVXBalance > 0) {
            IERC20(bentCVX).safeApprove(bentCVXStaking, bentCVXBalance);
            IBentCVXStaking(bentCVXStaking).deposit(bentCVXBalance);

            _updateAccPerShare(bentCVXBalance);

            bentCVXPerDay[block.timestamp / 1 days] += bentCVXBalance;
        }

        // lock Bent
        uint256 bentBalance = IERC20(bent).balanceOf(address(this));
        if (bentBalance > 0) {
            IERC20(bent).safeApprove(bentLocker, bentBalance);
            IBentLocker(bentLocker).deposit(bentBalance);

            bentPerDay[block.timestamp / 1 days] += bentBalance;
        }
    }

    function pendingReward(address _user) external view returns (uint256) {
        uint256 pending = ((balanceOf[_user] * accRewardPerShare) / 1e36) -
            userRewardDebt[_user];
        return userPendingRewards[_user] + pending;
    }

    function _updateAccPerShare(uint256 newRewards) internal {
        if (totalSupply == 0) {
            accRewardPerShare = block.number;
        } else {
            accRewardPerShare += (newRewards * (1e36)) / totalSupply;
        }
    }

    function _withdrawReward(address _user) internal {
        uint256 pending = ((balanceOf[_user] * accRewardPerShare) / 1e36) -
            userRewardDebt[_user];

        if (pending > 0) {
            userPendingRewards[_user] += pending;
        }
    }

    function _updateUserRewardDebt(address _user) internal {
        userRewardDebt[_user] = (balanceOf[_user] * accRewardPerShare) / 1e36;
    }

    function _mint(address _user, uint256 _amount) internal {
        balanceOf[_user] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _user, uint256 _amount) internal {
        balanceOf[_user] -= _amount;
        totalSupply -= _amount;
    }
}
