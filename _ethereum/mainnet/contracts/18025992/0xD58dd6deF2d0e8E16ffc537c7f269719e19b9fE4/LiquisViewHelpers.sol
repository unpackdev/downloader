// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IBalancerCore.sol";
import "./LiqLocker.sol";
import "./IBooster.sol";
import "./Math.sol";

/**
 * @title   LiquisViewHelpers
 * @author  AuraFinance
 * @notice  View-only contract to combine calls
 * @dev     IMPORTANT: These functions are extremely gas-intensive
 *          and should not be called from within a transaction.
 */
contract LiquisViewHelpers {
    using Math for uint256;

    IERC20Detailed public immutable liq = IERC20Detailed(0xD82fd4D6D62f89A1E50b1db69AD19932314aa408);
    IBalancerVault public immutable balancerVault = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    struct Token {
        address addr;
        uint8 decimals;
        string symbol;
        string name;
    }

    struct Pool {
        uint256 pid;
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
        address rewardToken;
        address uniV3Pool;
        address[] poolTokens;
        int24[] ticks;
        uint256 totalSupply;
        RewardsData rewardsData;
        ExtraRewards[] extraRewards;
    }

    struct Locker {
        uint256 epoch;
        uint256 totalSupply;
        uint256 lockedSupply;
        RewardsData rewardsData;
    }

    struct LockerAccount {
        address addr;
        uint256 total;
        uint256 unlockable;
        uint256 locked;
        uint256 nextUnlockIndex;
        uint128 rewardPerTokenPaid;
        uint128 rewards;
        address delegate;
        uint256 votes;
        LiqLocker.LockedBalance[] lockData;
        LiqLocker.EarnedData[] claimableRewards;
    }

    struct RewardsData {
        uint256 periodFinish;
        uint256 lastUpdateTime;
        uint256 rewardRate;
        uint256 rewardPerTokenStored;
        uint256 queuedRewards;
    }

    struct ExtraRewards {
        address addr;
        address rewardsToken;
        RewardsData rewardsData;
    }

    struct PoolBalances {
        uint256 pid;
        uint256 earned;
        uint256[] extraRewardsEarned;
        uint256 staked;
    }

    function getLocker(address _locker) external view returns (Locker memory locker) {
        LiqLocker liqLocker = LiqLocker(_locker);
        address rewardToken = liqLocker.cvxCrv();
        (uint32 periodFinish, uint32 lastUpdateTime, uint96 rewardRate, uint96 rewardPerTokenStored) = liqLocker
            .rewardData(rewardToken);

        RewardsData memory rewardsData = RewardsData({
            rewardRate: uint256(rewardRate),
            rewardPerTokenStored: uint256(rewardPerTokenStored),
            periodFinish: uint256(periodFinish),
            lastUpdateTime: uint256(lastUpdateTime),
            queuedRewards: liqLocker.queuedRewards(rewardToken)
        });

        locker = Locker({
            epoch: liqLocker.epochCount(),
            totalSupply: liqLocker.totalSupply(),
            lockedSupply: liqLocker.lockedSupply(),
            rewardsData: rewardsData
        });
    }

    function getLockerAccount(address _locker, address _account)
        external
        view
        returns (LockerAccount memory lockerAccount)
    {
        LiqLocker liqLocker = LiqLocker(_locker);
        address cvxCrv = liqLocker.cvxCrv();
        (, uint112 nextUnlockIndex) = liqLocker.balances(_account);
        (uint128 rewardPerTokenPaid, uint128 rewards) = liqLocker.userData(cvxCrv, _account);
        (uint256 total, uint256 unlockable, uint256 locked, LiqLocker.LockedBalance[] memory lockData) = liqLocker
            .lockedBalances(_account);

        lockerAccount = LockerAccount({
            addr: _account,
            total: total,
            unlockable: unlockable,
            locked: locked,
            lockData: lockData,
            nextUnlockIndex: uint256(nextUnlockIndex),
            rewardPerTokenPaid: rewardPerTokenPaid,
            rewards: rewards,
            delegate: liqLocker.delegates(_account),
            votes: liqLocker.balanceOf(_account),
            claimableRewards: liqLocker.claimableRewards(_account)
        });
    }

    function getPools(address _booster) external view returns (Pool[] memory) {
        IBooster booster = IBooster(_booster);

        uint256 poolLength = booster.poolLength();
        Pool[] memory pools = new Pool[](poolLength + 1); // +1 for cvxCrvRewards

        for (uint256 i = 0; i < poolLength; i++) {
            IBooster.PoolInfo memory poolInfo = booster.poolInfo(i);
            pools[i] = getPool(poolInfo, i);
        }

        // Add cvxCrvRewards
        pools[poolLength] = getCvxCrvRewards(booster.lockRewards());

        return pools;
    }

    function getCvxCrvRewards(address _cvxCrvRewards) public view returns (Pool memory) {
        IBaseRewardPool pool = IBaseRewardPool(_cvxCrvRewards);
        address cvxCrv = pool.stakingToken();

        address[] memory poolTokens = new address[](1);
        poolTokens[0] = cvxCrv;
        int24[] memory ticks = new int24[](1);
        ticks[0] = 0;

        RewardsData memory rewardsData = RewardsData({
            rewardRate: pool.rewardRate(),
            periodFinish: pool.periodFinish(),
            lastUpdateTime: pool.lastUpdateTime(),
            rewardPerTokenStored: pool.rewardPerTokenStored(),
            queuedRewards: pool.queuedRewards()
        });

        ExtraRewards[] memory extraRewards = getExtraRewards(_cvxCrvRewards);

        return
            Pool({
                pid: uint256(0),
                lptoken: cvxCrv,
                token: cvxCrv,
                gauge: address(0),
                crvRewards: _cvxCrvRewards,
                stash: address(0),
                shutdown: false,
                rewardToken: pool.rewardToken(),
                uniV3Pool: address(0),
                poolTokens: poolTokens,
                ticks: ticks,
                rewardsData: rewardsData,
                extraRewards: extraRewards,
                totalSupply: pool.totalSupply()
            });
    }

    function getExtraRewards(address _baseRewardPool) internal view returns (ExtraRewards[] memory) {
        IBaseRewardPool baseRewardPool = IBaseRewardPool(_baseRewardPool);

        uint256 extraRewardsLength = baseRewardPool.extraRewardsLength();
        ExtraRewards[] memory extraRewards = new ExtraRewards[](extraRewardsLength);

        for (uint256 i = 0; i < extraRewardsLength; i++) {
            address addr = baseRewardPool.extraRewards(i);
            IBaseRewardPool extraRewardsPool = IBaseRewardPool(addr);
            RewardsData memory data = RewardsData({
                rewardRate: extraRewardsPool.rewardRate(),
                periodFinish: extraRewardsPool.periodFinish(),
                lastUpdateTime: extraRewardsPool.lastUpdateTime(),
                rewardPerTokenStored: extraRewardsPool.rewardPerTokenStored(),
                queuedRewards: extraRewardsPool.queuedRewards()
            });
            extraRewards[i] = ExtraRewards({
                addr: addr,
                rewardsData: data,
                rewardsToken: extraRewardsPool.rewardToken()
            });
        }

        return extraRewards;
    }

    function getPool(IBooster.PoolInfo memory poolInfo, uint256 _pid) public view returns (Pool memory) {
        IBaseRewardPool rewardPool = IBaseRewardPool(poolInfo.crvRewards);
        IBunniLpToken bunniLpToken = IBunniLpToken(poolInfo.lptoken);

        // Some pools were added to the Booster without valid LP tokens
        // We need to try/catch all of these calls as a result
        address uniV3Pool;
        address[] memory poolTokens = new address[](2);
        int24[] memory ticks = new int24[](2);

        try bunniLpToken.pool() returns (address fetchedPool) {
            uniV3Pool = fetchedPool;

            poolTokens[0] = IUniV3Pool(uniV3Pool).token0();
            poolTokens[1] = IUniV3Pool(uniV3Pool).token1();

            ticks[0] = bunniLpToken.tickLower();
            ticks[1] = bunniLpToken.tickUpper();
        } catch {
            uniV3Pool = address(0);
        }

        ExtraRewards[] memory extraRewards = getExtraRewards(poolInfo.crvRewards);

        RewardsData memory rewardsData = RewardsData({
            rewardRate: rewardPool.rewardRate(),
            periodFinish: rewardPool.periodFinish(),
            lastUpdateTime: rewardPool.lastUpdateTime(),
            rewardPerTokenStored: rewardPool.rewardPerTokenStored(),
            queuedRewards: rewardPool.queuedRewards()
        });

        return
            Pool({
                pid: _pid,
                lptoken: poolInfo.lptoken,
                token: poolInfo.token,
                gauge: poolInfo.gauge,
                crvRewards: poolInfo.crvRewards,
                stash: poolInfo.stash,
                shutdown: poolInfo.shutdown,
                rewardToken: rewardPool.rewardToken(),
                uniV3Pool: uniV3Pool,
                poolTokens: poolTokens,
                ticks: ticks,
                rewardsData: rewardsData,
                extraRewards: extraRewards,
                totalSupply: rewardPool.totalSupply()
            });
    }

    function getPoolsBalances(address _booster, address _account) external view returns (PoolBalances[] memory) {
        uint256 poolLength = IBooster(_booster).poolLength();
        PoolBalances[] memory balances = new PoolBalances[](poolLength);
        for (uint256 i = 0; i < poolLength; i++) {
            IBooster.PoolInfo memory poolInfo = IBooster(_booster).poolInfo(i);
            balances[i] = getPoolBalances(poolInfo.crvRewards, i, _account);
        }
        return balances;
    }

    function getPoolBalances(
        address _rewardPool,
        uint256 _pid,
        address _account
    ) public view returns (PoolBalances memory) {
        IBaseRewardPool pool = IBaseRewardPool(_rewardPool);
        uint256 staked = pool.balanceOf(_account);
        uint256 earned = pool.earned(_account);

        uint256 extraRewardsLength = pool.extraRewardsLength();
        uint256[] memory extraRewardsEarned = new uint256[](extraRewardsLength);
        for (uint256 i = 0; i < extraRewardsLength; i++) {
            IBaseRewardPool extraRewardsPool = IBaseRewardPool(pool.extraRewards(i));
            extraRewardsEarned[i] = extraRewardsPool.earned(_account);
        }

        return PoolBalances({ pid: _pid, staked: staked, earned: earned, extraRewardsEarned: extraRewardsEarned });
    }

    function getTokens(address[] memory _addresses) public view returns (Token[] memory) {
        uint256 length = _addresses.length;
        Token[] memory tokens = new Token[](length);

        for (uint256 i = 0; i < length; i++) {
            address addr = _addresses[i];
            IERC20Detailed token = IERC20Detailed(addr);

            uint8 decimals;
            try token.decimals() {
                decimals = token.decimals();
            } catch {
                decimals = 0;
            }

            tokens[i] = Token({ addr: addr, decimals: decimals, symbol: token.symbol(), name: token.name() });
        }

        return tokens;
    }

    function getEarmarkingReward(
        uint256 pool,
        address booster,
        address token
    ) public returns (uint256 pending) {
        uint256 start = IERC20Detailed(token).balanceOf(address(this));
        IBooster(booster).earmarkRewards(pool);
        pending = IERC20Detailed(token).balanceOf(address(this)) - start;
    }

    function getMultipleEarmarkingRewards(
        uint256[] memory pools,
        address booster,
        address token
    ) external returns (uint256[] memory pendings) {
        pendings = new uint256[](pools.length);
        for (uint256 i = 0; i < pools.length; i++) {
            pendings[i] = getEarmarkingReward(pools[i], booster, token);
        }
    }

    function convertLitToLiq(uint256 _amount) external view returns (uint256 amount) {
        uint256 supply = liq.totalSupply();
        uint256 totalCliffs = 500;
        uint256 maxSupply = 5e25;
        uint256 initMintAmount = 5e25;
        uint256 reductionPerCliff = 1e23;

        // After LiqMinter.inflationProtectionTime has passed, this calculation might not be valid.
        // uint256 emissionsMinted = supply - initMintAmount - minterMinted;
        uint256 emissionsMinted = supply - initMintAmount;

        uint256 cliff = emissionsMinted.div(reductionPerCliff);

        // e.g. 100 < 500
        if (cliff < totalCliffs) {
            // e.g. (new) reduction = (500 - 100) * 0.25 + 70 = 170;
            // e.g. (new) reduction = (500 - 250) * 0.25 + 70 = 132.5;
            // e.g. (new) reduction = (500 - 400) * 0.25 + 70 = 95;
            uint256 reduction = totalCliffs.sub(cliff).div(4).add(70);
            // e.g. (new) amount = 1e19 * 170 / 500 =  34e17;
            // e.g. (new) amount = 1e19 * 132.5 / 500 =  26.5e17;
            // e.g. (new) amount = 1e19 * 95 / 500  =  19e16;
            amount = _amount.mul(reduction).div(totalCliffs);
            // e.g. amtTillMax = 5e25 - 1e25 = 4e25
            uint256 amtTillMax = maxSupply.sub(emissionsMinted);
            if (amount > amtTillMax) {
                amount = amtTillMax;
            }
        }
    }
}

interface IBaseRewardPool {
    function extraRewards(uint256 index) external view returns (address rewards);

    function extraRewardsLength() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function periodFinish() external view returns (uint256);

    function pid() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function earned(address owner) external view returns (uint256);

    function queuedRewards() external view returns (uint256);

    function rewardPerTokenStored() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function rewardToken() external view returns (address);

    function stakingToken() external view returns (address);
}

interface IERC20Detailed {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);
}

interface IBunniLpToken {
    function pool() external view returns (address);

    function tickLower() external view returns (int24);

    function tickUpper() external view returns (int24);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address user) external view returns (uint256);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);
}

interface IUniV3Pool {
    function token0() external view returns (address);

    function token1() external view returns (address);
}
