// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IFactory.sol";
import "./IPool.sol";
import "./IERC20.sol";
import "./IPair.sol";
import "./IERC721.sol";
/**
 * @title helper
 *
 * @notice to interact with core pool contracts
 *
 */

contract Helper {

    constructor(){}

    /**
     * @notice Returns adjusted information on the given deposit for the given address
     * @dev processing weight of Deposit structure
     *
     * @param pool address of pool
     * @param staker an address to query deposit for
     * @param depositId zero-indexed deposit ID for the address specified
     * @return deposit info as Deposit structure
     */
    function getDeposit(address pool, address staker, uint256 depositId) public view returns (Deposit memory) {
        // read deposit at specified index and return
        Deposit memory deposit = IPool(pool).getOriginDeposit(staker, depositId);
        if(deposit.tokenAmount != 0){
            deposit.weight = deposit.weight / deposit.tokenAmount;
        }
        return deposit;
    }

    /**
     * @notice Returns all deposits for the given address
     *
     * @dev processing weight of Deposit structure
     *
     * @param pool address of pool
     * @param staker an address to query deposit for
     * @return all deposits
     */
    function getAllDeposit(address pool, address staker) public view returns (Deposit[] memory) {
        uint256 depositsLength = IPool(pool).getDepositsLength(staker);
        if(depositsLength == 0) {
            return new Deposit[](0);
        }
        // all deposits
        Deposit[] memory deposits = new Deposit[](depositsLength);
        for(uint256 i = 0; i < depositsLength; i++) {
            deposits[i] = IPool(pool).getOriginDeposit(staker, i);
            if(deposits[i].tokenAmount != 0){
                deposits[i].weight = deposits[i].weight / deposits[i].tokenAmount;
            }
        }
        return deposits;
    }

    /**
     * @dev return arrary of deposit which was created by the pool itself or as a yield reward
     *
     * @param pool address of pool
     * @param staker an address to query arrary of deposit for
     * @param isYield deposit was created by the pool itself or as a yield reward  
     *
     * @return param1(Array): array of deposit ID
     * @return param2(Array): array of deposits
     */
    function getDepositsByIsYield(address pool, address staker, bool isYield) public view returns (uint[] memory, Deposit[] memory) {
        uint256 depositsLength = IPool(pool).getDepositsLength(staker);
        if(depositsLength == 0) {
            return (new uint[](0), new Deposit[](0));
        }
        // length of Deposits By isYield
        uint256 lengthIsYield = 0;
        for(uint256 i = 0; i < depositsLength; i++) {
            if((IPool(pool).getOriginDeposit(staker, i)).isYield == isYield) {
                lengthIsYield++;
            }
        }
        // deposit ID
        uint [] memory depositsID = new uint[](lengthIsYield);
        // deposits
        Deposit[] memory deposits = new Deposit[](lengthIsYield);
        // j is the index of deposits
        uint j = 0;
        for(uint256 i = 0; i < depositsLength; i++) {
            if((IPool(pool).getOriginDeposit(staker, i)).isYield == isYield) {
                deposits[j] = IPool(pool).getOriginDeposit(staker, i);
                depositsID[j] = i;
                if(deposits[j].tokenAmount != 0){
                    deposits[j].weight = deposits[j].weight / deposits[j].tokenAmount;
                }
                j++;
            }
        }
        return (depositsID, deposits);
    }

    /**
     * @dev return calculated lockingWeight

     * @param pool address of pool
     * @param lockPeriod stake period as unix timestamp; zero means no locking  
     */
    function getLockingWeight(address pool, uint64 lockPeriod) public view returns (uint256) {
        // weightMultiplier
        uint256 weightMultiplier = IPool(pool).weightMultiplier();
        // stake weight formula rewards for locking
        uint256 stakeWeight =
            ((lockPeriod * weightMultiplier) / 365 days + weightMultiplier);
        return stakeWeight;
    }

    /**
     * @notice Returns predicted rewards
     *
     * @param factory address of factory
     * @param pool address of pool
     * @param amount amount of tokens to stake
     * @param lockPeriod stake period as unix timestamp; zero means no locking
     * @param forecastTime how many rewards we get after forecast time
     * @param yieldTime how many seconds Ethereum produces one block
     * @return predicted rewards
     */
    function getPredictedRewards(
        address factory,
        address pool,
        uint256 amount, 
        uint256 lockPeriod, 
        uint256 forecastTime, 
        uint256 yieldTime,
        address staker,
        address nftAddress,
        uint256 nftTokenId
    ) external view returns (uint256) {
        if(amount == 0){
            return 0;
        }
        require(lockPeriod == 0 || lockPeriod <= 365 days, "invalid lock interval");
        // poolToken
        address poolToken = IPool(pool).poolToken();
        // weightMultiplier
        uint256 weightMultiplier = IPool(pool).weightMultiplier();
        // poolWgight
        uint256 poolWeight = (IFactory(factory).getPoolData(poolToken)).weight;
        // stakeWeight
        uint256 stakeWeight = 0;
        // stake weight formula rewards
        if(lockPeriod == 0) {
            // init weight of NFT
            uint nft_weight = 0;
            // if the user hold the right NFT tokenId, nft_weight will increase
            if (nftTokenId != 0 && nftAddress != address(0) ) {
                require(IERC721(nftAddress).ownerOf(nftTokenId) == staker, "the NFT tokenId doesn't match the user");
                nft_weight = IPool(pool).supportNTF(nftAddress);
            }
            stakeWeight =  nft_weight * weightMultiplier + amount * weightMultiplier;
        }else {
            stakeWeight =
                ((lockPeriod * weightMultiplier) / 365 days + weightMultiplier) * amount;
        }
        
        // makes sure stakeWeight is valid
        require(stakeWeight > 0, "invalid input");    
        uint256 cartRewards = ((forecastTime / yieldTime) * poolWeight * IFactory(factory).cartPerBlock()) / IFactory(factory).totalWeight();
        // newUsersLockingWeight
        uint256 newUsersLockingWeight = IPool(pool).usersLockingWeight() + stakeWeight;
        uint256 rewardsPerWeight = IPool(pool).rewardToWeight(cartRewards, newUsersLockingWeight);
        return IPool(pool).weightToReward(stakeWeight, rewardsPerWeight);
    }

    /**
     * @notice Calculates current yield rewards value available for address specified
     *
     * @param factory address of factory
     * @param pool address of pool
     * @param staker an address to calculate yield rewards value for
     * @return calculated yield reward value for the given address
     */
    function pendingYieldRewards(address factory, address pool, address staker) public view returns (uint256) {
        // Used to calculate yield rewards
        uint256 yieldRewardsPerWeight = IPool(pool).yieldRewardsPerWeight();
        // `newYieldRewardsPerWeight` will store stored or recalculated value for `yieldRewardsPerWeight`
        uint256 newYieldRewardsPerWeight;
        // current block number
        uint256 blockNumber = block.number;
        // Block number of the last yield distribution event
        uint256 lastYieldDistribution = IPool(pool).lastYieldDistribution();
        // Used to calculate yield rewards, keeps track of the tokens weight locked in staking
        uint256 usersLockingWeight = IPool(pool).usersLockingWeight();
        // poolToken
        address poolToken = IPool(pool).poolToken();
        // poolWgight
        uint256 poolWeight = (IFactory(factory).getPoolData(poolToken)).weight;
        // if smart contract state was not updated recently, `yieldRewardsPerWeight` value
        // is outdated and we need to recalculate it in order to calculate pending rewards correctly
        if (blockNumber > lastYieldDistribution && usersLockingWeight != 0) {
            uint256 endBlock = IFactory(factory).endBlock();
            uint256 multiplier =
                blockNumber > endBlock ? endBlock - lastYieldDistribution : blockNumber - lastYieldDistribution;
            uint256 cartRewards = (multiplier * poolWeight * IFactory(factory).cartPerBlock()) / IFactory(factory).totalWeight();
            // recalculated value for `yieldRewardsPerWeight`
            newYieldRewardsPerWeight = IPool(pool).rewardToWeight(cartRewards, usersLockingWeight) + yieldRewardsPerWeight;
        } else {
            // if smart contract state is up to date, we don't recalculate
            newYieldRewardsPerWeight = yieldRewardsPerWeight;
        }
        // based on the rewards per weight value, calculate pending rewards;
        User memory user = IPool(pool).getUser(staker);
        uint256 pending = IPool(pool).weightToReward(user.totalWeight, newYieldRewardsPerWeight) - user.subYieldRewards;
        return pending;
    }

    /**
     * @dev lptoTokenAmount lp tokens passed in, and return amounts of two tokens 
     * 
     * function lptoTokenAmount(address lpAddress, uint256 lpAmount)
     * 
     * @param lpAddress lp地址
     * @param lpAmount lp数量
     * 
     * @return amount0 amounts of two tokens 
     * @return amount1 amounts of two tokens 
     * 
     */
    function lptoTokenAmount(address lpAddress, uint256 lpAmount) external view returns(uint256 amount0, uint256 amount1){
        uint lpSupply = IERC20(lpAddress).totalSupply();
        (uint112 reserve0, uint112 reserve1, ) = IPair(lpAddress).getReserves();
        uint amount0 = uint(reserve0) * lpAmount / lpSupply;
        uint amount1 = uint(reserve1) * lpAmount/ lpSupply;
        return (amount0, amount1);
    }

    
}