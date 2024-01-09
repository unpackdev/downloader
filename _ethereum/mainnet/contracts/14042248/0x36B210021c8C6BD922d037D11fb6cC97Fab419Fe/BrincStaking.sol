// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeERC20.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";

interface IBrincGovToken is IERC20Upgradeable {
    function mint(address _to, uint256 _amount) external;

    function mintToTreasury(uint256 _amount) external;

    function getTreasuryOwner() external view returns (address);
}

interface IStakedBrincGovToken {
    function mint(address _to, uint256 _amount) external;

    function burnFrom(address _to, uint256 _amount) external;
}

// BrincStaking is the contract in which the Brinc token can be staked to earn
// Brinc governance tokens as rewards.
//
// Note that it's ownable and the owner wields tremendous power. Staking will
// governable in the future with the Brinc Governance token.

contract BrincStaking is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IBrincGovToken;
    // Stake mode
    enum StakeMode {MODE1, MODE2, MODE3, MODE4, MODE5, MODE6}
    // Info of each user.
    struct UserInfo {
        uint256 brcStakedAmount; // Amount of BRC tokens the user will stake.
        uint256 gBrcStakedAmount; // Amount of gBRC tokens the user will stake.
        uint256 unlockTimestamp; // Stake block timestamp.
        uint256 rewardDebt; // Receivable reward. See explanation below.
        StakeMode mode; // Stake mode

        // We do some fancy math here. Basically, any point in time, the amount of govBrinc tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.brcStakedAmount * accGovBrincPerShare) - user.rewardDebt
        //   rewardDebt = staked rewards for a user 

        // Whenever a user deposits or withdraws LP tokens to a pool. The following happens:
        //   1. The pool's `accGovBrincPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        uint256 supply; // Weighted balance of Brinc tokens in the pool
        uint256 lockTime; // Lock time
        uint256 weight; // Weight for the pool
        uint256 accGovBrincPerShare; // Accumulated govBrinc tokens per share, times 1e12. See below.
        bool brcOnly;
    }

    // Last block number that govBrinc token distribution occurs.
    uint256 lastRewardBlock;

    // The Brinc TOKEN!
    IERC20Upgradeable public brincToken;
    // The governance Brinc TOKEN!
    IBrincGovToken public govBrincToken;
    // The staked governance Brinc TOKEN!
    IStakedBrincGovToken public stakedGovBrincToken;
    // govBrinc tokens created per block.
    uint256 public govBrincPerBlock;
    // Info of each pool.
    mapping(StakeMode => PoolInfo) public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo[]) public userInfo;

    // ratioBrcToGov is the ratio of Brinc to govBrinc tokens needed to stake
    uint256 public ratioBrcToGov;
    // gBrcStakeAmount = brc * ratio / 1e10

    // treasuryRewardBalance is the number of tokens awarded to the treasury address
    // this is implemented this way so that the treasury address will be responsible for paying for the minting of rewards.
    uint256 public treasuryRewardBalance;

    // paused indicates whether staking is paused.
    // when paused, the staking pools will not update, nor will any gov tokens be minted.
    bool public paused;
    // pausedBlock is the block number that pause was started.
    // 0 if not paused.
    uint256 public pausedBlock;

    uint256 private govTokenOverMinted;

    event Deposit(address indexed user, uint256 amount, StakeMode mode);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event TreasuryMint(uint256 amount);

    event LockTimeChanged(
        StakeMode mode,
        uint256 oldLockTime,
        uint256 newLockTime
    );
    event WeightChanged(
        StakeMode mode,
        uint256 oldWeight,
        uint256 newWeight
    );
    event GovBrincPerBlockChanged(
        uint256 oldGovBrincPerBlock,
        uint256 newGovBrincPerBlock
    );
    event RatioBrcToGovChanged(
        uint256 oldRatioBrcToGov, 
        uint256 newRatioBrcToGov
    );

    event Paused();
    event Resumed();

    function initialize(
        IERC20Upgradeable _brincToken,
        IBrincGovToken _brincGovToken,
        IStakedBrincGovToken _stakedGovBrincToken,
        uint256 _govBrincPerBlock,
        uint256 _ratioBrcToGov
    ) initializer public {
        brincToken = _brincToken;
        govBrincToken = _brincGovToken;
        stakedGovBrincToken = _stakedGovBrincToken;
        govBrincPerBlock = _govBrincPerBlock;
        lastRewardBlock = block.number;
        ratioBrcToGov = _ratioBrcToGov;
        paused = false;
        pausedBlock = 0;
        poolInfo[StakeMode.MODE1] = PoolInfo({
            supply: 0,
            lockTime:  30 * 24 * 60 * 60, // 30 days in seconds
            weight: 10,
            accGovBrincPerShare: 0,
            // represents the reward amount for each brinc token in the pool
            brcOnly: true
        });
        poolInfo[StakeMode.MODE2] = PoolInfo({
            supply: 0,
            lockTime:  90 * 24 * 60 * 60, // 90 days in seconds
            weight: 15,
            accGovBrincPerShare: 0,
            brcOnly: true
        });
        poolInfo[StakeMode.MODE3] = PoolInfo({
            supply: 0,
            lockTime:  180 * 24 * 60 * 60, // 180 days in seconds
            weight: 25,
            accGovBrincPerShare: 0,
            brcOnly: true
        });
        poolInfo[StakeMode.MODE4] = PoolInfo({
            supply: 0,
            lockTime:  30 * 24 * 60 * 60, // 30 days in seconds
            weight: 80,
            accGovBrincPerShare: 0,
            brcOnly: false
        });
        poolInfo[StakeMode.MODE5] = PoolInfo({
            supply: 0,
            lockTime:  90 * 24 * 60 * 60, // 90 days in seconds
            weight: 140,
            accGovBrincPerShare: 0,
            brcOnly: false
        });
        poolInfo[StakeMode.MODE6] = PoolInfo({
            supply: 0,
            lockTime:  180 * 24 * 60 * 60, // 180 days in seconds
            weight: 256,
            accGovBrincPerShare: 0,
            brcOnly: false
        });

        __Ownable_init();
    }

    modifier isNotPaused {
     require(paused == false, "paused: operations are paused by admin");
     _;
   }

   /**
     * @dev pause the staking contract
     * paused features:
     * - deposit
     * - withdraw
     * - updating pools
     */
    /// #if_succeeds {:msg "pause: paused is true"}
        /// paused == true;
    function pause() public onlyOwner {
        paused = true;
        pausedBlock = block.number;
        emit Paused();
    }

    /**
     * @dev resume the staking contract
     * resumed features:
     * - deposit
     * - withdraw
     * - updating pools
     */
    /// #if_succeeds {:msg "resume: paused is false"}
        /// paused == false;
    function resume() public onlyOwner {
        paused = false;
        pausedBlock = 0;
        emit Resumed();
    }

    /**
     * @dev if paused or not 
     *
     * @return paused
     */
    /// #if_succeeds {:msg "isPaused: returns paused"}
        /// $result == paused;
    function isPaused() public view returns(bool) {
        return paused;
    }

    /**
     * @dev block that pause was called.
     *
     * @return pausedBlock
     */
    /// #if_succeeds {:msg "getPausedBlock: returns PausedBlock"}
        /// $result == pausedBlock;
    function getPausedBlock() public view returns(uint256) {
        return pausedBlock;
    }

    /**
     * @dev last reward block that has been recorded
     *
     * @return lastRewardBlock
     */
    /// #if_succeeds {:msg "getLastRewardBlock: returns lastRewardBlock"}
        /// $result == lastRewardBlock;
    function getLastRewardBlock() public view returns(uint256) {
        return lastRewardBlock;
    }

    /**
     * @dev address of the Brinc token contract 
     *
     * @return Brinc token address
     */
    /// #if_succeeds {:msg "getBrincTokenAddress: returns Brinc Token address"}
        /// $result == address(brincToken);
    function getBrincTokenAddress() public view returns(address) {
        return address(brincToken);
    }

    /**
     * @dev address of the Brinc Governance token contract 
     *
     * @return Brinc Gov token address
     */
    /// #if_succeeds {:msg "getGovTokenAddress: returns Brinc Gov token address"}
        /// $result == address(govBrincToken);
    function getGovTokenAddress() public view returns(address) {
        return address(govBrincToken);
    }

    /**
     * @dev the number of Gov tokens that can be issued per block
     *
     * @return Brinc Gov reward tokens per block
     */
    /// #if_succeeds {:msg "getGovBrincPerBlock: returns Brinc Gov reward tokens per block"}
        /// $result == govBrincPerBlock;
    function getGovBrincPerBlock() public view returns(uint256) {
        return govBrincPerBlock;
    }

    /**
     * @dev The ratio of BRC to gBRC tokens 
     * The ratio dictates the amount of tokens of BRC and gBRC required for staking
     *
     * @return BRC to gBRC ratio required for staking
     */
    /// #if_succeeds {:msg "getRatioBtoG: returns BRC to gBRC ratio required for staking"}
        /// $result == ratioBrcToGov;
    function getRatioBtoG() public view returns(uint256) {
        return ratioBrcToGov;
    }

    /**
     * @dev get specified pool supply
     *
     * @return pool's supply
     */
    /// #if_succeeds {:msg "getPoolSupply: returns pool's supply"}
        /// $result == poolInfo[_mode].supply;
    function getPoolSupply(StakeMode _mode) public view returns(uint256) {
        return poolInfo[_mode].supply;
    }

    /**
     * @dev get specified pool lockTime
     *
     * @return pool's lockTime
     */
    /// #if_succeeds {:msg "getPoolLockTime: returns pool's lockTime"}
        /// $result == poolInfo[_mode].lockTime;
    function getPoolLockTime(StakeMode _mode) public view returns(uint256) {
        return poolInfo[_mode].lockTime;
    }
    
    /**
     * @dev get specified pool weight
     *
     * @return pool's weight
     */
    /// #if_succeeds {:msg "getPoolWeight: returns pool's weight"}
        /// $result == poolInfo[_mode].weight;
    function getPoolWeight(StakeMode _mode) public view returns(uint256) {
        return poolInfo[_mode].weight;
    }

    /**
     * @dev get specified pool accGovBrincPerShare
     *
     * @return pool's accGovBrincPerShare
     */
    /// #if_succeeds {:msg "getPoolAccGovBrincPerShare: returns pool's accGovBrincPerShare"}
        /// $result == poolInfo[_mode].accGovBrincPerShare;
    function getPoolAccGovBrincPerShare(StakeMode _mode) public view returns(uint256) {
        return poolInfo[_mode].accGovBrincPerShare;
    }

    /**
     * @dev get specified user information with correlating index
     * _address will be required to have an active staking deposit.
     * 
     * @return UserInfo
     */
    function getUserInfo(address _address, uint256 _index) public view returns(UserInfo memory) {
        require(userInfo[_address].length > 0, "getUserInfo: user has not made any stakes");
        return userInfo[_address][_index];
    }

    /**
     * @dev gets the number of stakes the user has made.
     * 
     * @return UserStakeCount
     */
    /// #if_succeeds {:msg "getStakeCount: returns user's active stakes"}
        /// $result == userInfo[_msgSender()].length;
    function getStakeCount() public view returns (uint256) {
        return userInfo[_msgSender()].length;
    }

    /**
     * @dev gets the total supply of all the rewards that .
     * totalSupply = ( poolSupply1 * poolWeight1 ) + ( poolSupply2 * poolWeight2 ) + ( poolSupply3 * poolWeight3 )
     *
     * @return total supply of all pools
     */
    /*
    // there is an error: `throw e;`
    // seems to be an issue with the scribble compiler
    /// #if_succeeds {:msg "getTotalSupplyOfAllPools: returns total supply of all pool tokens"}
        /// let pool1 := poolInfo[StakeMode.MODE1].supply.mul(poolInfo[StakeMode.MODE1].weight) in
        /// let pool2 := poolInfo[StakeMode.MODE2].supply.mul(poolInfo[StakeMode.MODE2].weight) in
        /// let pool3 := poolInfo[StakeMode.MODE3].supply.mul(poolInfo[StakeMode.MODE3].weight) in
        /// let pool4 := poolInfo[StakeMode.MODE4].supply.mul(poolInfo[StakeMode.MODE4].weight) in
        /// let pool5 := poolInfo[StakeMode.MODE5].supply.mul(poolInfo[StakeMode.MODE5].weight) in
        /// let pool6 := poolInfo[StakeMode.MODE6].supply.mul(poolInfo[StakeMode.MODE6].weight) in
        /// $result == pool1.add(pool2).add(pool3).add(pool4).add(pool5).add(pool6);
    */
    function getTotalSupplyOfAllPools() private view returns (uint256) {
        uint256 totalSupply;

        totalSupply = totalSupply.add(
            poolInfo[StakeMode.MODE1].supply.mul(poolInfo[StakeMode.MODE1].weight)
        )
        .add(
            poolInfo[StakeMode.MODE2].supply.mul(poolInfo[StakeMode.MODE2].weight)
        )
        .add(
            poolInfo[StakeMode.MODE3].supply.mul(poolInfo[StakeMode.MODE3].weight)
        )
        .add(
            poolInfo[StakeMode.MODE4].supply.mul(poolInfo[StakeMode.MODE4].weight)
        )
        .add(
            poolInfo[StakeMode.MODE5].supply.mul(poolInfo[StakeMode.MODE5].weight)
        )
        .add(
            poolInfo[StakeMode.MODE6].supply.mul(poolInfo[StakeMode.MODE6].weight)
        );

        return totalSupply;
    }

    /**
     * @dev gets the pending rewards of a user.]
     * View function to see pending govBrinc on frontend.
     *
     * formula:
     * reward = multiplier * govBrincPerBlock * pool.supply * pool.weight / totalSupply
     *
     * @return pending reward of a user
     */

    /// #if_succeeds {:msg "pendingRewards: the pending rewards of a given user should be correct - case: maturity has not passed"}
        /// let pendingReward, complete := $result in
        /// userInfo[_user][_id].unlockTimestamp > block.timestamp ==> 
        /// pendingReward == 0 && complete == false;
    /// #if_succeeds {:msg "pendingRewards: the pending rewards of a given user should be correct - case: maturity has passed with no pending rewards"}
        /// let accGovBrincPerShare := old(poolInfo[userInfo[_user][_id].mode].accGovBrincPerShare) in
        /// let totalSupply := old(getTotalSupplyOfAllPools()) in
        /// let multiplier := old(block.number.sub(lastRewardBlock)) in
        /// let govBrincReward := multiplier.mul(govBrincPerBlock).mul(poolInfo[userInfo[_user][_id].mode].supply).mul(poolInfo[userInfo[_user][_id].mode].weight).div(totalSupply) in
        /// let scaled := govBrincReward.mul(1e12).div(poolInfo[userInfo[_user][_id].mode].supply) in
        /// let updatedAccGovBrincPerShare := accGovBrincPerShare.add(scaled) in
        /// let pendingReward, complete := $result in
        /// (block.number > lastRewardBlock) && (poolInfo[userInfo[_user][_id].mode].supply != 0) ==> pendingReward == userInfo[_user][_id].brcStakedAmount.mul(updatedAccGovBrincPerShare).div(1e12).sub(userInfo[_user][_id].rewardDebt) && complete == true;
    /// #if_succeeds {:msg "pendingRewards: the pending rewards of a given user should be correct - case: maturity has passed with pending rewards"}
        /// let accGovBrincPerShare := poolInfo[userInfo[_user][_id].mode].accGovBrincPerShare in
        /// let pendingReward, complete := $result in
        /// (userInfo[_user][_id].unlockTimestamp <= block.timestamp) || (poolInfo[userInfo[_user][_id].mode].supply == 0) ==> pendingReward == userInfo[_user][_id].brcStakedAmount.mul(accGovBrincPerShare).div(1e12).sub(userInfo[_user][_id].rewardDebt) && complete == true;
    function pendingRewards(address _user, uint256 _id) public view returns (uint256, bool) {
        require(_id < userInfo[_user].length, "pendingRewards: invalid stake id");

        UserInfo storage user = userInfo[_user][_id];

        bool withdrawable; // false

        // only withdrawable after the user's stake has passed maturity
        if (block.timestamp >= user.unlockTimestamp) {
            withdrawable = true;
        }

        PoolInfo storage pool = poolInfo[user.mode];
        uint256 accGovBrincPerShare = pool.accGovBrincPerShare;
        uint256 totalSupply = getTotalSupplyOfAllPools();
        if (block.number > lastRewardBlock && pool.supply != 0) {
            uint256 multiplier;
            if (paused) {
                multiplier = pausedBlock.sub(lastRewardBlock);
            } else {
                multiplier = block.number.sub(lastRewardBlock);
            }
            
            uint256 govBrincReward =
                multiplier
                    .mul(govBrincPerBlock)
                    .mul(pool.supply) // supply is the number of staked Brinc tokens
                    .mul(pool.weight)
                    .div(totalSupply);
            accGovBrincPerShare = accGovBrincPerShare.add(
                govBrincReward.mul(1e12).div(pool.supply)
            );
        }
        return
            (user.brcStakedAmount.mul(accGovBrincPerShare).div(1e12).sub(user.rewardDebt), withdrawable);
    }

    function totalRewards(address _user) external view returns (uint256) {
        UserInfo[] storage stakes = userInfo[_user];
        uint256 total;
        for (uint256 i = 0; i < stakes.length; i++) {
            (uint256 reward, bool withdrawable) = pendingRewards(_user, i);
            if (withdrawable) {
                total = total.add(reward);
            }
        }

        return total;
    }

    /**
     * @dev updates the lockTime required for stakers to lock up their stakes for. 
     * This will be taken as seconds but will be converted to blocks by multiplying by the average block time.
     * This can only be called by the owner of the contract.
     * 
     * lock up blocks = lock up time * 13 [avg. block time]
     *
     * @param _updatedLockTime new lock up time
     */
    /// #if_succeeds {:msg "updateLockTime: the sender must be Owner"}
        /// old(msg.sender == this.owner());
    /// #if_succeeds {:msg "updateLockTime: sets lockTime correctly"}
        /// poolInfo[_mode].lockTime == _updatedLockTime;
    function updateLockTime(StakeMode _mode, uint256 _updatedLockTime) public onlyOwner {
        PoolInfo storage pool = poolInfo[_mode];
        uint256 oldLockTime = pool.lockTime;
        pool.lockTime = _updatedLockTime;
        emit LockTimeChanged(_mode, oldLockTime, _updatedLockTime);
    }

    /**
     * @dev updates the weight of a specified pool. The mode specified will map to the period 
     *
     * @param _mode period of the pool you wish to update
     * @param _weight new weight
     */
    /// #if_succeeds {:msg "updateWeight: the sender must be Owner"}
        /// old(msg.sender == this.owner());
    /// #if_succeeds {:msg "updateWeight: sets weight correctly"}
        /// poolInfo[_mode].weight == _weight;
    function updateWeight(StakeMode _mode, uint256 _weight) public onlyOwner {
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_mode];
        uint256 oldWeight = pool.weight;
        pool.weight = _weight;
        emit WeightChanged(_mode, oldWeight, _weight);
    }

    /**
     * @dev updates the govBrincPerBlock reward amount that will be issued to the stakers. This can only be called by the owner of the contract.
     *
     * @param _updatedGovBrincPerBlock new reward amount
     */
    /// #if_succeeds {:msg "updateGovBrincPerBlock: the sender must be Owner"}
        /// old(msg.sender == this.owner());
    /// #if_succeeds {:msg "updateGovBrincPerBlock: sets govBrincPerBlock correctly"}
        /// govBrincPerBlock == _updatedGovBrincPerBlock;
    function updateGovBrincPerBlock(uint256 _updatedGovBrincPerBlock) public onlyOwner {
        massUpdatePools();
        uint256 oldGovBrincPerBlock = govBrincPerBlock;
        govBrincPerBlock = _updatedGovBrincPerBlock;
        emit GovBrincPerBlockChanged(oldGovBrincPerBlock, govBrincPerBlock);
    }

    /**
     * @dev updates the ratio of BRC to gBRC tokens required for staking.
     *
     * @param _updatedRatioBrcToGov new ratio of BRC to gBRC for staking
     */
    /// #if_succeeds {:msg "updateRatioBrcToGov: the sender must be Owner"}
        /// old(msg.sender == this.owner());
    /// #if_succeeds {:msg "updateRatioBrcToGov: sets ratioBrcToGov correctly"}
        /// ratioBrcToGov == _updatedRatioBrcToGov;
    function updateRatioBrcToGov(uint256 _updatedRatioBrcToGov) public onlyOwner {
        uint256 oldRatioBrcToGov = ratioBrcToGov;
        ratioBrcToGov = _updatedRatioBrcToGov;
        emit RatioBrcToGovChanged(oldRatioBrcToGov, ratioBrcToGov);
    }

    /**
     * @dev staking owner will call to mint treasury tokens
     * implemented this way so that users will not have to pay for the minting of the treasury tokens
     * when pools are updated
     * the `treasuryBalance` variable is used to keep track of the total number of tokens that the
     * the treasury address will be able to mint at any given time.
     */
    /// #if_succeeds {:msg "treasuryMint: the sender must be Owner"}
        /// old(msg.sender == this.owner());
    function treasuryMint() public onlyOwner {
        require(treasuryRewardBalance > 0, "treasuryMint: not enough balance to mint");
        uint256 balanceToMint;
        balanceToMint = treasuryRewardBalance;
        treasuryRewardBalance = 0;
        govBrincToken.mintToTreasury(balanceToMint);
        emit TreasuryMint(balanceToMint);
    }

    /**
     * @dev updates all pool information.
     *
     * Note Update reward vairables for all pools. Be careful of gas spending!
     */
    /// #if_succeeds {:msg "massUpdatePools: case totalSupply == 0"}
        /// let multiplier := block.number - lastRewardBlock in
        /// let unusedReward := multiplier.mul(govBrincPerBlock) in
        /// getTotalSupplyOfAllPools() > 0 ==> treasuryRewardBalance == old(treasuryRewardBalance) + unusedReward;
    /// #if_succeeds {:msg "massUpdatePools: updates lastRewardBlock"}
        /// lastRewardBlock == block.number;
    function massUpdatePools() internal isNotPaused {
        uint256 totalSupply = getTotalSupplyOfAllPools();
        if (totalSupply == 0) {
            if (block.number > lastRewardBlock) {
                uint256 multiplier = block.number.sub(lastRewardBlock);
                uint256 unusedReward = multiplier.mul(govBrincPerBlock);
                treasuryRewardBalance = treasuryRewardBalance.add(unusedReward);
            }
        } else {
            uint256 govBrincReward;
            govBrincReward = govBrincReward.add(updatePool(StakeMode.MODE1));
            govBrincReward = govBrincReward.add(updatePool(StakeMode.MODE2));
            govBrincReward = govBrincReward.add(updatePool(StakeMode.MODE3));
            govBrincReward = govBrincReward.add(updatePool(StakeMode.MODE4));
            govBrincReward = govBrincReward.add(updatePool(StakeMode.MODE5));
            govBrincReward = govBrincReward.add(updatePool(StakeMode.MODE6));

            if (govTokenOverMinted >= govBrincReward) {
                govTokenOverMinted = govTokenOverMinted.sub(govBrincReward);
            } else {
                govBrincToken.mint(address(this), govBrincReward.sub(govTokenOverMinted));
                govTokenOverMinted = 0;
            }
        }
        lastRewardBlock = block.number;
    }

    /**
     * @dev update a given pool. This should be done every time a deposit or withdraw is made. 
     *
     * Note Update reward variables of the given pool to be up-to-date.
     */
    /// #if_succeeds {:msg "updatePool: updates pool's information and mint's reward"}
        /// let totalSupply := getTotalSupplyOfAllPools() in
        /// let multiplier := block.number.sub(lastRewardBlock) in
        /// let govBrincReward := multiplier.mul(govBrincPerBlock).mul(poolInfo[mode].supply).mul(poolInfo[mode].weight).div(totalSupply) in
        /// (block.number > lastRewardBlock) && (poolInfo[mode].supply != 0) ==> 
        /// govBrincToken.balanceOf(address(this)) == govBrincReward && poolInfo[mode].accGovBrincPerShare == poolInfo[mode].accGovBrincPerShare.add(govBrincReward.mul(1e12).div(poolInfo[mode].supply));
    function updatePool(StakeMode mode) internal isNotPaused returns (uint256) {
        PoolInfo storage pool = poolInfo[mode];
        if (block.number <= lastRewardBlock) {
            return 0;
        }
        if (pool.supply == 0) {
            return 0;
        }
        uint256 totalSupply = getTotalSupplyOfAllPools();
        uint256 multiplier = block.number.sub(lastRewardBlock);
        uint256 govBrincReward =
            multiplier
                .mul(govBrincPerBlock)
                .mul(pool.supply)
                .mul(pool.weight)
                .div(totalSupply);
        pool.accGovBrincPerShare = pool.accGovBrincPerShare.add(
            govBrincReward.mul(1e12).div(pool.supply)
        );
        return govBrincReward;
    }

    /**
     * @dev a user deposits some Brinc token for a given period. The period will be determined based on the pools.
     * Every time a user deposits any stake, the pool will be updated.
     * The user will only be allowed to deposit Brinc tokens to stake if they deposit the equivalent amount in governance tokens.
     *
     * Note Deposit Brinc tokens to BrincStaking for govBrinc token allocation.
     */
    /// #if_succeeds {:msg "deposit: deposit Brinc token amount is correct"}
        /// poolInfo[_mode].brcOnly == true ==> brincToken.balanceOf(address(this)) == _amount + old(brincToken.balanceOf(address(this))) && govBrincToken.balanceOf(address(this)) == old(govBrincToken.balanceOf(address(this)));
    /// #if_succeeds {:msg "deposit: deposit Brinc Gov token amount is correct"}
        /// poolInfo[_mode].brcOnly == false ==> brincToken.balanceOf(address(this)) == _amount + old(brincToken.balanceOf(address(this))) && govBrincToken.balanceOf(address(this)) == _amount.mul(ratioBrcToGov).div(1e10);
    /// #if_succeeds {:msg "deposit: successful deposit should update user information correctly"}
        /// let depositNumber := getStakeCount().sub(1) in
        /// depositNumber > 0 ==>
        /// userInfo[msg.sender][depositNumber].brcStakedAmount == _amount && userInfo[msg.sender][depositNumber].unlockTimestamp == block.timestamp.add(poolInfo[_mode].lockTime) && userInfo[msg.sender][depositNumber].rewardDebt == userInfo[msg.sender][depositNumber].brcStakedAmount.mul(poolInfo[_mode].accGovBrincPerShare).div(1e12) && userInfo[msg.sender][depositNumber].mode == _mode;
    /// #if_succeeds {:msg "deposit: pool supply is updated correctly"}
        /// let depositNumber := getStakeCount().sub(1) in
        /// depositNumber > 0 ==>
        /// poolInfo[_mode].supply == old(poolInfo[_mode].supply) + userInfo[msg.sender][depositNumber].brcStakedAmount;
    /// #if_succeeds {:msg "deposit: userInfo array should increment by one"}
        /// userInfo[msg.sender].length == old(userInfo[msg.sender].length) + 1;
    function deposit(uint256 _amount, StakeMode _mode) public {
        require(_amount > 0, "deposit: invalid amount");
        UserInfo memory user;
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_mode];
        brincToken.safeTransferFrom(msg.sender, address(this), _amount);
        user.brcStakedAmount = _amount;
        if (!pool.brcOnly) {
            govBrincToken.safeTransferFrom(
                msg.sender,
                address(this),
                _amount.mul(ratioBrcToGov).div(1e10)
            );
            user.gBrcStakedAmount = _amount.mul(ratioBrcToGov).div(1e10);
            stakedGovBrincToken.mint(msg.sender, user.gBrcStakedAmount);
        }
        user.unlockTimestamp = block.timestamp.add(pool.lockTime);
        user.rewardDebt = user.brcStakedAmount.mul(pool.accGovBrincPerShare).div(1e12);
        user.mode = _mode;

        pool.supply = pool.supply.add(user.brcStakedAmount);
        emit Deposit(msg.sender, _amount, _mode);

        userInfo[msg.sender].push(user);
    }

    /**
     * @dev a user withdraws their Brinc token that they have staked, including their rewards.
     * Every time a user withdraws their stake, the pool will be updated.
     *
     * Note Withdraw Brinc tokens from BrincStaking.
     */
    /// #if_succeeds {:msg "withdraw: token deducted from staking contract correctly"}
        /// let depositNumber := getStakeCount().sub(1) in
        /// let _amount := userInfo[msg.sender][depositNumber].brcStakedAmount in
        /// depositNumber > 0 ==>
        /// old(brincToken.balanceOf(address(this))) == brincToken.balanceOf(address(this)) - _amount;
    /// #if_succeeds {:msg "withdraw: user's withdrawn Brinc token amount is correct"}
        /// let depositNumber := getStakeCount().sub(1) in
        /// let _amount := userInfo[msg.sender][depositNumber].brcStakedAmount in
        /// depositNumber > 0 ==>
        /// brincToken.balanceOf(msg.sender) == old(brincToken.balanceOf(msg.sender)) + _amount;
    /// #if_succeeds {:msg "withdraw: user's withdrawn Brinc Gov reward amount is correct"}
        /// let reward, complete := old(pendingRewards(msg.sender, userInfo[msg.sender].length - 1)) in
        /// govBrincToken.balanceOf(msg.sender) == reward && complete == true;
    /// #if_succeeds {:msg "withdraw: user information is updated correctly"}
        /// let depositNumber := getStakeCount().sub(1) in
        /// let _amount := userInfo[msg.sender][depositNumber].brcStakedAmount in
        /// depositNumber > 0 ==>
        /// userInfo[msg.sender][depositNumber].rewardDebt == userInfo[msg.sender][depositNumber].brcStakedAmount.mul(poolInfo[userInfo[msg.sender][depositNumber].mode].accGovBrincPerShare).div(1e12) && userInfo[msg.sender][depositNumber].mode == userInfo[msg.sender][depositNumber].mode;
    /// #if_succeeds {:msg "withdraw: pool supply is updated correctly"}
        /// let depositNumber := getStakeCount().sub(1) in
        /// depositNumber > 0 ==>
        /// poolInfo[userInfo[msg.sender][depositNumber].mode].supply == old(poolInfo[userInfo[msg.sender][depositNumber].mode].supply).sub(userInfo[msg.sender][depositNumber].brcStakedAmount);
    function withdraw(uint256 _id) public {
        require(_id < userInfo[msg.sender].length, "withdraw: invalid stake id");

        UserInfo memory user = userInfo[msg.sender][_id];
        require(user.brcStakedAmount > 0, "withdraw: nothing to withdraw");
        require(user.unlockTimestamp <= block.timestamp, "withdraw: stake is still locked");
        massUpdatePools();
        PoolInfo storage pool = poolInfo[user.mode];
        uint256 pending =
            user.brcStakedAmount.mul(pool.accGovBrincPerShare).div(1e12).sub(user.rewardDebt);
        safeGovBrincTransfer(msg.sender, pending.add(user.gBrcStakedAmount));
        stakedGovBrincToken.burnFrom(msg.sender, user.gBrcStakedAmount);
        uint256 _amount = user.brcStakedAmount;
        brincToken.safeTransfer(msg.sender, _amount);
        pool.supply = pool.supply.sub(_amount);
        emit Withdraw(msg.sender, _amount);

        _removeStake(msg.sender, _id);
    }

    /**
     * @dev a user withdraws their Brinc token that they have staked, without caring their rewards.
     * Only pool's supply will be updated.
     *
     * Note EmergencyWithdraw Brinc tokens from BrincStaking.
     */
    function emergencyWithdraw(uint256 _id) public {
        require(_id < userInfo[msg.sender].length, "emergencyWithdraw: invalid stake id");

        UserInfo storage user = userInfo[msg.sender][_id];
        require(user.brcStakedAmount > 0, "emergencyWithdraw: nothing to withdraw");
        PoolInfo storage pool = poolInfo[user.mode];
        safeGovBrincTransfer(msg.sender, user.gBrcStakedAmount);
        stakedGovBrincToken.burnFrom(msg.sender, user.gBrcStakedAmount);

        uint256 pendingReward =
            user.brcStakedAmount.mul(pool.accGovBrincPerShare).div(1e12).sub(user.rewardDebt);
        govTokenOverMinted = govTokenOverMinted.add(pendingReward);

        delete user.gBrcStakedAmount;
        uint256 _amount = user.brcStakedAmount;
        delete user.brcStakedAmount;
        brincToken.safeTransfer(msg.sender, _amount);
        pool.supply = pool.supply.sub(_amount);
        emit EmergencyWithdraw(msg.sender, _amount);

        _removeStake(msg.sender, _id);
    }

    function _removeStake(address _user, uint256 _id) internal {
        require(_id < userInfo[_user].length, "invalid _id");

        userInfo[_user][_id] = userInfo[_user][userInfo[_user].length - 1];
        userInfo[_user].pop();
    }

    /**
     * @dev the safe transfer of the governance token rewards to the designated adress with the specified reward. 
     * Safe govBrinc transfer function, just in case if rounding error causes pool to not have enough govBrinc tokens.
     *
     * @param _to address to send Brinc Gov token rewards to
     * @param _amount amount of Brinc Gov token rewards to send
     *
     * Note this will be only used internally inside the contract.
     */
    /// #if_succeeds {:msg "safeGovBrincTransfer: transfer of Brinc Gov token is correct - case _amount > govBrincBal"}
        /// let initGovBrincBal := old(govBrincToken.balanceOf(_to)) in
        /// let govBrincBal := old(govBrincToken.balanceOf(address(this))) in
        /// _amount > govBrincBal ==> govBrincToken.balanceOf(_to) == initGovBrincBal + govBrincBal;
    /// #if_succeeds {:msg "safeGovBrincTransfer: transfer of Brinc Gov token is correct - case _amount < govBrincBal"}
        /// let initGovBrincBal := old(govBrincToken.balanceOf(_to)) in
        /// let govBrincBal := old(govBrincToken.balanceOf(address(this))) in
        /// _amount <= govBrincBal ==> govBrincToken.balanceOf(_to) == initGovBrincBal + _amount;
    function safeGovBrincTransfer(address _to, uint256 _amount) internal {
        uint256 govBrincBal = govBrincToken.balanceOf(address(this));
        if (_amount > govBrincBal) {
            govBrincToken.transfer(_to, govBrincBal);
        } else {
            govBrincToken.transfer(_to, _amount);
        }
    }
}