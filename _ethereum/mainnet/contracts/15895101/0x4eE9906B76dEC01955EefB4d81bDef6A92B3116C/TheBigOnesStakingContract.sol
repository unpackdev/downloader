// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";

//████████╗██╗░░██╗███████╗  ██████╗░██╗░██████╗░  ░█████╗░███╗░░██╗███████╗░██████╗
//╚══██╔══╝██║░░██║██╔════╝  ██╔══██╗██║██╔════╝░  ██╔══██╗████╗░██║██╔════╝██╔════╝
//░░░██║░░░███████║█████╗░░  ██████╦╝██║██║░░██╗░  ██║░░██║██╔██╗██║█████╗░░╚█████╗░
//░░░██║░░░██╔══██║██╔══╝░░  ██╔══██╗██║██║░░╚██╗  ██║░░██║██║╚████║██╔══╝░░░╚═══██╗
//░░░██║░░░██║░░██║███████╗  ██████╦╝██║╚██████╔╝  ╚█████╔╝██║░╚███║███████╗██████╔╝
//░░░╚═╝░░░╚═╝░░╚═╝╚══════╝  ╚═════╝░╚═╝░╚═════╝░  ░╚════╝░╚═╝░░╚══╝╚══════╝╚═════╝░

//WEBSITE: https://www.thebigonesociety.com

contract TheBigOnesStaking is ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;

    uint256 public minimumStakingTime = 6;
    uint256 private rewardsPerHour = 625000000000000000;

    IERC721 public immutable nftCollection;
    IERC20 public immutable rewardsToken;


    constructor(IERC721 _nftCollection, IERC20 _rewardsToken) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        rewardsToken = _rewardsToken;
        nftCollection = _nftCollection;
    }

    struct StakedToken {
        address staker;
        uint256 tokenId;
        uint256 tokenStoreTime;
    }
    
    struct Staker {
        uint256 amountStaked;

        StakedToken[] stakedTokens;

        uint256 timeOfLastUpdate;
        uint256 timeOfStake;

        uint256 unclaimedRewards;
    }


    mapping(address => Staker) public stakers;
    mapping(uint256 => address) public stakerAddress;


    function setMinimumStakingHours (uint _hours) public onlyRole(DEFAULT_ADMIN_ROLE) {
        minimumStakingTime = _hours;
    }

    function setRewardPerHour (uint _reward) public onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardsPerHour = _reward;
    }

    function availableRewards(address _staker) public view returns (uint256) {
        uint256 rewards = calculateRewards(_staker) +
            stakers[_staker].unclaimedRewards;
        return rewards;
    }

    function getStakedTokens(address _user) public view returns (StakedToken[] memory) {
        if (stakers[_user].amountStaked > 0) {
            unchecked {
                StakedToken[] memory _stakedTokens = new StakedToken[](stakers[_user].amountStaked);
                uint256 _index = 0;

                for (uint256 j = 0; j < stakers[_user].stakedTokens.length; j++) {
                    if (stakers[_user].stakedTokens[j].staker != (address(0))) {
                        _stakedTokens[_index] = stakers[_user].stakedTokens[j];
                        _index++;
                    }
                }

                return _stakedTokens;
            }
        }
        
        else {
            return new StakedToken[](0);
        }
    }

    function stake(uint256[] calldata _tokenIds) external nonReentrant {
        if (stakers[msg.sender].amountStaked > 0) {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
        }

        unchecked {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                _stake(_tokenIds[i]);
            }
        }

        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    function _stake(uint _tokenId) internal {
        require(
            nftCollection.ownerOf(_tokenId) == msg.sender,
            "You don't own this token!"
        );

        unchecked {
            nftCollection.transferFrom(msg.sender, address(this), _tokenId);

            StakedToken memory stakedToken = StakedToken(msg.sender, _tokenId, block.timestamp);

            stakers[msg.sender].stakedTokens.push(stakedToken);

            stakers[msg.sender].amountStaked++;

            stakerAddress[_tokenId] = msg.sender;
        }
    }

    function withdraw(uint256[] calldata _tokenIds) external nonReentrant {
        require(
            stakers[msg.sender].amountStaked > 0,
            "You have no tokens staked"
        );
        
        uint256 rewards = calculateRewards(msg.sender);
        stakers[msg.sender].unclaimedRewards += rewards;

        unchecked {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                _withdraw(_tokenIds[i]);
            }
        }

        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }
    
    function _withdraw(uint256 _tokenId) internal {
        require(stakerAddress[_tokenId] == msg.sender, "You don't own this token!");
        uint256 index = 0;
        unchecked {
            for (uint256 i = 0; i < stakers[msg.sender].stakedTokens.length; i++) {
                if (stakers[msg.sender].stakedTokens[i].tokenId == _tokenId) {
                    index = i;
                    break;
                }
            }
        }

        require(stakers[msg.sender].stakedTokens[index].tokenStoreTime + (minimumStakingTime * 1 hours) <= block.timestamp, "You cannot withdraw before minimum staking time is passed !");
        stakers[msg.sender].stakedTokens[index].staker = address(0);

        stakers[msg.sender].amountStaked--;

        stakerAddress[_tokenId] = address(0);

        nftCollection.transferFrom(address(this), msg.sender, _tokenId);
    }

    function claimRewards() external {
        uint256 rewards = calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;
        rewardsToken.safeTransfer(msg.sender, rewards);
    }

    function calculateRewards(address _staker)
        internal
        view
        returns (uint256 _rewards)
    {
        return (((
            ((block.timestamp - stakers[_staker].timeOfLastUpdate) *
                stakers[_staker].amountStaked)
        ) * rewardsPerHour) / 3600);
    }
}