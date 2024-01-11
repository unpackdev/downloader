// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./SafeERC20.sol";
import "./ERC1155Receiver.sol";
import "./IERC1155.sol";
import "./IRewardVesting.sol";

struct Stake {
    uint256 depositAmount; //Deposited Amount
    uint256 depositTime; //The time when the stake was created
}

contract LVMHStaking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event ChangedRewardRate(
        uint256 indexed oldRewardRate,
        uint256 indexed newRate
    );

    IERC20 rewardToken;
    IERC20 stakingToken;
    IRewardVesting vestingContract;

    mapping(address => Stake) public deposits;

    uint256 public rate;

    uint256 public percentageWithHeros = 50;

    // expiration time of reward providing
    uint256 public expiration;

    constructor(IERC20 lvmh) {
        stakingToken = lvmh;
        rewardToken = lvmh;
    }

    function changeRewardRate(uint256 newRate) public onlyOwner {
        uint256 oldRate = rate;
        rate = newRate;
        emit ChangedRewardRate(oldRate, newRate);
    }

    function changeVestinContract(IRewardVesting _vestingContract)
        public
        onlyOwner
    {
        vestingContract = _vestingContract;
    }

    function changeHeroClaimPercentage(uint256 newPercentage) public onlyOwner {
        percentageWithHeros = newPercentage;
    }

    function changeExpiration(uint256 _expiration) public onlyOwner {
        expiration = _expiration;
    }

    function deposit(uint256 _amount) external {
        require(expiration > block.timestamp, "Invalid time stamp");
        uint256 stakedAmount = deposits[msg.sender].depositAmount;
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        if (stakedAmount == 0) {
            deposits[msg.sender] = Stake(_amount, block.timestamp);
        } else {
            claimTokens();
            deposits[msg.sender].depositAmount += _amount;
        }
    }

    function calculateReward(address account) public view returns (uint256) {
        Stake memory reward = deposits[account];
        uint256 depositTime = reward.depositTime;
        uint256 depositAmount = reward.depositAmount;
        if (depositAmount == 0) return 0;
        if (block.timestamp > expiration) {
            return
                expiration.sub(depositTime).mul(rate).mul(depositAmount).div(
                    10**18
                );
        } else {
            return
                block
                    .timestamp
                    .sub(depositTime)
                    .mul(rate)
                    .mul(depositAmount)
                    .div(10**18);
        }
    }

    function claimTokens() public {
        uint256 reward = calculateReward(msg.sender);
        uint256 claimAbleWithoutHeros = reward
            .mul(100 - percentageWithHeros)
            .div(100);
        uint256 claimAbleWithHeros = reward - claimAbleWithoutHeros;
        vestingContract.addReward(msg.sender, claimAbleWithHeros);
        if (block.timestamp < expiration)
            deposits[msg.sender].depositTime = block.timestamp;
        rewardToken.safeTransfer(msg.sender, claimAbleWithoutHeros);
        rewardToken.safeTransfer(address(vestingContract), claimAbleWithHeros);
    }

    function withDrawTokens(uint256 _amount) public {
        uint256 stakedAmount = deposits[msg.sender].depositAmount;
        require(
            _amount <= stakedAmount,
            "Cannot WithDraw Token More Than Staked"
        );
        stakingToken.safeTransfer(msg.sender, _amount);
        claimTokens();
        if (stakedAmount == _amount) delete deposits[msg.sender];
        else deposits[msg.sender].depositAmount -= _amount;
    }
}
