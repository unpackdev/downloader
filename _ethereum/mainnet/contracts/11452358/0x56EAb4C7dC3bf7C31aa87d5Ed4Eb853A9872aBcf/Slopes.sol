// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./ERC20.sol";
import "./IPWDR.sol";
import "./IAvalanche.sol";
import "./ISlopes.sol";
import "./ILoyalty.sol";
import "./SlopesBase.sol"; 

contract Slopes is ISlopes, SlopesBase {
    event Activated(address indexed user);
    event Claim(address indexed user, uint256 indexed pid, uint256 pwdrAmount, uint256 tokenAmount);
    event ClaimAll(address indexed user, uint256 pwdrAmount, uint256[] tokenAmounts);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Migrate(address indexed user, uint256 amount);
    event PwdrPurchase(address indexed user, uint256 ethSpentOnPwdr, uint256 pwdrBought);

    uint256 internal constant DEFAULT_WEIGHT = 1;
    
    bool internal avalancheActive;
    bool public override active;
    uint256 public override pwdrSentToAvalanche;
    uint256 public override stakingFee; // 1 = 0.1%, default 10%
    uint256 public override roundRobinFee; // default to 500, 50% of staking Fee
    uint256 public override protocolFee; // default to 200, 20% of roundRobinFee
    
    modifier PoolActive(uint256 _pid) {
        require(poolInfo[_pid].active, "This Slope is inactive");
        _;
    }

    modifier AvalancheActive {
        require(IAvalanche(avalancheAddress()).active(), "Slopes are not active");
        _;
    }

    modifier SlopesActive {
        require(active, "Slopes are not active");
        _;
    }

    modifier SlopesNotActive {
        require(!active, "Slopes are not active");
        _;
    }
    
    constructor(address addressRegistry)
        public 
        SlopesBase(addressRegistry) 
    {
        stakingFee = 50; // 5% initial fee
        roundRobinFee = 500;
        protocolFee = 200;
    }

    receive() external payable {}

    function activate()
        external
        override
        OnlyLGE
        SlopesNotActive
    {
        active = true;
        _addInitialPools();
        emit Activated(_msgSender());
    }

    // Internal function that adds all of the pools that will be available at launch
    // enables flash loan lending on active pools
    function _addInitialPools() internal {
        _addPool(
            pwdrAddress(),
            pwdrPoolAddress(),
            true
        ); // PWDR-ETH LP
        
        _addPool(
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            false
        ); // WETH
        _addPool(
            0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
            0xBb2b8038a1640196FbE3e38816F3e67Cba72D940,
            false
        ); // WBTC
        _addPool(
            0xdAC17F958D2ee523a2206206994597C13D831ec7,
            0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852,
            false
        ); // USDT
        _addPool(
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc,
            false
        ); // USDC
        _addPool(
            0x6B175474E89094C44Da98b954EedeAC495271d0F,
            0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11,
            false
        ); // DAI

        _setLendingToken(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, true);
        _setLendingToken(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, true);
        _setLendingToken(0xdAC17F958D2ee523a2206206994597C13D831ec7, true);
        _setLendingToken(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, true);
        _setLendingToken(0x6B175474E89094C44Da98b954EedeAC495271d0F, true);
    }

    // Internal function to add a new LP Token pool
    function _addPool(
        address _token,
        address _lpToken,
        bool _lpStaked
    ) 
        internal
    {
        uint256 weight = DEFAULT_WEIGHT;
        if (_token == pwdrAddress()) {
            weight = weight * 5;
        }

        uint256 lastReward = block.timestamp;

        if (_lpStaked) {
            tokenPools[_lpToken] = poolInfo.length; 
        } else {
            tokenPools[_token] = poolInfo.length;
        }

        poolInfo.push(
            PoolInfo({
                active: true,
                token: _token,
                lpToken: _lpToken,
                lpStaked: _lpStaked,
                weight: weight,
                lastReward: lastReward,
                totalShares: 0,
                totalStaked: 0,
                accPwdrPerShare: 0,
                accTokenPerShare: 0
            })
        );
    }

    function updatePool(uint256 _pid) 
        external
        override
        HasPatrol("ADMIN")
    {
        _updatePool(_pid);
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool(uint256 _pid) 
        internal
        SlopesActive
    {
        PoolInfo storage pool = poolInfo[_pid];
        address pwdrAddress = pwdrAddress();

        if (block.timestamp <= pool.lastReward
            || (_pid == 0 && avalancheActive)) {
            return;
        }

        if (pool.totalStaked == 0) {
            pool.lastReward = block.timestamp;
            return;
        }

        // calculate pwdr rewards to mint for this epoch if accumulating,
        //  mint them to the contract for users to claim
        if (IPWDR(pwdrAddress).accumulating()) {
            // Calculate the current PWDR rewards for a specific pool
            //  using fixed APR formula and Uniswap price
            uint256 pwdrReward;
            uint256 tokenPrice;
            if (pool.lpStaked) {
                tokenPrice = _getLpTokenPrice(pool.lpToken);
                pwdrReward = _calculatePendingRewards(
                    pool.lastReward,
                    pool.totalShares,
                    tokenPrice,
                    pool.weight
                );
            } else {
                tokenPrice = _getTokenPrice(pool.token, pool.lpToken);
                uint256 adjuster = 18 - uint256(ERC20(pool.token).decimals());
                uint256 adjustedShares = pool.totalShares * (10**adjuster);

                pwdrReward = _calculatePendingRewards(
                    pool.lastReward,
                    adjustedShares,
                    tokenPrice,
                    pool.weight
                );
            }

            // if we hit the max supply here, ensure no overflow 
            //  epoch will be incremented from the token     
            uint256 pwdrTotalSupply = IERC20(pwdrAddress).totalSupply();
            if (pwdrTotalSupply.add(pwdrReward) >= IPWDR(pwdrAddress).currentMaxSupply()) {
                pwdrReward = IPWDR(pwdrAddress).currentMaxSupply().sub(pwdrTotalSupply);

                if (IPWDR(pwdrAddress).currentEpoch() == 1) {
                    poolInfo[0].active = false;
                    avalancheActive = true;
                } 
            }

            if (pwdrReward > 0) {
                // IPWDR(pwdrAddress).mint(address(this), pwdrReward + avalancheSeed);
                IPWDR(pwdrAddress).mint(address(this), pwdrReward);
                pool.accPwdrPerShare = pool.accPwdrPerShare.add(pwdrReward.mul(1e12).div(pool.totalShares));
                pool.lastReward = block.timestamp;
            }
        }
    }

    // Internal view function to get the actual amount of tokens staked in the specified pool
    function _getPoolSupply(uint256 _pid) 
        internal 
        view 
        returns (uint256 tokenSupply) 
    {
        if (poolInfo[_pid].lpStaked) {
            tokenSupply = IERC20(poolInfo[_pid].lpToken).balanceOf(address(this));
        } else {
            tokenSupply = IERC20(poolInfo[_pid].token).balanceOf(address(this));  
        }
    }

    // Deposits tokens in the specified pool to start earning the user PWDR
    function deposit(uint256 _pid, uint256 _amount) 
        external
        override
    {
        _deposit(_pid, msg.sender, _amount);
    }
    
    // internal deposit function, 
    function _deposit(
        uint256 _pid, 
        address _user, 
        uint256 _amount
    ) 
        internal
        NonZeroAmount(_amount)
        SlopesActive
        PoolActive(_pid)
    {
        // Accept deposit
        if (poolInfo[_pid].lpStaked) {
            IERC20(poolInfo[_pid].lpToken).safeTransferFrom(_user, address(this), _amount);
        } else {
            IERC20(poolInfo[_pid].token).safeTransferFrom(_user, address(this), _amount);
        }

        _updatePool(_pid);

        // Claim any pending PWDR and Token Rewards
        _claim(_pid, _user);

        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        
        // Calculate fees
        uint256 stakingFeeAmount = _amount.mul(stakingFee).div(1000);
        uint256 remainingUserAmount = _amount.sub(stakingFeeAmount);

        //  get the user shares, virtual staked balance given by nft bonus
        //      1:1 token amount if no bonus
        uint256 userPoolShares = ILoyalty(loyaltyAddress()).getTotalShares(_user, remainingUserAmount);
        
        if (_pid == 0) {
            // The user is depositing to the PWDR-ETH, send liquidity to vault
            _safeTokenTransfer(
                pool.lpToken,
                vaultAddress(),
                stakingFeeAmount
            );
        } else {
            uint256 roundRobinAmount = stakingFeeAmount.mul(roundRobinFee).div(1000);
            uint256 protocolAmount = roundRobinAmount.mul(protocolFee).div(1000);

            // do the PWDR buyback, route tx result directly to avalanche
            uint256 pwdrBought;
            if (pool.lpStaked) {
                uint256 ethReceived = address(this).balance;
                uint256 tokensReceived = IERC20(pool.token).balanceOf(address(this));
                _removeLiquidityETH(
                    stakingFeeAmount.sub(roundRobinAmount),
                    pool.lpToken,
                    pool.token
                );
                ethReceived = address(this).balance.sub(ethReceived); // update for rewards
                tokensReceived = IERC20(pool.token).balanceOf(address(this)).sub(tokensReceived); // update token rewards
                ethReceived = ethReceived.add(_swapExactTokensForETH(tokensReceived, pool.token));
                if (ethReceived > 0) {
                    pwdrBought = _swapExactETHForTokens(ethReceived, pwdrAddress());
                }
            } else {
                if (pool.token == wethAddress()) {
                    _unwrapETH(stakingFeeAmount.sub(roundRobinAmount));
                    pwdrBought = _swapExactETHForTokens(stakingFeeAmount.sub(roundRobinAmount), pwdrAddress());
                } else {
                    uint256 ethReceived = _swapExactTokensForETH(stakingFeeAmount.sub(roundRobinAmount), pool.token);
                    if (ethReceived > 0) {
                        pwdrBought = _swapExactETHForTokens(ethReceived, pwdrAddress());
                    }
                }
            }
            // emit event, 
            if (pwdrBought > 0) {
                pwdrSentToAvalanche += pwdrBought;
                _safeTokenTransfer(
                    pwdrAddress(),
                    avalancheAddress(),
                    pwdrBought
                );
                emit PwdrPurchase(msg.sender, _amount, pwdrBought);
            }
            
            // apply round robin fee
            uint256 poolSupply = _getPoolSupply(_pid);
            pool.accTokenPerShare = pool.accTokenPerShare.add(roundRobinAmount.sub(protocolAmount).mul(1e12).div(poolSupply));

            if (protocolAmount > 0) {
                IERC20(pool.token).safeTransfer(treasuryAddress(), protocolAmount);
            }
        }

        // Add tokens to user balance, update reward debts to reflect the deposit
        //   bonus rewards only apply to PWDR, so use shares for pwdr debt and staked for token debt
        uint256 _currentRewardDebt = user.shares.mul(pool.accPwdrPerShare).div(1e12).sub(user.rewardDebt);
        uint256 _currentTokenRewardDebt = user.staked.mul(pool.accTokenPerShare).div(1e12).sub(user.tokenRewardDebt);

        user.staked = user.staked.add(remainingUserAmount);
        user.shares = user.shares.add(userPoolShares);
        pool.totalStaked = pool.totalStaked.add(remainingUserAmount);
        pool.totalShares = pool.totalShares.add(userPoolShares);

        user.rewardDebt = user.shares.mul(pool.accPwdrPerShare).div(1e12).sub(_currentRewardDebt);
        user.tokenRewardDebt = user.staked.mul(pool.accTokenPerShare).div(1e12).sub(_currentTokenRewardDebt);

        emit Deposit(_user, _pid, _amount);
    }

    // Claim all earned PWDR and token rewards from a single pool.
    function claim(uint256 _pid) 
        external
        override
    {
        _updatePool(_pid);
        _claim(_pid, msg.sender);
    }

    
    // Internal function to claim earned PWDR and tokens from slopes
    function _claim(uint256 _pid, address _user) 
        internal
        SlopesActive
    {
        if (userInfo[_pid][_user].staked == 0) {
            return;
        }
        
        // calculate the pending pwdr rewards using virtual user shares
        uint256 userPwdrPending = userInfo[_pid][_user].shares.mul(poolInfo[_pid].accPwdrPerShare).div(1e12).sub(userInfo[_pid][_user].rewardDebt);
        if (userPwdrPending > 0) {
            userInfo[_pid][_user].claimed = userInfo[_pid][_user].claimed.add(userPwdrPending);
            userInfo[_pid][_user].rewardDebt = userInfo[_pid][_user].shares.mul(poolInfo[_pid].accPwdrPerShare).div(1e12);

            _safeTokenTransfer(
                pwdrAddress(),
                _user,
                userPwdrPending
            );
        }

        // calculate the pending token rewards, use actual user stake
        // rewards will be denoted in token decimals, not 1e18
        uint256 userTokenPending = userInfo[_pid][_user].staked.mul(poolInfo[_pid].accTokenPerShare).div(1e12).sub(userInfo[_pid][_user].tokenRewardDebt);
        if (userTokenPending > 0) {
            userInfo[_pid][_user].tokenClaimed = userInfo[_pid][_user].tokenClaimed.add(userTokenPending);
            userInfo[_pid][_user].tokenRewardDebt = userInfo[_pid][_user].staked.mul(poolInfo[_pid].accTokenPerShare).div(1e12);

            if (poolInfo[_pid].lpStaked) {
                _safeTokenTransfer(
                    poolInfo[_pid].lpToken,
                    _user,
                    userTokenPending
                );
            } else {
                _safeTokenTransfer(
                    poolInfo[_pid].token,
                    _user,
                    userTokenPending
                );
            }
            
        }

        if (userPwdrPending > 0 || userTokenPending > 0) {
            emit Claim(_user, _pid, userPwdrPending, userTokenPending);
        }
    }

    // external function to claim all rewards
    function claimAll()
        external
        override
    {
        _claimAll(msg.sender);
    }

    // loyalty contract calls this function to claim rewards for user
    //   before gaining NFT boosts to prevent retroactive/postmortem rewards
    function claimAllFor(address _user)
        external
        override
        OnlyLoyalty
    {
        _claimAll(_user);
    }

    // Claim all earned PWDR and Tokens from all pools,
    //   reset share value after claim
    function _claimAll(address _user) 
        internal
        SlopesActive
    {
        uint256 totalPendingPwdrAmount = 0;
        
        uint256 length = poolInfo.length;
        uint256[] memory amounts = new uint256[](length);
        for (uint256 pid = 0; pid < length; pid++) {
            if (userInfo[pid][_user].staked > 0) {
                _updatePool(pid);

                UserInfo storage user = userInfo[pid][_user];
                PoolInfo storage pool = poolInfo[pid];

                uint256 accPwdrPerShare = pool.accPwdrPerShare;
                uint256 pendingPoolPwdrRewards = user.shares.mul(accPwdrPerShare).div(1e12).sub(user.rewardDebt);
                user.claimed += pendingPoolPwdrRewards;
                totalPendingPwdrAmount = totalPendingPwdrAmount.add(pendingPoolPwdrRewards);
                user.rewardDebt = user.shares.mul(accPwdrPerShare).div(1e12);

                // update user shares to reset bonuses, only necessary in claimAll 
                uint256 shares = ILoyalty(loyaltyAddress()).getTotalShares(_user, user.staked);
                if (shares > user.shares) {
                    pool.totalShares = pool.totalShares.add(shares.sub(user.shares));
                } else if (shares < user.shares) {
                    pool.totalShares = pool.totalShares.sub(user.shares.sub(shares));
                }
                user.shares = shares;

                // claim any token reward debt, use actual staked balance
                if (pid != 0) {
                    address tokenAddress = pool.token;
                    uint256 accTokenPerShare = pool.accTokenPerShare;

                    // need to double check math on this for 1e6 tokens like USDC
                    uint256 pendingPoolTokenRewards = user.staked.mul(accTokenPerShare).div(1e12).sub(user.tokenRewardDebt);
                    user.tokenClaimed = user.tokenClaimed.add(pendingPoolTokenRewards);
                    // totalPendingWETHAmount = totalPendingWETHAmount.add(pendingPoolWETHRewards);
                    user.tokenRewardDebt = user.staked.mul(accTokenPerShare).div(1e12);
                    
                    // claim token rewards
                    if (pendingPoolTokenRewards > 0) {
                        _safeTokenTransfer(tokenAddress, _user, pendingPoolTokenRewards);
                        amounts[pid] = pendingPoolTokenRewards;
                    }
                }
            }
        }

        // claim PWDR rewards
        if (totalPendingPwdrAmount > 0) {
            _safeTokenTransfer(
                pwdrAddress(),
                _user,
                totalPendingPwdrAmount
            );
        }

        emit ClaimAll(_user, totalPendingPwdrAmount, amounts);
    }

    // Withdraw LP tokens and earned PWDR from Accumulation. 
    // Withdrawing won't work until pwdrPoolActive == true
    function withdraw(uint256 _pid, uint256 _amount)
        external
        override
    {
        _withdraw(_pid, _amount, msg.sender);
    }

    function _withdraw(uint256 _pid, uint256 _amount, address _user) 
        internal
        SlopesActive
        NonZeroAmount(_amount)
        HasStakedBalance(_pid, _user)
    {
        _updatePool(_pid);

        // Claim any pending PWDR and Tokens
        _claim(_pid, _user);

        UserInfo storage user = userInfo[_pid][_user];
        PoolInfo memory pool = poolInfo[_pid];

        uint256 shares = ILoyalty(loyaltyAddress()).getTotalShares(_user, _amount);
        pool.totalShares = pool.totalShares.sub(shares);
        user.shares = user.shares.sub(shares);

        pool.totalStaked = pool.totalStaked.sub(_amount);
        user.staked = user.staked.sub(_amount);
        user.rewardDebt = user.shares.mul(pool.accPwdrPerShare).div(1e12); // users pwdr debt by shares
        user.tokenRewardDebt = user.staked.mul(pool.accTokenPerShare).div(1e12); // taken in terms of tokens, not affected by boosts

        if (poolInfo[_pid].lpStaked) {
            _safeTokenTransfer(pool.lpToken, _user, _amount);
        } else {
            _safeTokenTransfer(pool.token, _user, _amount);
        }

        emit Withdraw(_user, _pid, _amount);
    }

    // Convenience function to allow users to migrate all of their staked PWDR-ETH LP tokens 
    // from Accumulation to the Avalanche staking contract after the max supply is hit.
    function migrate() 
        external
        override
        AvalancheActive
        HasStakedBalance(0, msg.sender)
    {
        _updatePool(0);

        _claim(0, msg.sender);

        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        
        uint256 amountToMigrate = user.staked;
        address avalancheAddress = avalancheAddress();

        pool.totalShares = pool.totalShares.sub(user.shares);
        pool.totalStaked = pool.totalStaked.sub(user.staked);

        user.shares = 0;
        user.staked = 0;
        user.rewardDebt = 0;

        IERC20(pool.lpToken).safeApprove(avalancheAddress, 0);
        IERC20(pool.lpToken).safeApprove(avalancheAddress, amountToMigrate);
        IAvalanche(avalancheAddress).depositFor(address(this), msg.sender, amountToMigrate);

        emit Migrate(msg.sender, amountToMigrate);
    }

    function poolLength() 
        external
        override
        view 
        returns (uint256)
    {
        return poolInfo.length;
    }
    
    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() 
        external
        override
    {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; pid++) {
            _updatePool(pid);
        }
    }

    // Add a new LP Token pool
    function addPool(
        address _token, 
        address _lpToken, 
        bool _lpStaked,
        uint256 _weight
    ) 
        external
        override 
        HasPatrol("ADMIN")
    {
        _addPool(_token, _lpToken, _lpStaked);

        if (_weight != DEFAULT_WEIGHT) {
            poolInfo[poolInfo.length-1].weight = _weight;
        } 
    }

    // Update the given pool's APR
    function setWeight(uint256 _pid, uint256 _weight)
        external
        override
        HasPatrol("ADMIN")
    {
        _updatePool(_pid);
        poolInfo[_pid].weight = _weight;
    }

    function setActive(uint256 _pid, bool _active)
        external
        HasPatrol("ADMIN")
    {
        _updatePool(_pid);
        poolInfo[_pid].active = _active;
    }

    function getSlopesStats(address _user)
        external
        view
        returns (bool _active, bool _accumulating, uint[20][] memory _stats)
    {
        _active = active;
        _accumulating = IPWDR(pwdrAddress()).accumulating();
        _stats = new uint[20][](poolInfo.length);

        for (uint i = 0; i < poolInfo.length; i++) {
            _stats[i] = getPoolStats(_user, i);
        }
    }

    function getPoolStats(address _user, uint256 _pid)
        public
        view
        returns (uint[20] memory _pool)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        _pool[0] = pool.active ? 1 : 0;
        _pool[1] = pool.weight * IPWDR(pwdrAddress()).currentBaseRate();
        _pool[2] = pool.lastReward;
        _pool[3] = pool.totalShares;
        _pool[4] = pool.totalStaked;
        _pool[5] = pool.accPwdrPerShare;
        _pool[6] = pool.accTokenPerShare;
        _pool[7] = _getTokenPrice(pool.token, pool.lpToken);
        _pool[8] = _getLpTokenPrice(pool.lpToken);
        _pool[9] = stakingFee;
        _pool[10] = IERC20(pool.token).balanceOf(_user);
        _pool[11] = IERC20(pool.token).allowance(_user, address(this));
        _pool[12] = IERC20(pool.lpToken).balanceOf(_user);
        _pool[13] = IERC20(pool.lpToken).allowance(_user, address(this));
        _pool[14] = user.staked;
        _pool[15] = user.shares;
        _pool[16] = user.shares.mul(pool.accPwdrPerShare).div(1e12).sub(user.rewardDebt); // pending pwdr rewards
        _pool[17] = user.staked.mul(pool.accTokenPerShare).div(1e12).sub(user.tokenRewardDebt); // pending token rewards
        _pool[18] = user.claimed;
        _pool[19] = user.tokenClaimed;
    }
}