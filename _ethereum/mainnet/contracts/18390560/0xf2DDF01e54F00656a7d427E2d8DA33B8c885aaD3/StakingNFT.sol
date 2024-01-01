// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Context.sol";
import "./IERC721.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IERC721Receiver.sol";
import "./ERC165Checker.sol";
import "./StakingErrors.sol";
import "./IStakingNFT.sol";

import "./console.sol";


abstract contract StakingNFT is IStakingNFT, IERC721Receiver, Context
{
    using SafeERC20 for IERC20;

    // Token that will be used as a reward for staking
    // It can be as ERC20 or ERC721 token or other
    address private immutable _REWARD_TOKEN;


    // mapping for setting up or extract boolean for stake token
    mapping(address stakeToken => bool isStakeToken) private _isStakeToken;


    // mapping for setting up or extract rewards of staker
    mapping(address staker => uint256 rewards) private _rewardsOf;


    // mapping for setting up or extract info of staked NFT
    mapping(address staker => 
        mapping(address stakeToken => StakedInfoNFT stakedInfo)
    ) private _stakedInfoOf;


    // mapping for setting up or extract staker of  token
    mapping(address staker => 
        mapping(address stakeToken => 
        mapping(uint256 tokenId => bool isStaker)
    )) private _isStakerOf;




    constructor(address rewardToken_)
    {
        _REWARD_TOKEN = rewardToken_;
    }



    modifier onlyStakeToken(address stakeToken)
    {
        _requireStakeToken(stakeToken);
        _;
    }




    //***************************** startregion: external overrided functions *****************************//

    /// @notice overrided ERC721 receiver
    /// @dev function used to allow this contract to receive ERC721 from any
    /// @param operator: address
    /// @param from: address
    /// @param tokenId: uint256
    /// @param data: bytes
    /// @return bytes4
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) 
        external
        virtual
        override
        returns (bytes4)
    {
        emit ReceivedNFT(operator, from, tokenId, data);
        return IERC721Receiver.onERC721Received.selector;
    }


    /// @notice stake function
    /// @dev takes arguments to stake ERC721 tokens
    /// @param stakeToken: address
    /// @param tokenId: uint256
    /// @return True if transaction is successfull
    function stake(
        address stakeToken,
        uint256 tokenId
    ) external returns (bool)
    {
        _safeStake(_msgSender(), stakeToken, tokenId);
        return true;
    }


    /// @notice unstake function
    /// @dev takes arguments to stake ERC721 tokens
    /// @param stakeToken: address
    /// @param tokenId: uint256
    /// @return True if transaction is successfull
    function unstake(
        address stakeToken,
        uint256 tokenId
    ) external returns (bool)
    {
        _safeUnstake(_msgSender(), stakeToken, tokenId);
        return true;
    }

    //***************************** endregion: external overrided functions *****************************//



    //***************************** startregion: public functions *****************************//

    /// @notice shows address of reward token
    /// @dev reward token cannot be zero address
    /// @custom:require ERC20 token to be added
    /// @return reward token address
    function getRewardToken() public virtual view returns (address)
    {
        return _REWARD_TOKEN;
    }


    /// @notice shows period in which reward balance will be updated
    /// @return Time in seconds when reward balance can be updated
    function getUpdatePeriod() public virtual pure returns (uint256)
    {
        return 86_400;
    }


    /// @notice shows balance of staked tokens
    /// @param staker: address
    /// @param stakeToken: address
    /// @return balance of staked tokens for it's owner
    function stakedBalanceOf(
        address staker,
        address stakeToken
    ) public view returns (uint256)
    {
        return _stakedInfoOf[staker][stakeToken].ids.length;
    }


    /// @notice shows time when first time ERC721 token was staked
    /// @param staker: address
    /// @param stakeToken: address
    /// @return Time in seconds when first time ERC721 token was staked
    function stakedTimestampOf(
        address staker,
        address stakeToken
    ) public view returns (uint256)
    {
        return _stakedInfoOf[staker][stakeToken].timestamp;
    }


    /// @notice shows rewards collected by staker
    /// @param staker: address
    /// @return Collected staker rewards
    function rewardsOf(address staker)
        public
        virtual
        view
        returns (uint256)
    {
        return _rewardsOf[staker];
    }


    /// @notice shows rewards collected by staker
    /// @param staker: address
    /// @param stakeToken: address
    /// @return Collected staker rewards
    function stakedTokensOf(
        address staker,
        address stakeToken
    ) 
        public 
        virtual 
        view 
        returns (uint256[] memory)
    {
        return _stakedInfoOf[staker][stakeToken].ids;
    }


    /// @notice shows if token is added by owner
    /// @param stakeToken: address
    /// @return True if token is allowed
    function isStakeToken(address stakeToken) 
        public
        virtual
        override
        view
        returns (bool)
    {
        return _isStakeToken[stakeToken];
    }


    /// @notice shows staker of ERC721 token
    /// @param staker: address
    /// @param stakeToken: address
    /// @param tokenId: uint256
    /// @return True if token by it's id is staked by staker
    function isStakerOf(
        address staker,
        address stakeToken,
        uint256 tokenId
    ) public view returns (bool)
    {
        return _isStakerOf[staker][stakeToken][tokenId];
    }


    /// @notice transfers collected rewards to it's owner wallet
    /// @notice caller can claim only it's rewards
    /// @param stakeToken: address
    /// @return True if transaction is successfull
    function claimRewards(address stakeToken, uint256 amount) public virtual returns (bool)
    {
        _claimRewards(_msgSender(), stakeToken, amount);
        return true;
    }


    /// @notice stakes multiple tokens
    /// @param stakeTokens: address[]
    /// @param tokenIds: uint256[]
    /// @param tokenIdsLength: uint256[] - for gas saving
    /// it is used to set length of ids belonging to a specific stake token address
    /// otherwise it will revert 
    /// @return True if transaction is successfull
    function batchStake(
        address[] memory stakeTokens,
        uint256[] memory tokenIds,
        uint256[] memory tokenIdsLength
    ) public virtual returns (bool)
    {
        uint256 currentIndex = 0;
        address currentStakeToken = stakeTokens[0];
        uint256 nextStakeTokenStartsFrom = tokenIdsLength[0] - 1;
        
        for(uint256 i = 0; i < tokenIds.length;)
        {
            if(i > nextStakeTokenStartsFrom)
            {
                unchecked { ++currentIndex; }
                nextStakeTokenStartsFrom = i + tokenIdsLength[currentIndex] - 1;
                currentStakeToken = stakeTokens[currentIndex];
            }

            _safeStake(_msgSender(), currentStakeToken, tokenIds[i]);
            unchecked { ++i; }
        }

        return true;
    }


    /// @notice unstakes multiple tokens
    /// @param stakeTokens: address[]
    /// @param tokenIds: uint256[]
    /// @param tokenIdsLength: uint256[] - for gas saving
    /// it is used to set length of ids belonging to a specific stake token address
    /// otherwise it will revert 
    /// @return True if transaction is successfull
    function batchUnstake(
        address[] memory stakeTokens,
        uint256[] memory tokenIds,
        uint256[] memory tokenIdsLength
    ) public virtual returns (bool)
    {
        uint256 currentIndex = 0;
        address currentStakeToken = stakeTokens[0];
        uint256 nextStakeTokenStartsFrom = tokenIdsLength[0] - 1;
        
        for(uint256 i = 0; i < tokenIds.length;)
        {
            if(i > nextStakeTokenStartsFrom)
            {
                unchecked { ++currentIndex; }
                nextStakeTokenStartsFrom = i + tokenIdsLength[currentIndex] - 1;
                currentStakeToken = stakeTokens[currentIndex];
            }

            _safeUnstake(_msgSender(), currentStakeToken, tokenIds[i]);
            unchecked { ++i; }
        }

        return true;
    }


    /// @notice updates rewards of staker by specific stakeToken
    /// @param staker: address
    /// @param stakeToken: uint256
    function updateRewards(address staker, address stakeToken) public
    {
        _updateRewards(staker, stakeToken);
    }


    /// @notice updates rewards of staker by specific many stake tokens
    /// @param staker: address
    /// @param stakeTokens: uint256[]
    function batchUpdateRewards(address staker, address[] memory stakeTokens) public
    {
        for(uint256 i = 0; i < stakeTokens.length;)
        {
            _updateRewards(staker, stakeTokens[i]);
            unchecked { ++i; }
        }
    }

    //***************************** endregion: public functions *****************************//






    //***************************** startregion: internal centralization functions *****************************//

    function _addStakeToken(address newStakeToken) internal virtual
    {
        if(_isERC721Token(newStakeToken) != true)
        {
            if(newStakeToken == address(0))
            {
                revert ZeroAddress();
            }
            else if(newStakeToken == address(this))
            {
                revert ThisContractAddress();
            }

            revert NotErc721();
        }

        _isStakeToken[newStakeToken] = true;
    }

    function _removeStakeToken(address stakeToken) internal virtual
    {
        if(_isStakeToken[stakeToken] == false)
        {
            revert StakeTokenAlredyRemovedOrWasNotAdded();
        }

        delete _isStakeToken[stakeToken];
    }

    function _transferRewards(address from, address to, uint256 amount) internal 
    {
        if(rewardsOf(from) < amount)
        {
            revert TransferAmountExceedsStakerBalance();
        }

        unchecked
        {
            _rewardsOf[from] -= amount;
            _rewardsOf[to] += amount;
        }

        emit RewardsTransferred(from, to, amount);
    }

    //***************************** endregion: internal centralization functions *****************************//



    //***************************** startregion: internal hooks *****************************//

    function _safeStake(
        address staker,
        address stakeToken,
        uint256 tokenId
    ) internal
    {
        // Stake token should be ERC721 token
        bool isSupportingERC721 = _isERC721Token(stakeToken);

        if(staker == address(0))
        {
            revert ZeroAddress();
        }
        if(isSupportingERC721 != true)
        {
            revert NotErc721();
        }


        // Hook is used for additional checks or actions
        _beforeStake(staker, stakeToken, tokenId);

        _isStakerOf[staker][stakeToken][tokenId] = true;

        // update info about staker
        _incrementUserBalance(_stakedInfoOf[staker][stakeToken], tokenId);

        // Send NFT from owner to this contract
        IERC721(stakeToken).safeTransferFrom(staker, address(this), tokenId);

        // Hook is used for additional checks or actions
        _afterStake(staker, stakeToken, tokenId);


        emit StakedNFT(staker, stakeToken, tokenId);
    }


    function _safeUnstake(
        address staker,
        address stakeToken,
        uint256 tokenId
    ) internal
    {
        StakedInfoNFT storage userStakingInfo = _stakedInfoOf[staker][stakeToken];
        uint256 currentBalance = userStakingInfo.ids.length;

        if(currentBalance == 0)
        {
            revert ZeroStakerBalance();
        }
        if(isStakerOf(staker, stakeToken, tokenId) == false)
        {
            revert StakerIsNotOwnerOf(stakeToken, tokenId);
        }


        // Hook is used for additional checks or actions
        _beforeUnstake(staker, stakeToken, tokenId);

        _isStakerOf[staker][stakeToken][tokenId] = false;

        // update user balance once if balance will be zero
        // so user can release his/her rewards without loosing any
        if(currentBalance - 1 == 0)
        {
            _updateRewards(staker, stakeToken);
        }

        // update info about staker
        _decrementUserBalance(userStakingInfo, tokenId);

        // Send NFT from owner to this contract
        IERC721(stakeToken).safeTransferFrom(address(this), staker, tokenId);
        
        // Hook is used for additional checks or actions
        _afterUnstake(staker, stakeToken, tokenId);

        emit UnstakedNFT(staker, stakeToken, tokenId);
    }

    function _rewardsCalculatedHook(
        address staker,
        address stakeToken
    ) 
        internal
        virtual
        view
        returns(uint256)
    {
        uint256 balance = _stakedInfoOf[staker][stakeToken].ids.length;
        return balance;
    }

    function _timeLeft(
        uint256 currentTimestamp,
        uint256 lastTimestamp
    ) internal pure returns(uint256)
    {
        if(lastTimestamp > currentTimestamp)
        {
            revert InvalidCurrentDate();
        }

        return (currentTimestamp - lastTimestamp) / getUpdatePeriod();
    }

    function _requireStakeToken(address stakeToken) internal view 
    {
        if(_isStakeToken[stakeToken] == false)
        {
            revert TokenIsNotAvailableToStake();
        }
    }

    
    function _updateRewards(address staker, address stakeToken) internal virtual
    {
        StakedInfoNFT storage userStakingInfo = _stakedInfoOf[staker][stakeToken];
        
        uint256 currentTimestamp = block.timestamp;

        // skip if timestamp less than next period
        if(currentTimestamp <= userStakingInfo.timestamp + getUpdatePeriod())
        {
            return;
        }

        uint256 balance = userStakingInfo.ids.length;

        // skip update if balance is 0
        if(balance == 0)
        {
            return;
        }

        _rewardsOf[staker] += _rewardsCalculatedHook(staker, stakeToken) * _timeLeft(currentTimestamp, userStakingInfo.timestamp);
        
        userStakingInfo.timestamp = currentTimestamp;
    }


    function _claimRewards(
        address staker,
        address stakeToken,
        uint256 amount
    ) internal virtual
    {
        // Update staker balance to last actual
        _updateRewards(staker, stakeToken);

        uint256 stakerRewards = rewardsOf(staker);

        // Anulate user stake balance greather then zero and 
        // transfer tokens to staker or do nothing otherwise
        if(stakerRewards < amount)
        {
            revert ClaimAmountExceedBalance();
        }
        
        _rewardsOf[staker] -= amount;
        IERC20(_REWARD_TOKEN).safeTransfer(staker, amount);
        
        // emit event only when rewards can be claimed
        emit RewardsClaimed(staker, stakerRewards);
    }


    function _beforeStake(address staker, address stakeToken, uint256 tokenId) internal virtual {}
    

    function _afterStake(address staker, address stakeToken, uint256 tokenId) internal virtual {}


    function _beforeUnstake(address staker, address stakeToken, uint256 tokenId) internal virtual {}
    

    function _afterUnstake(address staker, address stakeToken, uint256 tokenId) internal virtual {}

    //***************************** endregion: internal hooks *****************************//



    //***************************** startregion: private functions *****************************//

    function _incrementUserBalance(
        StakedInfoNFT storage userStakingInfo,
        uint256 tokenId
    ) private 
    {
        if(userStakingInfo.ids.length == 0)
        {
            userStakingInfo.timestamp = block.timestamp;
        }

        userStakingInfo.idPos[tokenId] = userStakingInfo.ids.length;
        userStakingInfo.ids.push(tokenId);
    }


    function _decrementUserBalance(
        StakedInfoNFT storage userStakingInfo,
        uint256 tokenId
    ) private
    {
        uint256 lastIdPos = userStakingInfo.ids.length - 1;
        
        if(userStakingInfo.ids[lastIdPos] == tokenId)
        {
            userStakingInfo.ids.pop();
        }
        
        // as we don't know where exactly our elements are in array
        // so as we save all arr positions in mapping we can use it here
        // to exctract exact pos and save gas skipping for each search
        else
        {
            uint256 currentElemPos = userStakingInfo.idPos[tokenId];

            // do swap between current elements and last to pop from array
            uint256 tmp = userStakingInfo.ids[currentElemPos];
            userStakingInfo.ids[currentElemPos] = userStakingInfo.ids[lastIdPos];
            userStakingInfo.ids[lastIdPos] = tmp;
            
            // delete current id from array
            userStakingInfo.ids.pop();
        }


        // if current user balance is zero anulate timestamp
        if(userStakingInfo.ids.length == 0)
        {
            delete userStakingInfo.timestamp;
        }

        delete userStakingInfo.idPos[tokenId];
    }


    function _isERC721Token(address stakeToken) private view returns (bool)
    {
        bytes4 IERC721Id = type(IERC721).interfaceId;
        ERC165Checker.supportsInterface(stakeToken, IERC721Id);
        return ERC165Checker.supportsInterface(stakeToken, IERC721Id);
    }


    //***************************** endregion: private functions *****************************//
}
