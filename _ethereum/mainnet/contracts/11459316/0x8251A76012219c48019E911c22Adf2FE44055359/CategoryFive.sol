// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./IUniswap.sol";
import "./IWETH.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./FeeHelpers.sol";
import "./Cane.sol";
import "./Hugo.sol";


// File: contracts/CategoryFive.sol

contract CategoryFive is ReentrancyGuard, Ownable {
 
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    event Staked(address indexed from, uint256 amount, uint256 amountLP);
    event Withdrawn(address indexed to, uint256 poolId, uint256 amount, uint256 amountLP);
    event Claimed(address indexed to, uint256 poolId, uint256 amount);
    event ClaimedAndStaked(address indexed to, uint256 poolId, uint256 amount);
    event Halving(uint256 amount);
    event Received(address indexed from, uint256 amount);
    event EmergencyWithdraw(address indexed to, uint256 poolId, uint256 amount);
    event ClaimedLPReward(address indexed to, uint256 poolId, uint256 lpEthReward, uint256 lpCaneReward);

    Cane public cane; // Hurricane farming token
    Hugo public hugo; // Hurricane governance token

    IUniswapV2Factory public factory;
    IUniswapV2Router02 public router;
    address public weth;
    address payable public treasury;
    bool public treasuryDisabled = false;

    struct AccountInfo {
        uint256 index;
        uint256 balance;
        uint256 maxBalance;
        uint256 lastWithdrawTimestamp;
        uint256 lastStakedTimestamp;
        uint256 reward;
        uint256 rewardPerTokenPaid;
        uint256 lpEthReward;
        uint256 lpEthRewardPaid;
        uint256 lpCaneReward;
        uint256 lpCaneRewardPaid;
    }
    struct PoolInfo {
        IERC20 pairAddress; // Address of LP token contract
        IERC20 otherToken; // Reference to other token in pair (e.g. 'weth')
        uint256 rewardAllocation; // Rewards allocated for this pool
        uint256 totalSupply; // Total supply of tokens in pool
        uint256 borrowedSupply; // Total CANE token borrowed for pool
        uint256 rewardPerTokenStored; // Rewards per token in this pool
    }
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => AccountInfo)) public accountInfos;
    // List for supporting accountInfos interation
    mapping(uint256 => address payable[]) public accountInfosIndex;

    struct Airgrabber {
        uint256 ethAmount; // Amount of ETH due
        uint256 caneAmount; // Amount of CANE due
        bool ethClaimed; // Track eth claim status
        bool caneClaimed; // Track claimed CANE
    }
    mapping(address => Airgrabber) public airgrabbers;

    uint256 public constant HALVING_DURATION = 14 days;
    uint256 public rewardAllocation = 5000 * 10 ** 18;
    uint256 public halvingTimestamp = 0;
    uint256 public lastUpdateTimestamp = 0;

    uint256 public rewardRate = 0;

    // configurable parameters via gov voting (days 30+ parameters only)
    uint256 public rewardHalvingPercent = 50;
    uint256 public claimBurnFee = 1;
    uint256 public claimTreasuryFeePercent = 2;
    uint256 public claimLPFeePercent = 2;
    uint256 public claimLiquidBalancePercent = 95;
    uint256 public unstakeLPFeePercent = 2;
    uint256 public unstakeTreasuryFeePercent = 2;
    uint256 public unstakeBurnFeePercent = 1;
    uint256 public withdrawalLimitPercent = 20;
    uint256 public katrinaExitFeePercent = 3;

    // Goal is for farming to be started as early as this timestamp
    // Date and time (GMT): Tuesday, December 15, 2020 7:00 PM UTC
    uint256 public farmingStartTimestamp = 1608058800;
    bool public farmingStarted = false;

    // References to our 2 core pools
    uint256 private constant HUGO_POOL_ID = 0;
    uint256 private constant KATRINA_POOL_ID = 1;

    // Burn address
    address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // Uniswap Router Address
    address constant ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // Prevent big buys for first few mins after farming starts
    uint256 public constant NOBUY_DURATION = 5 minutes;

    constructor(address payable _treasury) public {
        cane = new Cane(address(this), farmingStartTimestamp.add(NOBUY_DURATION));
        hugo = new Hugo(address(this));

        router = IUniswapV2Router02(ROUTER_ADDRESS);
        factory = IUniswapV2Factory(router.factory());
        weth = router.WETH();
        treasury = _treasury;

        IERC20(cane).safeApprove(address(router), uint256(-1));

        // Calc initial reward rate
        rewardRate = rewardAllocation.div(HALVING_DURATION);

        // Initialize CANE staking pool w/ 30% of rewards at launch
        // New allocations can be set dynamically via governance
        poolInfo.push(PoolInfo({
            pairAddress: cane,
            otherToken: cane,
            rewardAllocation: rewardAllocation.mul(30).div(100),
            borrowedSupply: 0,
            totalSupply: 0,
            rewardPerTokenStored: 0
        }));

        // Initialize Katrina liquidity pool w/ 70% of rewards at launch
        // New allocations can be set dynamically via governance
        poolInfo.push(PoolInfo({
            pairAddress: IERC20(factory.createPair(address(cane), weth)),
            otherToken: IERC20(weth),
            rewardAllocation: rewardAllocation.mul(70).div(100),
            borrowedSupply: 0,
            totalSupply: 0,
            rewardPerTokenStored: 0
        }));
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function stakeToHugo(uint256 _amount, bool _claimAndStakeRewards) public nonReentrant {
        _checkFarming();
        _updateReward(HUGO_POOL_ID);
        _halving(HUGO_POOL_ID);

        // Retrieve pool & account Info
        PoolInfo storage pool = poolInfo[HUGO_POOL_ID];
        AccountInfo storage account = accountInfos[HUGO_POOL_ID][msg.sender];

        // find user rewards due in each pool and auto claim
        if (_claimAndStakeRewards) {
            uint256 rewardsDue = account.reward; // current reward due in Hugo
            for (uint256 pid = 1; pid < poolInfo.length; pid++) {
                if (accountInfos[pid][msg.sender].reward > 0) {
                    rewardsDue = rewardsDue.add(accountInfos[pid][msg.sender].reward);
                    accountInfos[pid][msg.sender].reward = 0;
                }
            }

            if (rewardsDue > 0) { // transfer to Hugo staking pool directly without any fees
                // mint rewards directly to pool, plus send equiv Hugo gov tokens to user
                cane.mint(address(this), rewardsDue);
                hugo.mint(msg.sender, rewardsDue);

                emit ClaimedAndStaked(msg.sender, HUGO_POOL_ID, rewardsDue);

                account.balance = account.balance.add(rewardsDue);
                // Track to always allow full withdrawals against withdrawalLimit
                if (account.balance > account.maxBalance) {
                    account.maxBalance = account.balance;
                }
                account.lastStakedTimestamp = block.timestamp;
                if (account.index == 0) {
                    accountInfosIndex[HUGO_POOL_ID].push(msg.sender);
                    account.index = accountInfosIndex[HUGO_POOL_ID].length;
                }

                pool.totalSupply = pool.totalSupply.add(rewardsDue);

                if (account.reward > 0) {
                    account.reward = 0;
                }
            }
        }

        if (_amount > 0) { // allows staking only rewards to Hugo
            require(cane.balanceOf(msg.sender) >= _amount, 'Invalid balance');
            cane.transferFrom(msg.sender, address(this), _amount);

            // Add balance to pool's total supply
            pool.totalSupply = pool.totalSupply.add(_amount);

            // Add to iterator tracker if not exists
            account.balance = account.balance.add(_amount);
            // Track to always allow full withdrawals against withdrawalLimit
            if (account.balance > account.maxBalance) {
                account.maxBalance = account.balance;
            }
            account.lastStakedTimestamp = block.timestamp;
            
            if (account.index == 0) {
                accountInfosIndex[HUGO_POOL_ID].push(msg.sender);
                account.index = accountInfosIndex[HUGO_POOL_ID].length;
            }

            // Mint equivalent number of our gov token for user
            hugo.mint(msg.sender, _amount);

            emit Staked(msg.sender, _amount, 0);
        }
    }

    function stake(uint256 _poolId, uint256 _amount, address payable sender) external payable nonReentrant {
        _checkFarming();
        _updateReward(_poolId);
        _halving(_poolId);

        if (_poolId == KATRINA_POOL_ID) {
            _amount = msg.value;
        }

        require(_amount > 0, 'Invalid amount');
        require(!address(msg.sender).isContract() || address(msg.sender) == address(this), 'Invalid user');

        require(_poolId < poolInfo.length, 'Invalid pool');
        require(_poolId > HUGO_POOL_ID, 'Stake in Hugo');

        if (address(msg.sender) != address(this)) {
            sender = msg.sender;
        }

        PoolInfo storage pool = poolInfo[_poolId];
        AccountInfo storage account = accountInfos[_poolId][sender];

        // Use 2% of deposit sent to purchase CANE
        uint256 boughtCane = 0;
        if (pool.totalSupply > 0 && 
            farmingStartTimestamp.add(NOBUY_DURATION) <= block.timestamp && 
            _poolId == KATRINA_POOL_ID) {
            address[] memory swapPath = new address[](2);
            swapPath[0] = address(pool.otherToken);
            swapPath[1] = address(cane);
            IERC20(pool.otherToken).safeApprove(address(router), 0);
            IERC20(pool.otherToken).safeApprove(address(router), _amount.div(50));
            uint256[] memory amounts = router.swapExactETHForTokens{ value: _amount.div(50) }
                (uint(0), swapPath, address(this), block.timestamp + 1 days);
            
            boughtCane = amounts[amounts.length - 1];
            _amount = _amount.sub(_amount.div(50));
        }

        uint256 caneTokenAmount = IERC20(cane).balanceOf(address(pool.pairAddress));
        uint256 otherTokenAmount = IERC20(pool.otherToken).balanceOf(address(pool.pairAddress));
        
        // If otherTokenAmount = 0 then set initial price to 1 ETH = 1 CANE
        uint256 amountCaneTokenDesired = 0;
        if (_poolId == KATRINA_POOL_ID) {
            amountCaneTokenDesired = (otherTokenAmount == 0) ? 
                _amount * 1 : _amount.mul(caneTokenAmount).div(otherTokenAmount);
        } else {
            require(otherTokenAmount > 0, "Pool not started"); // require manual add for new LPs
            amountCaneTokenDesired = _amount.mul(caneTokenAmount).div(otherTokenAmount);
        }

        // Mint borrowed cane and update borrowed amount in pool
        cane.mint(address(this), amountCaneTokenDesired.sub(boughtCane));
        pool.borrowedSupply = pool.borrowedSupply.add(amountCaneTokenDesired);

        // Add liquidity in uniswap
        IERC20(cane).approve(address(router), amountCaneTokenDesired);
        
        uint256 liquidity;
        if (_poolId == KATRINA_POOL_ID) { // use addLiquidityETH
            (,, liquidity) = router.addLiquidityETH{value : _amount}(
                address(cane), amountCaneTokenDesired, 0, 0, address(this), block.timestamp + 1 days);
        } else { // use addLiquidity for token/cane liquidity
            IERC20(pool.otherToken).approve(address(router), _amount);
            (,, liquidity) = router.addLiquidity(
                address(pool.otherToken), address(cane), 
                _amount, amountCaneTokenDesired, 0, 0, address(this), block.timestamp + 1 days);
        }

        // Add LP token to total supply
        pool.totalSupply = pool.totalSupply.add(liquidity);

        // Add to balance and iterator tracker if not exists
        account.balance = account.balance.add(liquidity);
        // Track to always allow full withdrawals against withdrawalLimit
        if (account.balance > account.maxBalance) {
            account.maxBalance = account.balance;
        }
        if (account.index == 0) {
            accountInfosIndex[_poolId].push(sender);
            account.index = accountInfosIndex[_poolId].length;
        }

        // Set stake timestamp as last withdraw timestamp
        // to prevent withdraw immediately after first staking
        account.lastStakedTimestamp = block.timestamp;
        if (account.lastWithdrawTimestamp == 0) {
            account.lastWithdrawTimestamp = block.timestamp;
        }

        emit Staked(sender, _amount, liquidity);
    }

    function withdraw(uint256 _poolId) external nonReentrant {
        _checkFarming();
        _updateReward(_poolId);
        _halving(_poolId);

        require(_poolId < poolInfo.length, 'Invalid pool');

        // Retrieve account in pool
        PoolInfo storage pool = poolInfo[_poolId];
        AccountInfo storage account = accountInfos[_poolId][msg.sender];

        require(account.lastWithdrawTimestamp + 12 hours <= block.timestamp, 'Invalid withdraw time');
        require(account.balance > 0, 'Invalid balance');

        uint256 _amount = account.maxBalance.mul(withdrawalLimitPercent).div(100);
        if (account.balance < _amount) {
            _amount = account.balance;
        }

        // Reduce total supply in pool
        pool.totalSupply = pool.totalSupply.sub(_amount);
        // Reduce user's balance
        account.balance = account.balance.sub(_amount);
        // Update user's withdraw timestamp
        account.lastWithdrawTimestamp = block.timestamp;

        uint256[] memory totalToken = new uint256[](2);

        uint256 otherTokenAmountMinusFees = 0;

        if (_poolId == HUGO_POOL_ID) { // burn Hugo
            totalToken[1] = _amount;
            hugo.burn(msg.sender, _amount);

            uint256 burnFee = _amount.div(FeeHelpers.getUnstakeBurnFee(account.lastStakedTimestamp, unstakeBurnFeePercent)); // calculate fee
            cane.burn(BURN_ADDRESS, burnFee);
            otherTokenAmountMinusFees = _amount.sub(burnFee);
        } else { // Remove liquidity in uniswap
            IERC20(pool.pairAddress).approve(address(router), _amount);
            if (_poolId == KATRINA_POOL_ID) {
                (uint256 caneTokenAmount, uint256 otherTokenAmount) = router.removeLiquidityETH(address(cane), _amount, 0, 0, address(this), block.timestamp + 1 days);
                totalToken[0] = caneTokenAmount;
                totalToken[1] = otherTokenAmount;
            } else {
                (uint256 caneTokenAmount, uint256 otherTokenAmount) = router.removeLiquidity(address(cane), address(pool.otherToken), _amount, 0, 0, address(this), block.timestamp + 1 days);
                totalToken[0] = caneTokenAmount;
                totalToken[1] = otherTokenAmount;
            }

            // Burn borrowed cane and update count
            cane.burn(address(this), totalToken[0]);
            pool.borrowedSupply = pool.borrowedSupply.sub(totalToken[0]);
        }

        // Calculate and transfer withdrawal fee to treasury
        uint256 treasuryFee = 0;
        if (_poolId == KATRINA_POOL_ID) {
            treasuryFee = FeeHelpers.getKatrinaExitFee(katrinaExitFeePercent);
            treasuryFee = totalToken[1].div(treasuryFee);
            treasury.transfer(treasuryFee);
        } else {
            treasuryFee = FeeHelpers.getUnstakeTreasuryFee(account.lastStakedTimestamp, unstakeTreasuryFeePercent);
            treasuryFee = totalToken[1].div(treasuryFee);
            pool.otherToken.transfer(treasury, treasuryFee);
        }
        
        if (_poolId == HUGO_POOL_ID) {
            otherTokenAmountMinusFees = otherTokenAmountMinusFees.sub(treasuryFee);
        } else {
            otherTokenAmountMinusFees = totalToken[1].sub(treasuryFee);
        }
        
        // Calculate and transfer withdrawal fee for distribution to other LPs
        if (accountInfosIndex[_poolId].length > 0 && pool.totalSupply > 0) {
            uint256 lpFee = 0;
            if (_poolId == KATRINA_POOL_ID) {
                lpFee = FeeHelpers.getKatrinaExitFee(katrinaExitFeePercent);
            } else {
                lpFee = FeeHelpers.getUnstakeLPFee(account.lastStakedTimestamp, unstakeLPFeePercent);
            }

            lpFee = totalToken[1].div(lpFee);
            for (uint256 i = 0; i < accountInfosIndex[_poolId].length; i ++) {
                AccountInfo storage lpAccount = accountInfos[_poolId][accountInfosIndex[_poolId][i]];
                // Send portion of fee and track amounts if we have an LP balance and is not sender
                if (lpAccount.balance > 0 && accountInfosIndex[_poolId][i] != msg.sender) {
                    if (_poolId == KATRINA_POOL_ID) {
                        lpAccount.lpEthReward = lpAccount.lpEthReward.add(lpAccount.balance.mul(lpFee).div(pool.totalSupply));
                    } else {
                        lpAccount.lpCaneReward = lpAccount.lpCaneReward.add(lpAccount.balance.mul(lpFee).div(pool.totalSupply));
                    }
                }
            }
            otherTokenAmountMinusFees = otherTokenAmountMinusFees.sub(lpFee);
        }

        totalToken[1] = otherTokenAmountMinusFees;

        if (_poolId == KATRINA_POOL_ID) {
            msg.sender.transfer(totalToken[1]);
        } else {
            pool.otherToken.transfer(msg.sender, totalToken[1]);
        }

        // Remove from list if balance is zero
        if (account.balance == 0 && account.index > 0 && account.index <= accountInfosIndex[_poolId].length) {
            uint256 accountIndex = account.index - 1; // Fetch real index in array
            accountInfos[_poolId][accountInfosIndex[_poolId][accountInfosIndex[_poolId].length - 1]].index = accountIndex + 1; // Give it my index
            accountInfosIndex[_poolId][accountIndex] = accountInfosIndex[_poolId][accountInfosIndex[_poolId].length - 1]; // Give it my address
            accountInfosIndex[_poolId].pop();
            account.index = 0; // Keep struct ref valid, but remove from tracking list of active LPs
        }

        emit Withdrawn(msg.sender, _poolId, _amount, totalToken[1]);
    }

    // Claim functions for extracting pool rewards
    function claim(uint256 _poolId) external nonReentrant {
        _checkFarming();
        _updateReward(_poolId);
        _halving(_poolId);

        require(_poolId < poolInfo.length, 'Invalid pool');

        // Retrieve account in pool
        PoolInfo storage pool = poolInfo[_poolId];
        AccountInfo storage account = accountInfos[_poolId][msg.sender];
        
        uint256 reward = account.reward;

        require(reward > 0, 'No rewards');

        if (reward > 0) {
            // Reduce rewards due
            account.reward = 0;
            // Apply variable % burn fee
            cane.mint(BURN_ADDRESS, reward.div(FeeHelpers.getClaimBurnFee(account.lastStakedTimestamp, claimBurnFee)));
            // Extract liquid qty and send liquid to user wallet
            cane.mint(msg.sender, reward.div(FeeHelpers.getClaimLiquidBalancePcnt(account.lastStakedTimestamp, claimLiquidBalancePercent)));
            // Extract treasury fee and send
            cane.mint(address(treasury), reward.div(FeeHelpers.getClaimTreasuryFee(account.lastStakedTimestamp, claimTreasuryFeePercent)));

            // Extract LPs fees amount and distribute
            if (accountInfosIndex[_poolId].length > 0 && pool.totalSupply > 0) {
                for (uint256 i = 0; i < accountInfosIndex[_poolId].length; i ++) {
                    AccountInfo storage lpAccount = accountInfos[_poolId][accountInfosIndex[_poolId][i]];
                    // Send portion of fee and track amounts if we have an LP balance and is not sender
                    if (lpAccount.balance > 0 && accountInfosIndex[_poolId][i] != msg.sender) {
                        lpAccount.lpCaneReward = lpAccount.lpCaneReward.add(lpAccount.balance
                            .mul(reward.div(FeeHelpers.getClaimLPFee(account.lastStakedTimestamp, claimLPFeePercent)))
                            .div(pool.totalSupply));
                    }
                }
            }

            // Remove liquid and treasury/lp/burn fees, then remainder goes back to LP
            uint256[] memory rewardAmounts = new uint256[](2);
            rewardAmounts[0] = reward
                .sub(reward.div(FeeHelpers.getClaimBurnFee(account.lastStakedTimestamp, claimBurnFee)))
                .sub(reward.div(FeeHelpers.getClaimLiquidBalancePcnt(account.lastStakedTimestamp, claimLiquidBalancePercent)))
                .sub(reward.div(FeeHelpers.getClaimTreasuryFee(account.lastStakedTimestamp, claimTreasuryFeePercent)))
                .sub(reward.div(FeeHelpers.getClaimLPFee(account.lastStakedTimestamp, claimLPFeePercent)));
            rewardAmounts[1] = rewardAmounts[0].div(2);
            // Mint [ALL] the qty of tokens needed to buy ETH and add LP
            cane.mint(address(this), rewardAmounts[0]);
            // Build swap pair from token to token (eg: WETH)
            address[] memory swapPath = new address[](2);
            swapPath[0] = address(cane);
            swapPath[1] = address(weth);
            // Sell minted half for ETH equivalent
            IERC20(cane).safeApprove(address(router), 0);
            IERC20(cane).safeApprove(address(router), rewardAmounts[1]);
            uint256[] memory swappedTokens = router.swapExactTokensForETH(rewardAmounts[1], uint(0), swapPath, address(this), block.timestamp + 1 days);
            // Use other minted half for CANE part, add to lp
            uint256[] memory totalLp = new uint256[](3);
            IERC20(cane).safeApprove(address(router), 0);
            IERC20(cane).safeApprove(address(router), rewardAmounts[1]);
            (totalLp[0], totalLp[1], totalLp[2]) = router.addLiquidityETH{value: swappedTokens[swappedTokens.length - 1]}
                (address(cane), rewardAmounts[1], 0, 0, address(this), block.timestamp + 5 minutes);
            // Check for any leftover CANE dust, return to treasury
            if (rewardAmounts[1].sub(totalLp[0]) > 0) {
                cane.mint(treasury, rewardAmounts[1].sub(totalLp[0]));
            }
            // Check for any leftover ETH dust, return to treasury
            if (swappedTokens[swappedTokens.length - 1].sub(totalLp[1]) > 0) {
                treasury.transfer(swappedTokens[swappedTokens.length - 1].sub(totalLp[1]));
            }

            // Add LP token to total and borrowed supply to KAT pool
            PoolInfo storage katPool = poolInfo[KATRINA_POOL_ID];
            AccountInfo storage katAccount = accountInfos[KATRINA_POOL_ID][msg.sender];

            katPool.totalSupply = katPool.totalSupply.add(totalLp[2]);
            katPool.borrowedSupply = katPool.borrowedSupply.add(totalLp[0]);
            
            // Add to balance and iterator if not already in pool
            katAccount.balance = katAccount.balance.add(totalLp[2]);
            if (katAccount.index == 0) {
                accountInfosIndex[KATRINA_POOL_ID].push(msg.sender);
                katAccount.index = accountInfosIndex[KATRINA_POOL_ID].length;
            }

            emit Claimed(msg.sender, _poolId, reward);
        }
    }

    // allow LPs to claim fee rewards with no penalties
    function claimLP(uint256 _poolId) external {
        AccountInfo storage account = accountInfos[_poolId][msg.sender];
        require (account.lpEthReward > 0 || account.lpCaneReward > 0, 'No LP rewards');
        emit ClaimedLPReward(msg.sender, _poolId, account.lpEthReward, account.lpCaneReward);

        if (account.lpEthReward > 0) {
            // Reduce rewards due, track total paid, and send ETH
            account.lpEthRewardPaid = account.lpEthRewardPaid.add(account.lpEthReward);
            msg.sender.transfer(account.lpEthReward);
            account.lpEthReward = 0;
        }
        if (account.lpCaneReward > 0) {
            account.lpCaneRewardPaid = account.lpCaneRewardPaid.add(account.lpCaneReward);
            cane.mint(msg.sender, account.lpCaneReward);
            account.lpCaneReward = 0;
        }
    }

    // stake airgrabber's tokens to Hugo
    function stakeAirgrabber() external {
        require(airgrabbers[msg.sender].caneAmount > 0, "No CANE to stake");
        require(!airgrabbers[msg.sender].caneClaimed, "Already airgrabbed CANE");
        airgrabbers[msg.sender].caneClaimed = true;
        cane.mint(msg.sender, airgrabbers[msg.sender].caneAmount);
        stakeToHugo(airgrabbers[msg.sender].caneAmount, false);
    }

    // stake airgrabber's tokens to Katrina
    function stakeAirgrabberLP() external {
        require(airgrabbers[msg.sender].ethAmount > 0, "No ETH to stake");
        require(!airgrabbers[msg.sender].ethClaimed, "Already airgrabbed ETH");
        airgrabbers[msg.sender].ethClaimed = true;
        this.stake{value: airgrabbers[msg.sender].ethAmount}(KATRINA_POOL_ID, airgrabbers[msg.sender].ethAmount, msg.sender);
    }

    // withdraw airgrabber's ETH to their wallet
    function withdrawAirgrabber() external {
        require(airgrabbers[msg.sender].ethAmount > 0, "No ETH to stake");
        require(!airgrabbers[msg.sender].ethClaimed, "Already airgrabbed ETH");
        airgrabbers[msg.sender].ethClaimed = true;
        msg.sender.transfer(airgrabbers[msg.sender].ethAmount);
    }

    // Accepts user's address and adds their ETH/CANE stakes due from the airgrab
    function addAirgrabber(address _airgrabber, uint256 _ethAmount, uint256 _caneAmount) external onlyOwner {
        require(!airgrabbers[_airgrabber].ethClaimed || !airgrabbers[_airgrabber].caneClaimed, "Airgrabber already claimed");
        airgrabbers[_airgrabber] = Airgrabber({
            ethAmount: _ethAmount,
            caneAmount: _caneAmount,
            ethClaimed: false,
            caneClaimed: false
        });
    }

    // transfer to treasury if problem found. allow disabling 
    // of this function, if we find all is well over time
    function disableSendToTreasury() external onlyOwner {
        require(!treasuryDisabled, "Already disabled");
        treasuryDisabled = true;
    }
    function sendToTreasury() external onlyOwner {
        require(!treasuryDisabled, "Invalid operation");
        treasury.transfer(address(this).balance);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    // _rewardAllocation must be % number (e.g. 15 means 15%)
    
    function add(
        uint256 _rewardAllocation, 
        IERC20 _pairAddress, 
        IERC20 _otherToken
        ) external onlyOwner {
        require (_rewardAllocation <= 100, "Invalid allocation");
        uint256 _totalAllocation = rewardAllocation.mul(_rewardAllocation).div(100);
        for (uint256 pid = 0; pid < poolInfo.length; ++ pid) {
            _totalAllocation = _totalAllocation.add(poolInfo[pid].rewardAllocation);
        }
        require (_totalAllocation <= rewardAllocation, "Allocation exceeded");

        poolInfo.push(PoolInfo({
            pairAddress: _pairAddress,
            otherToken: _otherToken,
            rewardAllocation: rewardAllocation.mul(_rewardAllocation).div(100),
            borrowedSupply: 0,
            totalSupply: 0,
            rewardPerTokenStored: 0
        }));
    }

    // Update the given pool's CANE rewards. Can only be called by the owner.
    // _rewardAllocation must be % number (e.g. 15 means 15%)
    function set(uint256 _poolId, uint256 _rewardAllocation) external onlyOwner {
        require (_rewardAllocation <= 100, "Invalid allocation");
        uint256 totalAllocation = rewardAllocation.sub(poolInfo[_poolId].rewardAllocation).add(
            rewardAllocation.mul(_rewardAllocation).div(100)
        );
        require (totalAllocation <= rewardAllocation, "Allocation exceeded");
        
        if (poolInfo[_poolId].rewardAllocation != rewardAllocation.mul(_rewardAllocation).div(100)) {
            poolInfo[_poolId].rewardAllocation = rewardAllocation.mul(_rewardAllocation).div(100);
        }
    }

    // Fetches length of accounts in a pool
    // Allows easy front end iteration of accountInfos
    function accountInfosLength(uint256 _poolId) external view returns (uint256) {
        require(_poolId < poolInfo.length, 'Invalid pool');
        return accountInfosIndex[_poolId].length;
    }

    // Fetches details of account in the pool specified
    // Allows easy front end iteration of accountInfos
    function accountInfosByIndex(uint256 _poolId, uint256 _index) 
        external view returns (
            uint256 index,
            uint256 balance,
            uint256 lastWithdrawTimestamp,
            uint256 lastStakedTimestamp,
            uint256 reward,
            uint256 rewardPerTokenPaid,
            uint256 lpEthReward,
            uint256 lpEthRewardPaid,
            uint256 lpCaneReward,
            uint256 lpCaneRewardPaid,
            address userAddress) {

        require(_poolId < poolInfo.length, 'Invalid pool');
        userAddress = accountInfosIndex[_poolId][_index];
        AccountInfo memory account = accountInfos[_poolId][userAddress];
        return (
            account.index,
            account.balance,
            account.lastWithdrawTimestamp,
            account.lastStakedTimestamp,
            account.reward,
            account.rewardPerTokenPaid,
            account.lpEthReward,
            account.lpEthRewardPaid,
            account.lpCaneReward,
            account.lpCaneRewardPaid,
            userAddress
            );
    }

    // Fetches individual balances for each token in a pair
    function balanceOfPool(uint256 _poolId) external view returns (uint256, uint256) {
        require(_poolId < poolInfo.length, 'Invalid pool');
        PoolInfo storage pool = poolInfo[_poolId];
        
        uint256 otherTokenAmount = IERC20(pool.otherToken).balanceOf(address(pool.pairAddress));
        uint256 caneTokenAmount = IERC20(cane).balanceOf(address(pool.pairAddress));

        return (otherTokenAmount, caneTokenAmount);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function burnedTokenAmount() external view returns (uint256) {
        return cane.balanceOf(BURN_ADDRESS);
    }

    function rewardPerToken(uint256 _poolId) public view returns (uint256) {
        require(_poolId < poolInfo.length, 'Invalid pool');
        PoolInfo storage pool = poolInfo[_poolId];
        if (pool.totalSupply == 0) {
            return pool.rewardPerTokenStored;
        }

        uint256 poolRewardRate = pool.rewardAllocation.mul(rewardRate).div(rewardAllocation);

        return pool.rewardPerTokenStored
        .add(
            lastRewardTimestamp()
            .sub(lastUpdateTimestamp)
            .mul(poolRewardRate)
            .mul(1e18)
            .div(pool.totalSupply)
        );
    }

    function lastRewardTimestamp() public view returns (uint256) {
        return Math.min(block.timestamp, halvingTimestamp);
    }

    function rewardEarned(uint256 _poolId, address account) public view returns (uint256) {
        return accountInfos[_poolId][account].balance.mul(
            rewardPerToken(_poolId).sub(accountInfos[_poolId][account].rewardPerTokenPaid)
        )
        .div(1e18)
        .add(accountInfos[_poolId][account].reward);
    }

    // Token price in eth
    function tokenPrice(uint256 _poolId) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_poolId];
        uint256 ethAmount = IERC20(weth).balanceOf(address(pool.pairAddress));
        uint256 tokenAmount = IERC20(cane).balanceOf(address(pool.pairAddress));
        
        return tokenAmount > 0 ?
        // Current price
        ethAmount.mul(1e18).div(tokenAmount) :
        // Initial price
        (uint256(1e18).div(1));
    }

    // Set all configurable parameters
    function setGoverningParameters(uint256[] memory _parameters) external onlyOwner {
        require(_parameters[0] >= 5 && _parameters[0] <= 50, "Invalid range");  //_parameters[0] _rewardHalvingPercent
        require(_parameters[1] >= 10 && _parameters[1] <= 50, "Invalid range"); //_parameters[1] _withdrawalLimitPercent
        require(_parameters[2] >= 1 && _parameters[2] <= 5, "Invalid range");   //_parameters[2] _claimBurnFee
        require(_parameters[3] >= 1 && _parameters[3] <= 5, "Invalid range");   //_parameters[3] _claimTreasuryFeePercent
        require(_parameters[4] >= 1 && _parameters[4] <= 5, "Invalid range");   //_parameters[4] _claimLPFeePercent
        require(_parameters[5] >= 25 && _parameters[5] <= 95, "Invalid range"); //_parameters[5] _claimLiquidBalancePercent
        require(_parameters[6] >= 1 && _parameters[6] <= 5, "Invalid range");   //_parameters[6] _unstakeBurnFeePercent
        require(_parameters[7] >= 1 && _parameters[7] <= 5, "Invalid range");   //_parameters[7] _unstakeTreasuryFeePercent
        require(_parameters[8] >= 1 && _parameters[8] <= 5, "Invalid range");   //_parameters[8] _unstakeLPFeePercent
        require(_parameters[9] >= 2 && _parameters[9] <= 10, "Invalid range");  //_parameters[9] _katrinaExitFeePercent
        require(_parameters[2]   // _claimBurnFee
            .add(_parameters[3]) // _claimTreasuryFeePercent
            .add(_parameters[4]) // _claimLPFeePercent
            .add(_parameters[5]) // _claimLiquidBalancePercent
            == 100, 'Invalid claim fees');
        rewardHalvingPercent = _parameters[0];
        withdrawalLimitPercent = _parameters[1];
        claimBurnFee = _parameters[2];
        claimTreasuryFeePercent = _parameters[3];
        claimLPFeePercent = _parameters[4];
        claimLiquidBalancePercent = _parameters[5];
        unstakeBurnFeePercent = _parameters[6];
        unstakeTreasuryFeePercent = _parameters[7];
        unstakeLPFeePercent = _parameters[8];
        katrinaExitFeePercent = _parameters[9];
    }
    
    // Only allow our farmingStartTimestamp to be changed between 72 hours
    // of the original schedule. Gives us flexibility in when to go live
    // if some unexpected circumstances happens (such as high gas prices)
    //
    // We must start farming somewhere between Dec 15, 2020 and Dec 16, 2020 19:00 GMT
    // Thanks Karl (Cat3) for the suggestion ;-)
    function setFarmingStartTimestamp(uint256 _farmingStartTimestamp) external onlyOwner {
        require(!farmingStarted && _farmingStartTimestamp >= 1608058800 && _farmingStartTimestamp <= 1608145200, "Invalid range");
        farmingStartTimestamp = _farmingStartTimestamp;
    }

    // Update user rewards
    function _updateReward(uint256 _poolId) internal {
        PoolInfo storage pool = poolInfo[_poolId];
        pool.rewardPerTokenStored = rewardPerToken(_poolId);
        lastUpdateTimestamp = lastRewardTimestamp();
        if (msg.sender != address(0)) {
            accountInfos[_poolId][msg.sender].reward = rewardEarned(_poolId, msg.sender);
            accountInfos[_poolId][msg.sender].rewardPerTokenPaid = pool.rewardPerTokenStored;
        }
    }

    // Do halving when timestamp reached
    function _halving(uint256 _poolId) internal {
        if (block.timestamp >= halvingTimestamp) {
            rewardAllocation = rewardAllocation.mul(rewardHalvingPercent).div(100);

            rewardRate = rewardAllocation.div(HALVING_DURATION);
            halvingTimestamp = halvingTimestamp.add(HALVING_DURATION);

            _updateReward(_poolId);
            emit Halving(rewardAllocation);
        }
    }
    // Check if farming is started
    function _checkFarming() internal {
        require(farmingStartTimestamp <= block.timestamp, 'Farming has not yet started. Try again later.');
        if (!farmingStarted) {
            // We made it to this line, so farming has finally started! The Hurricane.Finance team 
            // would love to thank the following team members for their unwavering support:
            // Kart (Cat3); Foxtrot Delta; Storm Wins; psychologist; Lito; and Lizzie
            // ...and of course, me, Meteorologist - hehehe.
            //
            // Let's go, Hurricanes!
            farmingStarted = true;
            halvingTimestamp = block.timestamp.add(HALVING_DURATION);
            lastUpdateTimestamp = block.timestamp;
        }
    }
}