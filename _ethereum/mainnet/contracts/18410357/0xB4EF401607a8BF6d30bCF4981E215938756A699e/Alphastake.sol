// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface TokenI {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address to) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external returns (uint256);

    function decimals() external view returns (uint8);
}

//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev To Main Stake contract  .
 */
contract Alphastake is Ownable {
    struct _staking {
        uint256 _id;
        uint256 _startTime;
        uint256 _claimTime;
        uint256 _amount;
        uint256 _APY;
    }
    struct _stakingWithReward {
        _staking _stakingData;
        uint256 _currentRewards;
    }
    address public rewardPoolAddress;
    address public tokenAddress = address(0);
    mapping(address => mapping(uint256 => _staking)) private staking;
    mapping(address => uint256) private activeStake;
    uint256 private APY = 100;
    uint256 private rewardPoolBal = 150000000000 * 10 ** 18;

    constructor(address _tokenContract) {
        tokenAddress = _tokenContract;
        rewardPoolAddress = address(this);
    }

    /**
     * @dev To show contract event  .
     */
    event StakeEvent(uint256 _stakeid, address _to, uint _stakeamount);
    event Unstake(uint256 _stakeid, address _to, uint _amount);
    event Claim(uint256 _stakeid, address _to, uint _claimamount);

    /**
     * @dev updates pool and apy.
     */
    function _updatePool(uint256 amount, bool isPositive) internal {
        uint256 maxAPY = 100;
        uint256 minAPY = 8;
        uint256 initialSupply = 150000000000 * 10 ** 18;
        uint256 breakpoint = initialSupply / 10;
        if (isPositive) {
            rewardPoolBal += amount;
        } else {
            rewardPoolBal -= amount;
        }
        if (rewardPoolBal >= initialSupply) {
            APY = maxAPY;
        }
        if (rewardPoolBal >= breakpoint) {
            APY =
                minAPY +
                ((((rewardPoolBal - breakpoint) * 10 ** 18) /
                    (initialSupply - breakpoint)) * (maxAPY - minAPY)) /
                10 ** 18;
        } else {
            APY = minAPY;
        }
    }

    /**
     * @dev returns APY for new users.
     */
    function currentAPY() public view returns (uint) {
        return APY;
    }

    /**
     * @dev returns stake instance data
     */
    function getStakingsWithRewards(
        address user
    ) public view returns (_stakingWithReward[] memory) {
        uint256 userActiveStake = activeStake[user];
        require(userActiveStake > 0, "No active stake instances found");
        _stakingWithReward[]
            memory stakingsWithRewards = new _stakingWithReward[](
                userActiveStake
            );
        for (uint256 i = 0; i < userActiveStake; i++) {
            stakingsWithRewards[i] = _stakingWithReward({
                _stakingData: staking[user][i],
                _currentRewards: currentRewards(user, i)
            });
        }
        return stakingsWithRewards;
    }

    /**
     * @dev return current pool balance.
     *
     */
    function viewRewardPoolBalance() public view returns (uint256) {
        return rewardPoolBal;
    }

    /**
     * @dev returns the number of stake instances tied to a wallet.
     */
    function numberOfStakeInstances(
        address user
    ) public view returns (uint256) {
        uint256 userActiveStake = activeStake[user];
        return userActiveStake;
    }

    /**
     * @dev returns current rewards for given stake instance
     */
    function currentRewards(
        address user,
        uint256 _stakeid
    ) public view returns (uint256) {
        require(_stakeid >= 0, "Please set valid stakeid!");
        require(_stakeid < activeStake[user], "Stake instance does not exist");
        uint32 oneMonth = 30 * 24 * 60 * 60;
        uint256 currentTime = block.timestamp;
        uint256 rewards = 0;
        uint256 locktime = staking[user][_stakeid]._startTime + oneMonth;
        uint256 oneYearDivisorAPY = 100 * 365 * 24 * 60 * 60;
        uint256 userStartTime = staking[user][_stakeid]._startTime;
        uint256 userClaimTime = staking[user][_stakeid]._claimTime;
        uint256 userAmount = staking[user][_stakeid]._amount;
        uint256 userAPY = staking[user][_stakeid]._APY;
        uint256 gamma = 0;
        if (currentTime >= locktime) {
            uint256 timeDifference = 0;
            uint256 alpha = 0;
            uint256 beta = 0;
            if (userClaimTime <= userStartTime) {
                timeDifference = 0;
            } else {
                timeDifference = userClaimTime - userStartTime;
            }
            if (timeDifference <= oneMonth) {
                alpha = timeDifference;
            } else {
                alpha = oneMonth;
                beta = timeDifference - oneMonth;
            }
            if (currentTime <= locktime + beta) {
                gamma = 0;
            } else {
                gamma = currentTime - (locktime + beta);
            }
            rewards =
                (userAmount *
                    userAPY *
                    ((oneMonth - alpha) + (gamma * 3) / 2)) /
                oneYearDivisorAPY;
        } else {
            if (currentTime <= userClaimTime) {
                gamma = 0;
            } else {
                gamma = currentTime - userClaimTime;
            }
            rewards = (userAmount * userAPY * gamma) / oneYearDivisorAPY;
        }
        return rewards;
    }

    /**
     * @dev stake amount for particular duration.
     * parameters : _stakeamount ( need to set token amount for stake)
     * it will increase activeStake result of particular wallet.
     * NOTE: _stakeamount must be inserted without decimals
     */
    function stake(uint256 _stakeamount) public returns (bool) {
        address user = msg.sender;
        _stakeamount = _stakeamount * 10 ** 18;
        require(
            TokenI(tokenAddress).balanceOf(user) >= _stakeamount,
            "Insufficient tokens"
        );
        require(_stakeamount > 0, "Amount should be greater than 0");
        require(
            TokenI(tokenAddress).allowance(user, rewardPoolAddress) >=
                _stakeamount,
            "Insufficient allowance."
        );
        require(
            TokenI(tokenAddress).transferFrom(
                user,
                rewardPoolAddress,
                _stakeamount
            ),
            "Token tranfer failed"
        );
        staking[user][activeStake[user]] = _staking(
            activeStake[user],
            block.timestamp,
            block.timestamp,
            _stakeamount,
            APY
        );
        activeStake[user] = activeStake[user] + 1;
        emit StakeEvent(activeStake[user], address(this), _stakeamount);
        return true;
    }

    /**
     * @dev stake amount release.
     * parameters : _stakeid is active stake ids which is getting from activeStake-1
     *
     * it will decrease activeStake result of particular wallet.
     * result : If unstake happen before time duration it will set 50% penalty on profited amount else it will sent you all stake amount,
     *          to the staking wallet.
     */
    function unstake(uint256 _stakeid) public returns (bool) {
        address user = msg.sender;
        require(_stakeid >= 0, "Please set valid stakeid!");
        require(_stakeid < activeStake[user], "Stake instance does not exist");
        uint256 userAmount = staking[user][_stakeid]._amount;
        uint256 withdrawAmount = viewWithdrawAmount(user, _stakeid);
        uint256 userActiveStake = activeStake[user];
        uint256 lastStake = userActiveStake - 1;
        require(
            TokenI(tokenAddress).transfer(user, withdrawAmount),
            "Token transfer failed"
        );
        if (withdrawAmount >= userAmount) {
            _updatePool(withdrawAmount - userAmount, true);
        } else {
            _updatePool(userAmount - withdrawAmount, false);
        }
        activeStake[user] = lastStake;

        staking[user][_stakeid]._id = staking[user][lastStake]._id;
        staking[user][_stakeid]._amount = staking[user][lastStake]._amount;
        staking[user][_stakeid]._startTime = staking[user][lastStake]
            ._startTime;
        staking[user][_stakeid]._claimTime = staking[user][lastStake]
            ._claimTime;
        staking[user][_stakeid]._APY = staking[user][lastStake]._APY;

        staking[user][lastStake]._id = 0;
        staking[user][lastStake]._amount = 0;
        staking[user][lastStake]._startTime = 0;
        staking[user][lastStake]._claimTime = 0;
        staking[user][lastStake]._APY = 0;
        emit Unstake(_stakeid, user, withdrawAmount);
        return true;
    }

    /**
     * @dev claims accrued rewards
     */

    function claim(uint256 _stakeid) public returns (bool) {
        address user = msg.sender;
        uint256 userActiveStake = activeStake[user];
        require(_stakeid >= 0, "Please set valid stakeid!");
        require(_stakeid < userActiveStake, "Stake instance does not exist");
        uint256 claimAmount = currentRewards(user, _stakeid);
        require(claimAmount > 0, "Cannot claim non zero amount");
        require(
            TokenI(tokenAddress).transfer(user, claimAmount),
            "Token transfer failed"
        );
        _updatePool(claimAmount, false);
        staking[user][_stakeid]._claimTime = block.timestamp;
        emit Claim(_stakeid, user, claimAmount);
        return true;
    }

    /**
     * @dev To know total withdrawal stake amount
     * parameters : _stakeid is active stake ids which is getting from activeStake-
     */
    function viewWithdrawAmount(
        address user,
        uint256 _stakeid
    ) public view returns (uint256) {
        uint256 userActiveStake = activeStake[user];
        require(_stakeid >= 0, "Please set valid stakeid!");
        require(_stakeid < userActiveStake, "Stake instance does not exist");
        uint32 oneWeek = 7 * 24 * 60 * 60;
        bool isPositive = true;
        uint256 currentTime = block.timestamp;
        uint256 startTime = staking[user][_stakeid]._startTime;
        uint256 locktime = startTime + 30 * 24 * 60 * 60;
        uint256 penalty = (staking[user][_stakeid]._amount * 5) / 100;
        uint256 userAmount = staking[user][_stakeid]._amount;
        uint256 userRewards = currentRewards(user, _stakeid);
        uint256 withdrawAmount = userAmount;
        uint256 poolModifier = 0;

        if (currentTime < startTime + oneWeek) {
            poolModifier += penalty;
            isPositive = false;
        } else if (currentTime < startTime + oneWeek * 2) {
            poolModifier += (userRewards * 25) / 100;
        } else if (currentTime < startTime + oneWeek * 3) {
            poolModifier += (userRewards * 35) / 100;
        } else if (currentTime < locktime) {
            poolModifier += (userRewards * 40) / 100;
        } else {
            poolModifier += userRewards;
        }
        if (isPositive) {
            withdrawAmount += poolModifier;
        } else {
            withdrawAmount -= poolModifier;
        }
        return withdrawAmount;
    }

    /**
     * @dev To know Penalty amount, if you unstake before locktime
     * parameters : _stakeid is active stake ids which is getting from activeStake-
     */
    function viewPenalty(
        address user,
        uint256 _stakeid
    ) public view returns (uint256) {
        uint256 userActiveStake = activeStake[user];
        require(_stakeid >= 0, "Please set valid stakeid!");
        require(_stakeid < userActiveStake, "Stake instance does not exist");
        uint256 penaltyTime = staking[user][_stakeid]._startTime +
            7 *
            24 *
            60 *
            60;
        uint256 penalty = 0;
        if (block.timestamp < penaltyTime) {
            penalty = (staking[user][_stakeid]._amount * 5) / 100;
        }
        return penalty;
    }
}