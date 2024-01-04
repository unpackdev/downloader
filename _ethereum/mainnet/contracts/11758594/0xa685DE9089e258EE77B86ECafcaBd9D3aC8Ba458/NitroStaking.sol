// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;
import "./SafeERC20.sol";
import "./TransferHelper.sol";
import "./UniswapV2Library.sol";
import "./IUniswapV2Router.sol";
import "./IKeep3rV1Mini.sol";

contract NitroStaking
{
    using SafeMath for uint256;

    uint256 internal scalefactor = 1e18;

    uint256 private _maxSellRemoval;

    uint256 private _maxBuyBonus;

    uint256 internal _totalNistToDist = 0;

    /// @notice Describes the minimum balance required to receive auto-rewards
    uint256 public minimumRewardBalance = 1 * 1 ether;

    /// @notice The minimum balance required to be eligible for automatic payouts
    uint256 public minimumAutoPayoutBalance = 0.1 * 1 ether;

    uint256 private totalstakes;

    /// @notice Describes the remaining ETH in the contract balance that is unallocated to rewards
    //          I.E. The contract may have 20 ETh in it but 10 ETH might already be allocated to existing stakers accruing a balance
    uint256 public remainingNISTToAllocate;

    /**
     * @notice The previous timestamp for reward allocation. Gets set to block.timestamp on reward distribution.
     */
    uint256 public previousRewardDistributionTimestamp;

    /**
     * @dev This is instantiated to 48 hours currently.The time over which the entire balance of this contract, if unchanged, would be sent to stakers.
     */
    uint balance_emission_time = 48 hours;

    /**
     * @notice The nist output per second in the staking system.
     * @dev This is only updated every time the eth balance of the contract increases.
     */
    uint256 public nist_output_per_second;

    /**
     * @param stake The amount of NIST staked.
     * @param S_init The value of S at the time this stake occured.
     * @param owed_rewards Any NIST rewards this user accrued that we want to keep track of for historical reasons.
     */
    struct StakeData{
        uint256 stake;
        uint256 S_init;
        uint256 owed_rewards;
    }

    /**
    * @notice The stakes for each stakeholder.
    */
    mapping(address => StakeData) public _stakes;
    /**
     * @dev All of the addresses involved in the staking system.
     */
    address[] internal _stakeholders;

    /**
     * @dev The running total of eth payout per staked NIST.
     */
    uint256 public S;
    //
    IUniswapV2Router router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address payable public RelayerJob;

    //RLR contract which will add eth credit to the job
    IKeep3rV1Mini public RLR;

//////////////////----------------Public View Variables----------------///////////////

    //Return the maxSellRemoval
    function maxSellRemoval() public view returns (uint256) {
        return _maxSellRemoval;
    }

    function maxBuyBonus() public view returns (uint256) {
        return _maxBuyBonus;
    }

   /**
    * @notice A method to get the stakeholders as a memory address array
    * @return uint256 The list of stakeholders
    */
    function stakeHolders() public view returns (address[] memory) {
        return _stakeholders;
    }

   /**
    * @notice A method to the aggregated stakes from all _stakeholders.
    * @return uint256 The aggregated stakes from all _stakeholders.
    */
   function totalStakes()
       public
       view
       returns(uint256)
   {
       uint256 _totalStakes = 0;
       for (uint256 s = 0; s < _stakeholders.length; s += 1){
           _totalStakes = _totalStakes.add(_stakes[_stakeholders[s]].stake);
       }
       return _totalStakes;
   }

   /**
    * @notice A method to the aggregated rewards from all _stakeholders.
    * @return uint256 The aggregated rewards from all _stakeholders.
    */
   function totalUnclaimedRewards()
       public
       view
       returns(uint256)
   {
       uint256 _totalRewards = 0;
       for (uint256 s = 0; s < _stakeholders.length; s += 1){
           _totalRewards = _totalRewards.add(calculateRewardWithFee(_stakeholders[s]));
       }
       return _totalRewards;
   }

    function getEligibleCount(uint256 target) internal view returns (uint256 count) {
        count = 0;
        for (uint256 s = 0; s < _stakeholders.length; s += 1){
            if(count >= target && target != 0) return count;
            if(calculateRewardWithFee(_stakeholders[s]) > minimumAutoPayoutBalance){
                count += 1;
            }
        }
    }

    /**
    * @notice Returns an iterable list of addresses that qualify for automatic payout
    * @dev This is pretty bad to use because it can run out of gas, please supplement with getNextEligibleAddressForAutomaticPayout and
    *      try again with a lower numToFind.
    * @param numToFind Is the number of addresses to pull from the database; Set to 0 to find all.
    * Returns An array that from 0->i has eligible addresses then from i->_stakeholders.length contains empty and total_rewards The total amount of NIST required to be liquidated if these users were paid
    * Use static call if you are using scripts to get data 
    */
    function getEligibleAddressesForAutomaticPayout(uint256 numToFind)
        public
        view
        returns(address[] memory eligible_addresses, uint256 total_rewards)
    {
        (uint256 eligible_count) = getEligibleCount(numToFind);
        eligible_addresses = new address[](eligible_count);
        uint256 count = 0;
        total_rewards = 0;
        for (uint256 s = 0; s < _stakeholders.length && count < eligible_addresses.length ; s++){
            uint256 reward = calculateRewardWithFee(_stakeholders[s]);
            if(reward > minimumAutoPayoutBalance){
                eligible_addresses[count] = _stakeholders[s];
                total_rewards += reward;
                count += 1;
            }
        }
        return (eligible_addresses, total_rewards);
    }

    /**
    * @notice Returns the next address in the list that is available for auto payout
    * @dev External iteration required
    * @return The next address eligible for auto payout.
    */
    function getNextEligibleAddressForAutomaticPayout()
        public
        view
        returns(address)
    {
        for (uint256 s = 0; s < _stakeholders.length; s += 1){
            if(calculateRewardWithFee(_stakeholders[s]) > minimumAutoPayoutBalance) return _stakeholders[s];
        }
        return address(0);
    }

   /**
    * @notice A method to check if an address is a stakeholder.
    * @param _address The address to verify.
    * @return bool, uint256 Whether the address is a stakeholder,
    * and if so its position in the _stakeholders array.
    */
   function isStakeholder(address _address)
       public
       view
       returns(bool, uint256)
   {
       for (uint256 s = 0; s < _stakeholders.length; s += 1){
           if (_address == _stakeholders[s]) return (true, s);
       }
       return (false, 0);
   }

   /**
    * @notice A method to retrieve the stake for a stakeholder.
    * @param _stakeholder The stakeholder to retrieve the stake for.
    * @return uint256 The amount of wei staked.
    */
   function stakeOf(address _stakeholder)
       public
       view
       returns(uint256)
   {
       return _stakes[_stakeholder].stake;
   }

   /**
    * @notice A simple method that calculates the rewards for a given stakeholder.
    * @param _stakeholder The stakeholder to calculate rewards for.
    * @return The amount of ETH owed to this _stakeholder.
    */
    function calculateRewardWithFee(address _stakeholder)
       public
       view
       returns(uint256)
    {
        return calculateRewardWithoutFee(_stakeholder).mul(94).div(100);
    }

    function getNistToETHPath() internal view returns (address[] memory) {
        //Create path
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        return path;
    }

    function getEstimateAmounts(uint256 nistAmount) internal view returns (uint256[] memory amountarr) {
        if(nistAmount <= 0){
            amountarr = new uint256[](2);
            amountarr[0] = 0;
            amountarr[1] = 0;
            return amountarr;
        }
        //Get estimated output
        amountarr = UniswapV2Library.getAmountsOut(router.factory(),nistAmount,getNistToETHPath());
    }

    /**
     * @notice Since 5% of earned fees go to RLR worker, the public function removes the fee. For the purposes of calculating, this is the
     * function with the true number of tokens earned by the user.
     */
    function calculateRewardWithoutFee(address _stakeholder)
        internal
        view
        returns(uint256)
    {
        uint256 earned_nist = calculateEarnedNIST(_stakeholder);
        return getEstimateAmounts(earned_nist)[1];
    }

    /**
     * @notice Returns the amount of NIST earned in the internal staking system.
     * @dev Use this to get the amount of NIST earned before it's converted to ETH.
     */
    function calculateEarnedNIST(address _stakeholder)
        public
        view
        returns (uint256 earned_NIST)
    {
        //(user's Stake)*(S- S_when_user_joined) + owed_rewards
        return ((_stakes[_stakeholder].stake).mul(S.sub(_stakes[_stakeholder].S_init)).div(scalefactor)).add(_stakes[_stakeholder].owed_rewards);
    }

    /**
     * @notice An approximate value for the NIST introduced into the system assuming price and global staking balance is constant.
     * @return The amount of ETH / NIST a user should expect to receive over the next distribution period. 
     */
    function approximateETHPerNISTOutput()
        public
        view
        returns(uint256)
    {
        return getEstimateAmounts(remainingNISTToAllocate)[1].div(totalStakes());
    }

//////////////////----------------Modify Variables, Internal----------------///////////////

    modifier onlyRelayerJob() {
        require(msg.sender == RelayerJob);
        _;
    }

    /**
     * @notice Set the maximum percent order volume of tokens taken in a sell order
     */
    function _changeMaxSellRemoval(uint256 new_maxSellRemoval) internal {
        _maxSellRemoval = new_maxSellRemoval;
    }

    /**
     * @notice Set the maximum percent order volume of bonus tokens for buyers
     */
    function _setMaxBuyBonusPercentage(uint256 new_maxBuyBonus) internal {
        _maxBuyBonus = new_maxBuyBonus;
    }

    /**
    * @notice A method to add a stakeholder.
    * @param _stakeholder The stakeholder to add.
    */
   function addStakeholder(address _stakeholder)
       internal
   {
       (bool _isStakeholder, ) = isStakeholder(_stakeholder);
       if(!_isStakeholder) _stakeholders.push(_stakeholder);
   }

   /**
    * @notice A method to remove a stakeholder.
    * @param _stakeholder The stakeholder to remove.
    */
   function removeStakeholder(address _stakeholder)
       internal
   {
       (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
       if(_isStakeholder){
           _stakeholders[s] = _stakeholders[_stakeholders.length - 1];
           _stakeholders.pop();
       }
   }

   /**
    * @notice A method for a stakeholder to create a stake.
    * @param _stakeholder The address of the stakeholder.
    * @dev Every addition resets the stake history. ETH transfer is included to claim the rewards for the user. 
    */
   function updateStake(address _stakeholder, uint256 user_current_balance)
       internal
   {
        (bool _isStakeholder,) = isStakeholder(_stakeholder);
        if(user_current_balance >= minimumRewardBalance){
            //Possibly add to stakeholder list if not included
            addStakeholder(_stakeholder);

            //Update the staking data to the current balance
            saveRewardData(_stakeholder, user_current_balance);
        }else if (_isStakeholder){ // User doesn't qualify for staking but is still included as stakeholder, needs to be removed

            //Update the staking data to the current balance
            saveRewardData(_stakeholder, user_current_balance);

            //Remove from stakeholder list
            removeStakeholder(_stakeholder);
        }
   }

    /**
     * @notice In the event that a stake is updated, we have to store the staking reward information for later for recall.
    *       This saves the data in a way that doesn't destroy previous reward history.
     */
   function saveRewardData(address _stakeholder, uint256 user_current_balance)
        internal
    {
        //Get the most up-to-date reward distribution
        distributeRewards(calcInstantaneousDistributionAmount());
        //Update the staking data for this user to the current S value, with the stored IOU rewards
        _stakes[_stakeholder] = StakeData(user_current_balance, S, calculateEarnedNIST(_stakeholder));
    }

   /**
    * @notice A method to allow a stakeholder to withdraw his rewards.
    * @dev This one doesn't liquidate the allocated nist for this user
    */
   function claimRewardsInternal(address _stakeholder)
       internal
   {
        uint256 reward = calculateRewardWithFee(_stakeholder);
        if(reward != 0 && address(this).balance >= reward){ //We can't check if it's above minimum auto payout, b/c we sometimes payout even if they don't qualify (like if they update their stake)
            //Transfer the owed reward to the user
            TransferHelper.safeTransferETH(_stakeholder,reward);

            //Reset user's S_init to be current S
            _stakes[_stakeholder] = StakeData(_stakes[_stakeholder].stake, S, 0);
        }
   }

    /**
     * @notice The public method for claiming rewards, which includes a swap of nist to eth for the tokens needed
     */
    function claimRewardsPublic(address _stakeholder)
        public
    {
        distributeRewards(calcInstantaneousDistributionAmount());
        uint256 num_tokens_to_liquidate = calculateEarnedNIST(_stakeholder);
        if(num_tokens_to_liquidate != 0){
            swapTokenstoETH(num_tokens_to_liquidate);
            claimRewardsInternal(_stakeholder);
        }
    }

// ------------------ Admin functions --------------//
    /**
    * @notice A method to distribute rewards to all _stakeholders.
    * @param r The amount of NIST at this moment in time to be distributed between all stakers when they eventually withdraw.
    * @dev Implementing this function with calcInstantaneousDistributionAmount() is how the RLR will perform the distribution job
    */
    function distributeRewards(uint256 r)
    internal
    {
        uint256 total_stakes = totalStakes();
        if(total_stakes != 0 && r <= remainingNISTToAllocate){
            S = S.add(r.mul(scalefactor).div(total_stakes));

            //Make sure we keep track of how much nist we have left to allocate
            remainingNISTToAllocate = remainingNISTToAllocate.sub(r);

            //Update the distribution timestamp to keep emissions constant
            previousRewardDistributionTimestamp = block.timestamp;
        }
    }

    /**
     * @notice Calculates what the variable r in distributeRewards should be given the current timestamp, last distribution timestamp, and the current rate
     * @dev This function will be used as the input to distribute rewards.
     * @return The amount of NIST appropriate to be distributed at this moment
     */
    function calcInstantaneousDistributionAmount()
        public
        view
        returns
        (uint256)
    {
        uint256 initCalc = (block.timestamp.sub(previousRewardDistributionTimestamp)).mul(nist_output_per_second);
        //If we've reached the end of the distribution period without a change in the NIST balance of the contract,
        //      it will attempt to continue the same rate of distribution. This returns zero in this case
        return (initCalc > remainingNISTToAllocate) ? 0 : initCalc;
    }

    /**
     * @notice Updates the emissions rate of the distribution mechanism.
     * @dev This currently is used for when the NIST for staking balance changes
     */
    function updateStakingOutputPerSecond(uint256 newTotalNist, uint256 newAllocNist)
        internal
    {
        _totalNistToDist = newTotalNist;
        remainingNISTToAllocate = newAllocNist;
        nist_output_per_second = remainingNISTToAllocate.div(balance_emission_time);
    }

    receive() external payable {
        if(RelayerJob != address(0) && msg.sender != RelayerJob) {
            //Send 5% of eth to rlr contract to add credit
            RLR.addCreditETH{value:msg.value.mul(5).div(100) }(RelayerJob);
        }
    }

    function swapTokenstoETH(uint256 numTokens) internal {
        //Get estimated output
        uint256[] memory amounts = getEstimateAmounts(numTokens);
        //swap with eth send to self
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amounts[0],
            amounts[1],
            getNistToETHPath(),
            address(this),
            block.timestamp
        );
        //Update the tracked NIST to distribute
        updateStakingOutputPerSecond(_totalNistToDist.sub(amounts[0]), remainingNISTToAllocate.sub(amounts[0]));
    }

    /**
    /**
     * @notice The primary interface function for hte relayer job to send rewards to eligible _stakeholders
     * @dev This needs to be compliant with the RLR protocols
     */
    function processAutoRewardPayouts(address[] calldata stakers,uint256 tokens_to_liquidate) external onlyRelayerJob
    {
        require(_totalNistToDist > 0, "!NIST_To_Distribute");
        distributeRewards(calcInstantaneousDistributionAmount());
        swapTokenstoETH(tokens_to_liquidate);
        for(uint i = 0;i<stakers.length;i++)
            claimRewardsInternal(stakers[i]);
    }


    function updateMinimumAutoPayoutBalance(uint256 new_minimum)
        internal
    {
        minimumAutoPayoutBalance = new_minimum;
    }
}
