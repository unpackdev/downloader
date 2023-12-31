// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./GaugeVoting.sol";
import "./WombexLensUI.sol";
import "./ERC20.sol";
import "./GaugeVotingLens.sol";

/**
 * @title   GaugeVotingLens
 * @author  WombexFinance
 */
contract GaugeVotingLens {
    GaugeVoting public gaugeVoting;
    address public wmx;
    address public wom;
    IERC20 public veWom;
    address public stakingToken;
    address public voterProxy;
    IBribeVoter public bribeVoter;
    WombexLensUI public wombexLensUI;

    struct Pool {
        address lpToken;
        address rewards;
        WombexLensUI.RewardItem[] userRewardItems;
        PoolVotes votes;
        bool isActive;
        string name;
        string symbol;
        WombexLensUI.PoolValuesTokenApr[] bribeAprs;
        uint128 rewardsApr;
        uint128 rewardsAprItem;
        uint128 bribeApr;
        uint128 bribeAprItem;
    }

    struct PoolVotes {
        uint128 vlVotes;
        int128 vlDelta;
        int128 veWomVotes;
        int128 veWomDelta;
    }

    struct UserReward {
        address lpToken;
        address rewards;
        address rewardToken;
        uint8 decimals;
        uint256 rewardAmount;
        uint256 usdAmount;
    }

    struct RewardToken {
        address token;
        string symbol;
        uint8 decimals;
    }

    constructor(GaugeVoting _gaugeVoting, WombexLensUI _wombexLensUI) {
        gaugeVoting = _gaugeVoting;
        wmx = _wombexLensUI.WMX_TOKEN();
        wom = _wombexLensUI.WOM_TOKEN();
        stakingToken = address(_gaugeVoting.stakingToken());
        veWom = _gaugeVoting.veWom();
        voterProxy = _gaugeVoting.voterProxy();
        bribeVoter = _gaugeVoting.bribeVoter();
        wombexLensUI = _wombexLensUI;
    }

    function getPools(address _userAddress) public returns (Pool[] memory pools) {
        address[] memory lpTokens = gaugeVoting.getLpTokensAdded();
        (int256[] memory deltas, int256[] memory votes) = gaugeVoting.getVotesDelta();
        if (deltas.length == 0) {
            deltas = new int256[](lpTokens.length);
            votes = new int256[](lpTokens.length);
        }
        pools = new Pool[](lpTokens.length);
        uint256 stakingTokenPrice = wombexLensUI.estimateInBUSDEther(wmx, 1 ether, 18);
        uint256 stakingTotalSupply = IERC20(stakingToken).totalSupply();
        uint256 veWomBalance = veWom.balanceOf(voterProxy);
        for (uint256 i = 0; i < lpTokens.length; i++) {
            pools[i].rewards = gaugeVoting.lpTokenRewards(lpTokens[i]);
            pools[i].userRewardItems = wombexLensUI.getUserPendingRewards(0, pools[i].rewards, _userAddress);
            uint256 vlVotes = IERC20(pools[i].rewards).totalSupply();
            if (vlVotes == 0) {
                vlVotes = 1 ether;
            }
            if (votes[i] != 0) {
                int256 ratio = int256(vlVotes) * int256(1 ether) / votes[i];
                pools[i].votes = PoolVotes(
                    uint128(vlVotes),
                    int128(deltas[i] * ratio / int256(1 ether)),
                    int128(votes[i]),
                    int128(deltas[i])
                );
            }
            uint256 tvl = (stakingTokenPrice * vlVotes) / 1 ether;
            (pools[i].rewardsAprItem, pools[i].rewardsApr) = wombexLensUI.getRewardPoolTotalApr128(IBaseRewardPool4626(pools[i].rewards), tvl, 0, 0);
            (pools[i].bribeAprItem, pools[i].bribeApr, pools[i].bribeAprs) = wombexLensUI.getBribeTotalApr128(voterProxy, bribeVoter, lpTokens[i], tvl, (stakingTotalSupply * stakingTokenPrice) / 1 ether, veWomBalance);

            pools[i].lpToken = lpTokens[i];
            pools[i].isActive = isLpActive(lpTokens[i]);
            pools[i].name = ERC20(lpTokens[i]).name();
            pools[i].symbol = ERC20(lpTokens[i]).symbol();
        }
    }

    function getPoolWithPrices(address _lpToken, uint256[] memory rewardTokenPrices) public returns (Pool memory pool) {
        pool.rewards = gaugeVoting.lpTokenRewards(_lpToken);
        uint256 stakingTokenPrice = wombexLensUI.estimateInBUSDEther(wmx, 1 ether, 18);
        uint256 bribeAprItem;
        uint256 bribeApr;
        (pool.bribeAprs, bribeAprItem, bribeApr) = wombexLensUI.getBribeApys(
            voterProxy,
            bribeVoter,
            _lpToken,
            (stakingTokenPrice * IERC20(pool.rewards).totalSupply()) / 1 ether,
            (IERC20(stakingToken).totalSupply() * stakingTokenPrice) / 1 ether,
            veWom.balanceOf(voterProxy),
            rewardTokenPrices
        );
        pool.bribeAprItem = uint128(bribeAprItem);
        pool.bribeApr = uint128(bribeApr);
        pool.lpToken = _lpToken;
        pool.isActive = isLpActive(_lpToken);
        pool.name = ERC20(_lpToken).name();
        pool.symbol = ERC20(_lpToken).symbol();
    }

    struct PoolInput {
        address lpToken;
        uint256[] rewardTokenPrices;
    }
    function getPoolsWithPrices(PoolInput[] memory poolInputs) public returns (Pool[] memory pools) {
        pools = new Pool[](poolInputs.length);
        for(uint256 i = 0; i < pools.length; i++) {
            pools[i] = getPoolWithPrices(poolInputs[i].lpToken, poolInputs[i].rewardTokenPrices);
        }
    }

    function isLpActive(address _lpToken) public view returns(bool) {
        return gaugeVoting.lpTokenStatus(_lpToken) == GaugeVoting.LpTokenStatus.ACTIVE;
    }

    function getUserVotes(address _user) public view returns (uint256[] memory votes) {
        address[] memory lpTokens = gaugeVoting.getLpTokensAdded();
        votes = new uint256[](lpTokens.length);
        for(uint256 i = 0; i < lpTokens.length; i++) {
            votes[i] = IERC20(gaugeVoting.lpTokenRewards(lpTokens[i])).balanceOf(_user);
        }
    }

    function getUserRewards(address _user, uint256 _rewardsPerLpToken) public returns (UserReward[] memory rewards) {
        address[] memory lpTokens = gaugeVoting.getLpTokensAdded();
        rewards = new UserReward[](lpTokens.length * _rewardsPerLpToken);
        uint256 rIndex = 0;

        for (uint256 j = 0; j < lpTokens.length; j++) {
            address rewardPool = gaugeVoting.lpTokenRewards(lpTokens[j]);
            uint256 rewardPoolBalance = IBribeRewardsPool(rewardPool).balanceOf(_user);

            address[] memory bribeRewardTokens = IBribeRewardsPool(rewardPool).rewardTokensList();
            for (uint256 i = 0; i < bribeRewardTokens.length; i++) {
                bool added = false;
                if (rewardPoolBalance == 0) {
                    for (uint256 k = 0; k < rIndex; k++) {
                        if (rewards[k].rewardToken == bribeRewardTokens[i]) {
                            added = true;
                            break;
                        }
                    }
                }
                if (added) {
                    continue;
                }
                uint8 decimals = wombexLensUI.getTokenDecimals(bribeRewardTokens[i]);
                uint256 earned = rewardPoolBalance == 0 ? 0 : IBribeRewardsPool(rewardPool).earned(bribeRewardTokens[i], _user);
                rewards[rIndex] = UserReward(
                    lpTokens[j],
                    rewardPool,
                    bribeRewardTokens[i],
                    decimals,
                    earned,
                    earned == 0 ? earned : wombexLensUI.estimateInBUSDEther(bribeRewardTokens[i], earned, decimals)
                );
                rIndex++;
            }
        }
    }

    function getTotalRewards(uint256 _rewardsPerLpToken) public returns (UserReward[] memory rewards) {
        address[] memory lpTokens = gaugeVoting.getLpTokensAdded();
        rewards = new UserReward[](lpTokens.length * _rewardsPerLpToken);
        uint256 rIndex = 0;

        for (uint256 i = 0; i < lpTokens.length; i++) {
            address rewardPool = gaugeVoting.lpTokenRewards(lpTokens[i]);
            address[] memory bribeRewardTokens = IBribeRewardsPool(rewardPool).rewardTokensList();
            for (uint256 j = 0; j < bribeRewardTokens.length; j++) {
                (, , , , , uint256 queuedRewards, , uint256 historicalRewards, ) = IBribeRewardsPool(rewardPool).tokenRewards(bribeRewardTokens[j]);
                uint8 decimals = wombexLensUI.getTokenDecimals(bribeRewardTokens[j]);
                uint256 amount = queuedRewards + historicalRewards;

                rewards[rIndex] = UserReward(
                    lpTokens[i],
                    rewardPool,
                    bribeRewardTokens[j],
                    decimals,
                    amount,
                    wombexLensUI.estimateInBUSDEther(bribeRewardTokens[j], amount, decimals)
                );
                rIndex++;
            }
        }
    }

    function getAllTokens(uint256 _rewardsPerLpToken) public returns (RewardToken[] memory rewardTokens) {
        address[] memory lpTokens = gaugeVoting.getLpTokensAdded();
        rewardTokens = new RewardToken[](lpTokens.length * (_rewardsPerLpToken + 1));
        uint256 rIndex = 0;

        for (uint256 i = 0; i < lpTokens.length; i++) {
            rewardTokens[rIndex] = RewardToken(
                lpTokens[i],
                ERC20(lpTokens[i]).symbol(),
                wombexLensUI.getTokenDecimals(lpTokens[i])
            );
            rIndex++;

            (, , , , , , address bribe) = bribeVoter.infos(lpTokens[i]);
            IERC20[] memory bribeTokens = IBribe(bribe).rewardTokens();
            for (uint256 j = 0; j < bribeTokens.length; j++) {
                rewardTokens[rIndex] = RewardToken(
                    address(bribeTokens[j]),
                    ERC20(address(bribeTokens[j])).symbol(),
                    wombexLensUI.getTokenDecimals(address(bribeTokens[j]))
                );
                rIndex++;
            }
        }
    }
}
