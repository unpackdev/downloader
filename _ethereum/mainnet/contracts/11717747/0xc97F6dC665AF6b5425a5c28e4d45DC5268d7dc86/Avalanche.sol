// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./AvalancheBase.sol";
import "./IAvalanche.sol";
import "./IPWDR.sol";
import "./ILoyalty.sol";
import "./ISlopes.sol";

contract Avalanche is IAvalanche, AvalancheBase {
    event Activated(address indexed user);
    event Distribution(address indexed user, uint256 totalPwdrRewards, uint256 payoutPerDay);
    event Claim(address indexed user, uint256 pwdrAmount);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event PwdrRewardAdded(address indexed user, uint256 pwdrReward);
    event EthRewardAdded(address indexed user, uint256 ethReward);

    uint256 public constant PAYOUT_INTERVAL = 24 hours; // How often the payouts occur
    uint256 public constant TOTAL_PAYOUTS = 10; // How many payouts per distribution cycle, updated to 10 in V2
    
    uint256 public nextEpochPwdrReward; // accumulated pwdr for next distribution cycle
    uint256 public epochPwdrReward; // current epoch rewards
    uint256 public epochPwdrRewardPerDay; // 5% per day, 20 days
    uint256 public unstakingFee; // The unstaking fee that is used to increase locked liquidity and reward Avalanche stakers (1 = 0.1%). Defaults to 10%
    uint256 public buybackAmount; // The amount of PWDR-ETH LP tokens kept by the unstaking fee that will be converted to PWDR and distributed to stakers (1 = 0.1%). Defaults to 50%

    bool public override active; // Becomes true once the 'activate' function called

    uint256 public startTime; // When the first payout can be processed (timestamp). It will be 24 hours after the Avalanche contract is activated
    uint256 public lastPayout; // When the last payout was processed (timestamp)
    uint256 public lastReward; // timestamp when last pwdr reward was minted
    uint256 public accPwdrPerShare; // Accumulated PWDR per share, times 1e12.
    uint256 public totalStaked; // The total amount of PWDR-ETH LP tokens staked in the contract
    uint256 public totalShares; // The total amount of pool shares
    uint256 public weight; // pool weight 

    modifier AvalancheActive {
        require(active, "Avalanche is not active");
        _;
    }

    modifier SlopesActive {
        require(ISlopes(slopesAddress()).active(), "Slopes are not active");
        _;
    }

    modifier OnlyAuthorized {
        require(
            _msgSender() == pwdrAddress() || hasPatrol("ADMIN", _msgSender()),
            "Only PWDR Contract can call this function"
        );
        _;
    }

    constructor(address addressRegistry) 
        public 
        AvalancheBase(addressRegistry)
    {
        unstakingFee = 100;
        buybackAmount = 500;
        weight = 5;
    }

    // activate the avalanche distribution phase
    //  signified avalanche is open on first call and calcs
    //  all necessary rewards vars
    function activate() 
        external
        override
        OnlyAuthorized
    {
        if (IPWDR(pwdrAddress()).currentEpoch() == 0) {
            return;
        }

        if (!active) {
            active = true;
            emit Activated(msg.sender);
        }

        // The first payout can be processed 24 hours after activation
        startTime = block.timestamp + getDistributionPayoutInterval(); 
        lastPayout = startTime;
        epochPwdrReward = epochPwdrReward.add(nextEpochPwdrReward);
        epochPwdrRewardPerDay = epochPwdrReward.div(getTotalDistributionPayouts());
        nextEpochPwdrReward = 0;

        emit Distribution(msg.sender, epochPwdrReward, epochPwdrRewardPerDay);
    }

    // The _transfer function in the PWDR contract calls this to let the Avalanche contract know that it received the specified amount of PWDR to be distributed 
    function addPwdrReward(address _from, uint256 _amount) 
        external
        override
        SlopesActive
        OnlyPWDR
    {
        // if max supply is hit, distribute directly to pool
        // else always add reward to next epoch rewards.
        if (IPWDR(pwdrAddress()).maxSupplyHit()) {
            accPwdrPerShare = accPwdrPerShare.add(_amount.mul(1e12).div(totalShares));
        } else {
            nextEpochPwdrReward = nextEpochPwdrReward.add(_amount);
        }

        emit PwdrRewardAdded(_from, _amount);
    }

    receive() external payable {
        addEthReward();
    }

    // Allows external sources to add ETH to the contract which is used to buy and then distribute PWDR to stakers
    function addEthReward() 
        public 
        payable
        SlopesActive
    {
        uint256 ethBalance = address(this).balance;
        require(ethBalance > 0, "Must have eth to swap");
        _swapExactETHForTokens(address(this).balance, pwdrAddress());

        // The _transfer function in the PWDR contract calls the Avalanche contract's updateOwdrReward function 
        // so we don't need to update the balances after buying the PWRD token
        emit EthRewardAdded(msg.sender, msg.value);
    }

    function _updatePool() 
        internal 
    {
        if (!active) {
            return;
        } else if (IPWDR(pwdrAddress()).accumulating()) {
            _processAccumulationPayouts();
        } else {
            _processDistributionPayouts();
        }
    }

    // handles updating the pool during accumulation phases
    function _processAccumulationPayouts() internal {
        if (block.timestamp <= lastReward) {
            return;
        }

        if (totalStaked == 0) {
            lastReward = block.timestamp;
            return;
        }

        // Calculate the current PWDR rewards for a specific pool
        //  using fixed APR formula and Uniswap price
        uint256 tokenPrice = _getLpTokenPrice(pwdrPoolAddress());
        uint256 pwdrReward = _calculatePendingRewards(
            lastReward,
            totalShares,
            tokenPrice,
            weight
        );

        // if we hit the max supply here, ensure no overflow 
        //  epoch will be incremented from the token
        address pwdrAddress = pwdrAddress();
        uint256 pwdrTotalSupply = IERC20(pwdrAddress).totalSupply();
        if (pwdrTotalSupply.add(pwdrReward) >= IPWDR(pwdrAddress).currentMaxSupply()) {
            pwdrReward = IPWDR(pwdrAddress).currentMaxSupply().sub(pwdrTotalSupply);
        }

        if (pwdrReward > 0) {
            IPWDR(pwdrAddress).mint(address(this), pwdrReward);
            accPwdrPerShare = accPwdrPerShare.add(pwdrReward.mul(1e12).div(totalShares));
            lastReward = block.timestamp;
        }
    }

    // Handles paying out the fixed distribution payouts over 20 days
    // rewards directly added to accPwdrPerShare at max supply hit, becomes a direct calculation
    function _processDistributionPayouts() internal {
        if (block.timestamp < startTime
            || IPWDR(pwdrAddress()).maxSupplyHit() 
            || epochPwdrReward == 0 || totalStaked == 0) 
        {
            return;
        }

        // How many days since last payout?
        uint256 daysSinceLastPayout = (block.timestamp - lastPayout) / getDistributionPayoutInterval();

        // If less than 1, don't do anything
        if (daysSinceLastPayout == 0) {
            return;
        }

        // Work out how many payouts have been missed
        uint256 payoutNumber = payoutNumber();
        uint256 previousPayoutNumber = payoutNumber - daysSinceLastPayout;

        // Calculate how much additional reward we have to hand out
        uint256 pwdrReward = rewardAtPayout(payoutNumber) - rewardAtPayout(previousPayoutNumber);
        if (pwdrReward > epochPwdrReward) {
            pwdrReward = epochPwdrReward;
        }
        epochPwdrReward = epochPwdrReward.sub(pwdrReward);

        // Payout the pwdrReward to the stakers
        accPwdrPerShare = accPwdrPerShare.add(pwdrReward.mul(1e12).div(totalShares));

        // Update lastPayout times 
        lastPayout += (daysSinceLastPayout * getDistributionPayoutInterval());
        lastReward = block.timestamp;

        // Update epoch if we have reached the final payout of distribution
        if (payoutNumber >= getTotalDistributionPayouts()) {
            IPWDR(pwdrAddress()).updateEpoch(IPWDR(pwdrAddress()).currentEpoch() + 1, 0);
        }
    }

    // Claim earned PWDR
    function claim()
        external
        override
    {        
        _updatePool();
        _claim(msg.sender);
    }

    function claimFor(address _user)
        external
        override
        OnlyLoyalty
    {
        _updatePool();
        _claim(_user);
    }

    function _claim(address _user)
        internal
    {
        if (!active) {
            return;
        }

        UserInfo storage user = userInfo[_user];
        if (user.staked > 0) {
            uint256 pendingPwdrReward = user.shares.mul(accPwdrPerShare).div(1e12).sub(user.rewardDebt);
            if (pendingPwdrReward > 0) {
                user.claimed += pendingPwdrReward;
                user.rewardDebt = user.shares.mul(accPwdrPerShare).div(1e12);

                // update user/pool shares
                uint256 shares = ILoyalty(loyaltyAddress()).getTotalShares(_user, user.staked);
                if (shares > user.shares) {
                    totalShares = totalShares.add(shares.sub(user.shares));
                } else if (shares < user.shares) {
                    totalShares = totalShares.sub(user.shares.sub(shares));
                }
                user.shares = shares;

                _safeTokenTransfer(
                    pwdrAddress(),
                    _user,
                    pendingPwdrReward
                );

                emit Claim(_user, pendingPwdrReward);
            }
        }
    }

     // Stake PWDR-ETH LP tokens
    function deposit(uint256 _amount) 
        external
        override
    {
        _deposit(msg.sender, msg.sender, _amount);
    }

    // stake for another user, used to migrate to this pool
    function depositFor(address _from, address _user, uint256 _amount)
        external
        override
        OnlySlopes
    {
        _deposit(_from, _user, _amount);
    }

    // Stake PWDR-ETH LP tokens for address
    function _deposit(address _from, address _user, uint256 _amount) 
        internal 
        AvalancheActive
        NonZeroAmount(_amount)
    {
        IERC20(pwdrPoolAddress()).safeTransferFrom(_from, address(this), _amount);

        _updatePool();
        _claim(_user);

        UserInfo storage user = userInfo[_user];

        uint256 shares = ILoyalty(loyaltyAddress()).getTotalShares(_user, _amount);
        totalShares = totalShares.add(shares);
        user.shares = user.shares.add(shares);

        totalStaked = totalStaked.add(_amount);
        user.staked = user.staked.add(_amount);
        user.rewardDebt = user.shares.mul(accPwdrPerShare).div(1e12);

        emit Deposit(_user, _amount);
    }

    // Unstake and withdraw PWDR-ETH LP tokens and any pending PWDR rewards. 
    // There is a 10% unstaking fee, meaning the user will only receive 90% of their LP tokens back.
    
    // For the LP tokens kept by the unstaking fee, a % will get locked forever in the PWDR contract, and the rest will get converted to PWDR and distributed to stakers.
    //TODO -> change ratio to 75% convertion to rewards
    function withdraw(uint256 _amount)
        external
        override
    {
        _withdraw(_msgSender(), _amount);
    }

    function _withdraw(address _user, uint256 _amount) 
        internal
        NonZeroAmount(_amount)
        HasStakedBalance(_user)
        HasWithdrawableBalance(_user, _amount)
    {
        _updatePool();

        UserInfo storage user = userInfo[_user];
        
        uint256 unstakingFeeAmount = _amount.mul(unstakingFee).div(1000);
        uint256 remainingUserAmount = _amount.sub(unstakingFeeAmount);

        // Some of the LP tokens kept by the unstaking fee will be locked forever in the PWDR contract, 
        // the rest  will be converted to PWDR and distributed to stakers
        uint256 lpTokensToConvertToPwdr = unstakingFeeAmount.mul(buybackAmount).div(1000);
        uint256 lpTokensToLock = unstakingFeeAmount.sub(lpTokensToConvertToPwdr);

        // Remove the liquidity from the Uniswap PWDR-ETH pool and buy PWDR with the ETH received
        // The _transfer function in the PWDR.sol contract automatically calls avalanche.addPwdrRewards()
        if (lpTokensToConvertToPwdr > 0) {
            _removeLiquidityETH(
                lpTokensToConvertToPwdr,
                pwdrPoolAddress(),
                pwdrAddress()
            );
            if (address(this).balance > 0) {
                addEthReward();
            }
        }

        // Permanently lock the LP tokens in the PWDR contract
        if (lpTokensToLock > 0) {
            IERC20(pwdrPoolAddress()).safeTransfer(vaultAddress(), lpTokensToLock);
        }

        // Claim any pending PWDR
        _claim(_user);

        uint256 shares = ILoyalty(loyaltyAddress()).getTotalShares(_user, _amount);
        totalShares = totalShares.sub(shares);
        user.shares = user.shares.sub(shares);

        totalStaked = totalStaked.sub(_amount);
        user.staked = user.staked.sub(_amount);
        user.rewardDebt = user.shares.mul(accPwdrPerShare).div(1e12); // update reward debt after balance change

        IERC20(pwdrPoolAddress()).safeTransfer(_user, remainingUserAmount);
        emit Withdraw(_user, remainingUserAmount);
    }

    function payoutNumber() 
        public
        override
        view 
        returns (uint256) 
    {
        if (block.timestamp < startTime) {
            return 0;
        }

        return (block.timestamp - startTime).div(getDistributionPayoutInterval());
    }

    function timeUntilNextPayout()
        external
        override
        view 
        returns (uint256) 
    {
        if (epochPwdrReward == 0) {
            return 0;
        } else {
            uint256 payout = payoutNumber();
            uint256 nextPayout = startTime.add((payout + 1).mul(getDistributionPayoutInterval()));
            return nextPayout - block.timestamp;
        }
    }

    function rewardAtPayout(uint256 _payoutNumber) 
        public
        override
        view 
        returns (uint256) 
    {
        if (_payoutNumber == 0) {
            return 0;
        } else {
            return epochPwdrRewardPerDay * _payoutNumber;
        }
    }

    function getTotalDistributionPayouts() public virtual pure returns (uint256) {
        return TOTAL_PAYOUTS;
    }

    function getDistributionPayoutInterval() public virtual pure returns (uint256) {
        return PAYOUT_INTERVAL;
    }

    function updatePool()
        external
        HasPatrol("ADMIN")
    {
        _updatePool();
    }

    // Sets the unstaking fee. Can't be higher than 50%.
    // _convertToPwdrAmount is the % of the LP tokens from the unstaking fee that will be converted to PWDR and distributed to stakers.
    // unstakingFee - unstakingFeeConvertToPwdrAmount = The % of the LP tokens from the unstaking fee that will be permanently locked in the PWDR contract
    function setUnstakingFee(uint256 _unstakingFee, uint256 _buybackAmount) 
        external
        HasPatrol("ADMIN") 
    {
        require(_unstakingFee <= 500, "over 50%");
        require(_buybackAmount <= 1000, "bad amount");
        unstakingFee = _unstakingFee;
        buybackAmount = _buybackAmount;
    }

    // Function to recover ERC20 tokens accidentally sent to the contract.
    // PWDR and PWDR-ETH LP tokens (the only 2 ERC2O's that should be in this contract) can't be withdrawn this way.
    function recoverERC20(address _tokenAddress) 
        external
        HasPatrol("ADMIN") 
    {
        require(_tokenAddress != pwdrAddress() && _tokenAddress != pwdrPoolAddress());
        IERC20 token = IERC20(_tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, tokenBalance);
    }

     function getAvalancheStats(address _user) 
        external 
        view 
        returns (bool _active, bool _accumulating, uint256[20] memory _stats)
    {
        _active = active;
        _accumulating = IPWDR(pwdrAddress()).accumulating();
        
        UserInfo storage user = userInfo[_user];

        _stats[0] = weight * IPWDR(pwdrAddress()).currentBaseRate();
        _stats[1] = lastReward;
        _stats[2] = totalStaked;
        _stats[3] = totalShares;
        _stats[4] = accPwdrPerShare;
        _stats[5] = _getTokenPrice(pwdrAddress(), pwdrPoolAddress());
        _stats[6] = _getLpTokenPrice(pwdrPoolAddress());

        _stats[7] = nextEpochPwdrReward;
        _stats[8] = epochPwdrReward;
        _stats[9] = epochPwdrRewardPerDay;
        _stats[10] = startTime;
        _stats[11] = lastPayout; 
        _stats[12] = payoutNumber();
        _stats[13] = unstakingFee;

        _stats[14] = IERC20(pwdrPoolAddress()).balanceOf(_user);
        _stats[15] = IERC20(pwdrPoolAddress()).allowance(_user, address(this));
        _stats[16] = user.staked;
        _stats[17] = user.shares;
        _stats[18] = user.shares.mul(accPwdrPerShare).div(1e12).sub(user.rewardDebt); // pending rewards
        _stats[19] = user.claimed;
    }

    function setActive(bool _active)
        external
        HasPatrol("ADMIN")
    {
        active = _active;
    }

    function updateWeight(uint256 _weight)
        external
        HasPatrol("ADMIN")
    {
        weight = _weight;
    }
}
