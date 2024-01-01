// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./SafeERC20.sol";
import "./IAccessControl.sol";
import "./ICflatsDatabase.sol";
import "./ICryptoflatsNFT.sol";
import "./Harvest.sol";
import "./CflatsStakingErrors.sol";
import "./IDiscountable.sol";
import "./ICflatsTerritory.sol";
import "./CflatsDappRequirements.sol";
import "./ICflatsStaking.sol";
import "./StakingNFT.sol";


contract CflatsStaking is ICflatsStaking, IDiscountable, StakingNFT, CflatsDappRequirements, Harvest
{
    using SafeERC20 for IERC20;

    //***************************** startregion: CONSTANTS *****************************//
    // Profit constants //
    // Gen 1
    uint256 public constant PROFIT_FIRST_GEN_STANDARD = 3000;
    uint256 public constant PROFIT_FIRST_GEN_SILVER = 4000;
    uint256 public constant PROFIT_FIRST_GEN_GOLD = 5000;
    uint256 public constant PROFIT_FIRST_GEN_DIAMOND = 6000;

    // Gen 2
    uint256 public constant PROFIT_SECOND_GEN_STANDARD = 4000;
    uint256 public constant PROFIT_SECOND_GEN_SILVER = 5000;
    uint256 public constant PROFIT_SECOND_GEN_GOLD = 6500;
    uint256 public constant PROFIT_SECOND_GEN_DIAMOND = 8000;
    
    // Gen 3
    uint256 public constant PROFIT_THIRD_GEN_STANDARD = 5000;
    uint256 public constant PROFIT_THIRD_GEN_SILVER = 6000;
    uint256 public constant PROFIT_THIRD_GEN_GOLD = 7000;
    uint256 public constant PROFIT_THIRD_GEN_DIAMOND = 8000;

    // Gen 4
    uint256 public constant PROFIT_FOURTH_GEN_STANDARD = 6000;
    uint256 public constant PROFIT_FOURTH_GEN_SILVER = 8500;
    uint256 public constant PROFIT_FOURTH_GEN_GOLD = 10000;
    uint256 public constant PROFIT_FOURTH_GEN_DIAMOND = 12500;

    // Gen 5
    uint256 public constant PROFIT_FIFTH_GEN = 15000;

    // One day in seconds
    uint256 private constant _ONE_DAY = 86_400;
    
    // Five days in seconds
    uint256 private constant _FIVE_DAYS = _ONE_DAY * 5;
    

    // Get address of token by gen
    address[6] private _tokensByGen;

    //***************************** endregion: CONSTANTS *****************************//


    // address of territory for buying some nft
    ICflatsTerritory private immutable _TERRITORY;


    // mapping for setting up or extract highest rarity staked by owner
    mapping(address staker =>
        mapping(address stakeToken => CflatsRarity rarity)
    ) private _upperStakedRarityOf;


    // mapping for setting up or extract lock time
    mapping(address stakeToken => 
        mapping(uint256 tokenId => uint256 unlockTimestamp)
    ) private _nftLocker;


    // @notice mapping for setting up or extract balance by it's rarity
    mapping(address staker => 
        mapping(address stakeToken => 
        mapping(CflatsRarity rarity => uint256 stakeBalance)
    )) private _stakeBalanceByRarity;


    // @notice mappings for showing statistics of users by staked gen
    mapping(address stakeToken => 
        mapping(CflatsRarity rarity => uint16 stakers)
    ) private _cflatsStatisticsByRarity;





    constructor(
        address rewardToken,
        ICflatsTerritory territory,
        ICflatsDatabase database
    ) 
        StakingNFT(rewardToken)
        CflatsDappRequirements(database)
    {
        _TERRITORY = territory;
    }



    //***************************** startregion: external functions *****************************//

    /// @notice Since in the functionality of the Dapp game there is an opportunity
    /// for some users "fraudsters" to take part of the profits of others for some charge, 
    /// there is a special bot that regulates the events of the function call, and
    /// allows "fraudster" to call the function of transferring reward tokens to the
    /// balance of the fraudster through the CflatsDapp contract. The function also
    /// works in the opposite direction, the "victim" can return his/her tokens with a
    /// certain percentage
    /// @param from: victim
    /// @param to: fraudster
    /// @param amount: uint256
    /// @return True if transaction was successfully done
    function transferRewards(
        address from,
        address to,
        uint256 amount
    ) 
        external
        onlyOperator
        returns (bool)
    {
        _transferRewards(from, to, amount);
        return true;
    }


    /// @notice this function allows the administrator to add authorized 
    /// NFT addresses for staking (gen-0, gen-1, gen-2, gen-3, gen-4, gen-5)
    /// @param newStakeToken: address
    /// @return True if transaction was successfully done
    function addStakeToken(address newStakeToken) 
        external
        onlyOperator
        returns (bool)
    {
        uint256 gen = _getGen(newStakeToken);
        if(_tokensByGen.length < gen)
        {
            revert MaxGenSupplyOverflow();
        }

        _tokensByGen[gen] = newStakeToken;

        _addStakeToken(newStakeToken);

        return true;
    }


    function getAddedStakeTokens() external view returns(address[6] memory){
        return _tokensByGen;
    }


    /// @notice this function allows the administrator to remove 
    /// NFT addresses if it was added by mistake
    /// @param stakeToken: address
    /// @return True if transaction was successfully done
    function removeStakeToken(address stakeToken) 
        external
        onlyOperator
        returns(bool)
    {
        uint256 gen = _getGen(stakeToken);
        if(_tokensByGen.length < gen)
        {
            revert MaxGenSupplyOverflow();
        }

        delete _tokensByGen[gen];

        _removeStakeToken(stakeToken);
        return true;
    }


    function getStatisticsByRarity(address stakeToken) 
        external
        view
        returns(uint16, uint16, uint16, uint16)
    {
        return (
            _cflatsStatisticsByRarity[stakeToken][CflatsRarity.Standart],
            _cflatsStatisticsByRarity[stakeToken][CflatsRarity.Silver],
            _cflatsStatisticsByRarity[stakeToken][CflatsRarity.Gold],
            _cflatsStatisticsByRarity[stakeToken][CflatsRarity.Diamond]
        );
    }

    //***************************** endregion: external functions *****************************//



    //***************************** startregion: public functions *****************************//

    /// @notice shows upper token rarity staked by user
    /// @param staker: address
    /// @param stakeToken: address
    /// @return Highest staked rarity
    function getUpperStakedRarityOf(
        address staker,
        address stakeToken
    ) public view returns (CflatsRarity)
    {
        uint256 diamondBalance = _stakeBalanceByRarity[staker][stakeToken][CflatsRarity.Diamond];
        
        if(diamondBalance > 0)
        {
            return CflatsRarity.Diamond;
        }

        uint256 goldBalance = _stakeBalanceByRarity[staker][stakeToken][CflatsRarity.Gold];
        if(goldBalance > 0)
        {
            return CflatsRarity.Gold;
        }

        uint256 silverBalance = _stakeBalanceByRarity[staker][stakeToken][CflatsRarity.Silver];
        if(silverBalance > 0)
        {
            return CflatsRarity.Silver;
        }

        return CflatsRarity.Standart;
    }




    /// @notice shows rewards that can be received for staking specific gen and rarity
    /// @param stakeToken: address
    /// @param tokenId: address
    /// @return Rewards 
    function getRewardsForStakeToken(
        address stakeToken,
        uint256 tokenId
    ) public view returns(uint256)
    {
        uint256 gen = _getGen(stakeToken);
        uint256 profit = PROFIT_FIFTH_GEN;
        CflatsRarity rarity = ICflatsNftRarity(stakeToken).getNFTType(tokenId);

        if(gen == 0)
        {
            return 0;
        }
        else if(gen == 1)
        {
            if(rarity == CflatsRarity.Standart)
            {
                profit = PROFIT_FIRST_GEN_STANDARD;
            }
            else if(rarity == CflatsRarity.Silver)
            {
                profit = PROFIT_FIRST_GEN_SILVER;
            }
            else if(rarity == CflatsRarity.Gold)
            {
                profit = PROFIT_FIRST_GEN_GOLD;
            }
            else
            {
                profit = PROFIT_FIRST_GEN_DIAMOND;
            }
        }
        else if(gen == 2)
        {
            if(rarity == CflatsRarity.Standart)
            {
                profit = PROFIT_SECOND_GEN_STANDARD;
            }
            else if(rarity == CflatsRarity.Silver)
            {
                profit = PROFIT_SECOND_GEN_SILVER;
            }
            else if(rarity == CflatsRarity.Gold)
            {
                profit = PROFIT_SECOND_GEN_GOLD;
            }
            else
            {
                profit = PROFIT_SECOND_GEN_DIAMOND;
            }
        }
        else if(gen == 3)
        {
            if(rarity == CflatsRarity.Standart)
            {
                profit = PROFIT_THIRD_GEN_STANDARD;
            }
            else if(rarity == CflatsRarity.Silver)
            {
                profit = PROFIT_THIRD_GEN_SILVER;
            }
            else if(rarity == CflatsRarity.Gold)
            {
                profit = PROFIT_THIRD_GEN_GOLD;
            }
            else
            {
                profit = PROFIT_THIRD_GEN_DIAMOND;
            }
        }
        else if(gen == 4)
        {
            if(rarity == CflatsRarity.Standart)
            {
                profit = PROFIT_FOURTH_GEN_STANDARD;
            }
            else if(rarity == CflatsRarity.Silver)
            {
                profit = PROFIT_FOURTH_GEN_SILVER;
            }
            else if(rarity == CflatsRarity.Gold)
            {
                profit = PROFIT_FOURTH_GEN_GOLD;
            }
            else
            {
                profit = PROFIT_FOURTH_GEN_DIAMOND;
            }

        }

        return profit * 10**IERC20Metadata(getRewardToken()).decimals();
    }


    /// @notice shows discount of user if he/she has nft pass staked and diamond token rarity
    /// @param staker: address
    /// @return Discount in boolean and percentage 
    function hasDiscount(
        address staker
    ) public view returns (bool, uint8)
    {
        if(hasNftPassStaked(staker) == false)
        {
            return (false, 0);
        }

        if(getUpperStakedRarityOf(staker, _tokensByGen[0]) == CflatsRarity.Diamond)
        {
            return (true, 20);
        }

        return (true, 10);
    }


    /// @notice shows true if user has nft pass in it's wallet
    /// @param staker: address
    /// @return Boolean
    function hasNftPass(
        address staker
    ) public view returns (bool)
    {
        address nftPass = _tokensByGen[0];
        if(nftPass == address(0))
        {
            revert NftPassNotSettedByAdmin();
        }

        return IERC20Metadata(nftPass).balanceOf(staker) > 0;
    }


    /// @notice shows true if user staked nft pass
    /// @param staker: address
    /// @return Boolean
    function hasNftPassStaked(
        address staker
    ) public view returns (bool)
    {
        address nftPass = _tokensByGen[0];
        if(nftPass == address(0))
        {
            revert NftPassNotSettedByAdmin();
        }

        return stakedBalanceOf(staker, nftPass) > 0;
    }

    //***************************** endregion: public functions *****************************//



    //***************************** startregion: internal overriden functions *****************************//

    function _beforeStake(
        address staker,
        address stakeToken,
        uint256 tokenId
    ) internal onlyNotBlacklisted override 
    {
        _requireStakeToken(stakeToken);

        getDatabase().addUser(staker);

        // check if user has territory
        uint256 gen = _getGen(stakeToken);
        if(gen > 1)
        {
            if(_TERRITORY.hasTerritoryForGen(staker, gen) == false)
            {
                revert TerritoryNotBoughtError();
            }

            // if user wants to stake gen5 it required to
            // has nft pass on wallet balance or staking balance
            if(gen == 5 && hasNftPass(staker) != true  && hasNftPassStaked(staker) != true)
            {
                revert NftPassNotBoughtError();
            }
        }


        CflatsRarity currentTokenRarity = ICflatsNftRarity(stakeToken).getNFTType(tokenId);
        
        // updating upper token rarity 
        _increaseCflatsStatisticsByRarity(staker, stakeToken, currentTokenRarity);
        _increaseUpperStakeTokenRarity(staker, stakeToken, currentTokenRarity);

        // lock tokens for five days
        _lockForFiveDays(stakeToken, tokenId);
    }


    function _afterUnstake(
        address staker,
        address stakeToken,
        uint256 tokenId
    ) internal override 
    {
        if(_isLocked(stakeToken, tokenId) != false)
        {
            revert UnstakePeriodHasntBeenCompletedError();
        }

        CflatsRarity rarity = ICflatsNftRarity(stakeToken).getNFTType(tokenId);
        _decreaseUpperStakeTokenRarity(staker, stakeToken, rarity);
        _decreaseCflatsStatisticsByRarity(staker, stakeToken, rarity);
        
        // claim some rewards staked by user imediately after unstake
        _updateRewards(staker, stakeToken);

        uint256 stakedBalance = stakedBalanceOf(staker, stakeToken);
        if(stakedBalance > 0)
        {
            uint256 stakerRewardsPartion = rewardsOf(staker) / stakedBalance;

            // user can unstake NFT's but can't claim rewards
            if(stakerRewardsPartion > 0 && getDatabase().isBlacklisted(staker) == false)
            {
                _claimRewards(
                    staker,
                    stakeToken,
                    stakerRewardsPartion 
                );
            }
        }
    }


    function _claimRewards(
        address staker,
        address stakeToken,
        uint256 amount
    ) internal onlyNotBlacklisted override
    {
        super._claimRewards(staker, stakeToken, amount);
    }
    


    function _rewardsCalculatedHook(
        address staker,
        address stakeToken
    ) 
        internal
        view
        override
        returns(uint256)
    {
        uint256 balance = stakedBalanceOf(staker, stakeToken);
        uint256[] memory stakeTokenIds = stakedTokensOf(staker, stakeToken);

        // skip all calcualtions if nothing is staked
        if(balance == 0)
        {
            return 0;
        }


        uint256 rewards = 0;
        if(balance == 1)
        {
            rewards = getRewardsForStakeToken(stakeToken, stakeTokenIds[0]);
        }
        else
        {
            uint256 stakeTokensReward = 0;
            for(uint256 i = 0; i < balance;)
            {
                stakeTokensReward += getRewardsForStakeToken(stakeToken, stakeTokenIds[i]);
                unchecked{ ++i; }
            }
            rewards = stakeTokensReward;
        }

        // check if user has nft pass so he/she can get additional prizes
        (bool nftPassStaked, uint8 addPercent) = hasDiscount(staker);
        if(nftPassStaked == true)
        {
            // add 10% if Golden pass or 20% if Diamond pass
            rewards += rewards * addPercent / 100;
        }

        return rewards;
    }


    function _updateRewards(
        address staker,
        address stakeToken
    ) internal override
    {
        if(stakeToken != _tokensByGen[0])
        {
            super._updateRewards(staker, stakeToken);
        }
    }

    //***************************** endregion: internal overriden functions *****************************//



    //***************************** startregion: private functions *****************************//
    function _increaseUpperStakeTokenRarity(
        address staker,
        address stakeToken,
        CflatsRarity rarity
    ) private
    {
        unchecked
        {
            ++_stakeBalanceByRarity[staker][stakeToken][rarity];
        }
    }


    function _decreaseUpperStakeTokenRarity(
        address staker,
        address stakeToken,
        CflatsRarity rarity
    ) private
    {
        uint256 stakeBalanceByRarity = _stakeBalanceByRarity[staker][stakeToken][rarity];
        if(stakeBalanceByRarity == 0)
        {
            revert ZeroStakerBalanceForCurrentRarity(uint8(rarity));
        }
        unchecked
        {
            --_stakeBalanceByRarity[staker][stakeToken][rarity];
        }
    }


    function _increaseCflatsStatisticsByRarity(
        address staker,
        address stakeToken,
        CflatsRarity rarity
    ) private
    {
        if(_stakeBalanceByRarity[staker][stakeToken][rarity] > 0)
        {
            return;
        }

        unchecked
        {
            ++_cflatsStatisticsByRarity[stakeToken][rarity];
        }
    }


    function _decreaseCflatsStatisticsByRarity(
        address staker,
        address stakeToken,
        CflatsRarity rarity
    ) private
    {
        if(_stakeBalanceByRarity[staker][stakeToken][rarity] > 0)
        {
            return;
        }

        unchecked
        {
            --_cflatsStatisticsByRarity[stakeToken][rarity];
        }
    }


    function _lockForFiveDays(
        address stakeToken,
        uint256 tokenId
    ) private 
    {
        _nftLocker[stakeToken][tokenId] = block.timestamp + _FIVE_DAYS;
    }


    function _isLocked(
        address stakeToken,
        uint256 tokenId
    ) private view returns(bool)
    {
        return _nftLocker[stakeToken][tokenId] > block.timestamp;
    }


    function _getGen(address stakeToken) private view returns(uint256)
    {
        (bool success, bytes memory data) = stakeToken.staticcall(
            abi.encodeWithSelector(ICflatsNftGenSelector.gen.selector)
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }


    //***************************** endregion: private functions *****************************//
}