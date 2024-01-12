// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

abstract contract CosmoGang is IERC721, Ownable
{    
    function main_address() public virtual returns (address);
    function isHolder(address addr) public virtual returns (bool);
    function tokenIdExists(uint256 tokenId) public virtual returns (bool);
    function totalSupply() public virtual returns (uint256);
}

contract CosmoGangStaking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public rewardsToken;
    // IERC721 public nftCollection;
    CosmoGang public nftCollection;

    struct Staker
    {
        // uint256 amountStaked;
        uint256[] stakedTokenIds;
        uint256 timeOfLastUpdate;
        uint256 unclaimedRewards;
    }

    uint256 private rewardsPerHour = 208300000000000000; // = 0.20830
    uint256 public totalStaked = 0;
    mapping(address => uint256) public stakerRewardsPerHour;
    mapping(address => Staker) public stakers;
    mapping(uint256 => address) public stakerAddress;
    mapping(address => bool) public approvedAddresses;

    // constructor(IERC721 _nftCollection, IERC20 _rewardsToken)
    constructor(address _nftCollection, IERC20 _rewardsToken)
    {
        // nftCollection = _nftCollection;
        nftCollection = CosmoGang(_nftCollection);
        rewardsToken = _rewardsToken;
    }

    modifier onlyApproved()
    {
        require(msg.sender == owner() || approvedAddresses[msg.sender], "caller is not approved");
        _;
    }

    // function setNftCollection(IERC721 addr)
    function setNftCollection(address addr)
        external onlyOwner
    {
        // nftCollection = addr;
        nftCollection = CosmoGang(addr);
    }

    function setRewardsToken(IERC20 addr)
        external onlyOwner
    {
        rewardsToken = addr;
    }

    function stake(uint256[] calldata _tokenIds)
        external nonReentrant
    {
        require(nftCollection.isApprovedForAll(msg.sender, address(this)), "You have to approve staking contract first!");
        // if (stakers[msg.sender].amountStaked > 0)
        // if (stakers[msg.sender].stakedTokenIds.length > 0)
        if (getUserTotalStaked(msg.sender) > 0)
        {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
        }
        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; i++)
        {
            require(nftCollection.tokenIdExists(_tokenIds[i]), "Can't stake tokens that doesn't exists");
            require(nftCollection.ownerOf(_tokenIds[i]) == msg.sender, "Can't stake tokens you don't own!");
            nftCollection.transferFrom(msg.sender, address(this), _tokenIds[i]);
            stakerAddress[_tokenIds[i]] = msg.sender;
            stakers[msg.sender].stakedTokenIds.push(_tokenIds[i]);
        }
        // stakers[msg.sender].amountStaked += len;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        totalStaked += len;
    }

    function _withdraw(uint256[] memory _tokenIds, bool calledBySender, address receiver)
        private nonReentrant
    {
        require(!calledBySender || (calledBySender && receiver == msg.sender), "calledBySender set to true and caller is not the receiver");
        require(getUserTotalStaked(receiver) > 0, "Nothing to withdraw");

        uint256 rewards = calculateRewards(receiver);
        stakers[receiver].unclaimedRewards += rewards;
        uint256 len = _tokenIds.length;
        uint256 totalUnstaked = 0;
        for (uint256 i; i < len; i++)
        {
            uint256 tokenId = _tokenIds[i];
            if (tokenId == 0)
            {
                continue;
            }
            require((calledBySender && stakerAddress[tokenId] == receiver) ||
                !calledBySender, "Can't withdraw staking amount of token you don't own!");
            stakerAddress[tokenId] = address(0);
            nftCollection.transferFrom(address(this), receiver, tokenId);
            totalUnstaked += 1;
        }

        uint256 currentStakedNfts = stakers[receiver].stakedTokenIds.length;
        uint256[] memory newStakedTokenIds = new uint256[](getUserTotalStaked(receiver));
        for (uint256 i; i < currentStakedNfts; i++)
        {
           uint256 tokenId = stakers[receiver].stakedTokenIds[i];
           if (tokenId == 0)
           {
               continue;
           }
           if (stakerAddress[tokenId] == receiver)
           {
               newStakedTokenIds[i] = tokenId;
           }
        }
        // stakers[receiver].amountStaked -= len;
        stakers[receiver].stakedTokenIds = newStakedTokenIds;
        stakers[receiver].timeOfLastUpdate = block.timestamp;
        totalStaked -= totalUnstaked;
    }

    function withdraw(uint256[] calldata _tokenIds)
        external
    {
        // require(stakers[msg.sender].amountStaked > 0, "You have no tokens staked");
        // require(stakers[msg.sender].stakedTokenIds.length > 0, "You have no tokens staked");
        require(getUserTotalStaked(msg.sender) > 0, "You have no tokens staked");
        _withdraw(_tokenIds, true, msg.sender);
    }

    function withdrawAll(uint256[][] calldata _tokenIds, address[] calldata receivers)
        external onlyOwner
    {
        for (uint256 i = 0; i < receivers.length; i++)
        {
            uint256[] calldata receiverTokenIds = _tokenIds[i];
            address receiver = receivers[i];
            _withdraw(receiverTokenIds, false, receiver);
        }
    }

    function withdrawAllFromAddress(address _staker)
        public 
    {
        uint256[] storage stakedTokenIds = stakers[_staker].stakedTokenIds;
        _withdraw(stakedTokenIds, true, _staker);
    }

    function withdrawAllFromAddresses(address[] memory _stakers)
        external onlyOwner
    {
        for (uint256 i = 0; i < _stakers.length; i++)
        {
            address staker = _stakers[i];
            uint256[] storage stakedTokenIds = stakers[staker].stakedTokenIds;
            _withdraw(stakedTokenIds, false, staker);
        }
    }

    function _claimRewards(address receiver)
        private
    {
        uint256 rewards = calculateRewards(receiver) + stakers[receiver].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");
        stakers[receiver].timeOfLastUpdate = block.timestamp;
        stakers[receiver].unclaimedRewards = 0;
        // rewardsToken.safeTransfer(receiver, rewards);
        rewardsToken.safeTransferFrom(address(rewardsToken), receiver, rewards);
    }

    function claimRewards()
        external
    {
        _claimRewards(msg.sender);
    }

    function claimAllRewards(address[] calldata receivers)
        external onlyOwner
    {
        for (uint256 i = 0; i < receivers.length; i++)
        {
            address receiver = receivers[i];
            _claimRewards(receiver);
        }
    }

    // Set the rewardsPerHour variable
    function setRewardsPerHour(uint256 _newValue)
        public onlyOwner
    {
         rewardsPerHour = _newValue;
    }

    // Set the rewardsPerHour variable
    function setStakerRewardsPerHour(address _staker, uint256 _newValue)
        public onlyApproved
    {
         stakerRewardsPerHour[_staker] = _newValue;
    }

    function userStakeInfo(address _user)
        public
        view
        returns (uint256 _tokensStaked, uint256 _availableRewards, uint256[] memory _tokenIds)
    {
        // return (stakers[_user].amountStaked, availableRewards(_user));
        // return (stakers[_user].stakedTokenIds.length, availableRewards(_user), stakers[_user].stakedTokenIds);
        return (getUserTotalStaked(_user), availableRewards(_user), stakers[_user].stakedTokenIds);
    }

    function availableRewards(address _user)
        internal view returns (uint256)
    {
        uint256 _rewards = stakers[_user].unclaimedRewards + calculateRewards(_user);
        return _rewards;
    }

    // Calculate rewards for param _staker by calculating the time passed
    // since last update in hours and mulitplying it to ERC721 Tokens Staked
    // and rewardsPerHour.
    function calculateRewards(address _staker)
        internal view
        returns (uint256 _rewards)
    {
        uint256 currentRewardPerHour = 0;
        if (stakerRewardsPerHour[_staker] == 0)
        {
            currentRewardPerHour = rewardsPerHour;
        }
        else
        {
            currentRewardPerHour = stakerRewardsPerHour[_staker];
        }

        // return (((((block.timestamp - stakers[_staker].timeOfLastUpdate) * stakers[_staker].amountStaked)) * currentRewardPerHour) / 3600);
        // return (((((block.timestamp - stakers[_staker].timeOfLastUpdate) * stakers[_staker].stakedTokenIds.length)) * currentRewardPerHour) / 3600);
        return (((((block.timestamp - stakers[_staker].timeOfLastUpdate) * getUserTotalStaked(_staker))) * currentRewardPerHour) / 3600);
    }

    function addApprovedAddress(address addr)
        external onlyOwner
    {
        approvedAddresses[addr] = true;
    }

    function getTokenBalanceOf(address addr)
        external view
        returns (uint256)
    {
        return rewardsToken.balanceOf(addr);
    }

    function getUserTotalStaked(address addr)
        public view
        returns (uint256)
    {
        uint256 _totalStaked = 0;
        for (uint256 i = 0; i < stakers[addr].stakedTokenIds.length; i++)
        {
            if (stakers[addr].stakedTokenIds[i] != 0)
            {
                _totalStaked += 1;
            }
        }
        return _totalStaked;
    }

    function setNftAllowance(address spender)
        external onlyOwner
    {
        // Need to encapsulate the contract in CosmoGangStaking() so that it makes an EXTERNAL call
        // So that this Staking Contract contract itself approve the spender, and not the msg.sender of this function
        CosmoGangStaking.nftCollection.setApprovalForAll(spender, true);
    }
}