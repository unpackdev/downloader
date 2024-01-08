// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Math.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./ERC1155.sol";

import "./Governable.sol";
import "./IStakingRewards.sol";

contract DeFineStakingPool is IERC1155Receiver, IStakingRewards, ReentrancyGuard, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */ 
    uint256 private _counter;
    
    struct Badge {
        address tokenAddress;
        uint256 tokenId;
        uint256 _type; //1155 for 1155;
        uint256 multiplier;
    }

    struct Pool {
        bool isInitialized;
        uint256 id;
        uint256 periodStart;
        uint256 periodFinish;
        uint256 rewardsDuration;
        uint256 rewardRate;
        uint256 totalReward;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 _totalSupply;
        uint256 _weightedTotalSupply;
        uint256 maxCount;
        uint256 maxCountPerUser;
        IERC20 rewardsToken;
        IERC20 stakingToken;
        mapping(address => uint256) _balances;
        mapping(address => uint256) _weightedBalances;
        mapping(address => uint256) userRewardPerTokenPaid;
        mapping(address => uint256) rewards;
        mapping(address => Badge[]) stakedBadges;
        mapping(address => uint256) userMultiplier;
    }
    
    mapping(uint256 => Pool) private Pools; // poolId -> Pool
    mapping(uint256 => mapping(address => mapping(uint256 => Badge))) private Badges; //poolid => token address => tokenId => Badge

    constructor(){
        super.initialize(msg.sender);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external override pure returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
    
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override pure returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == this.supportsInterface.selector;
    }
    
    function createPool(
        uint256 periodStart,
        uint256 periodFinish,
        address rewardsToken,
        address stakingToken,
        uint256 totalReward,
        uint256 maxCount,
        uint256 maxCountPerUser) external governance returns (uint256) {
            require(periodStart < periodFinish, "Start time past.");
            _counter++;
            Pool storage pool = Pools[_counter];
            
            pool.id = _counter;
            pool.isInitialized = false;
            pool.periodStart = periodStart;
            pool.periodFinish = periodFinish;
            pool.rewardsDuration = periodFinish.sub(periodStart);

            pool.lastUpdateTime = periodStart;
            pool.totalReward = totalReward;

            pool.maxCount = maxCount;
            pool.maxCountPerUser = maxCountPerUser;

            pool.rewardsToken = IERC20(rewardsToken);
            pool.stakingToken = IERC20(stakingToken);
            
            emit PoolCreated(pool.id, periodStart, periodFinish, totalReward, maxCount, maxCountPerUser, rewardsToken, stakingToken);
            return _counter;
        }
        
    function initBadge(
        uint256 _id,
        address tokenAddress,
        uint256 tokenId,
        uint256 _type, // 1155 for ERC1155
        uint256 multiplier
        ) external governance poolNotInitialized(_id) returns (bool) {
            require(_type == 1155, "Invalid Badge Type");
            require((Badges[_id][tokenAddress][tokenId].tokenAddress != tokenAddress) && (Badges[_id][tokenAddress][tokenId].tokenId != tokenId), "ERC1155 Duplicated");

            Badge memory badge = Badge(
                tokenAddress,
                tokenId,
                _type,
                multiplier);
            
            Badges[_id][tokenAddress][tokenId] = badge;
            
            emit BadgeAdded(_id, badge);
            return true;
        }
        
    function initPool(uint256 _id) override governance external poolNotInitialized (_id) {
        if (Pools[_id].periodStart < block.timestamp) {
            Pools[_id].periodStart = block.timestamp;
            Pools[_id].lastUpdateTime = block.timestamp;
            Pools[_id].rewardsDuration = Pools[_id].periodFinish - Pools[_id].periodStart;
        }
        Pools[_id].rewardRate = Pools[_id].totalReward.div(Pools[_id].rewardsDuration);
        Pools[_id].isInitialized = true;
        Pools[_id].rewardsToken.safeTransferFrom(msg.sender, address(this), Pools[_id].totalReward);
    }
    
    /* ========== VIEWS ========== */

    function totalSupply(uint256 _id) external override view returns (uint256) {
        return Pools[_id]._totalSupply;
    }

    function balanceOf(uint256 _id, address account) external override view returns (uint256) {
        return Pools[_id]._balances[account];
    }

    function lastTimeRewardApplicable(uint256 _id) public override view returns (uint256) {
        return Math.min(block.timestamp, Pools[_id].periodFinish);
    }

    function rewardPerToken(uint256 _id) public override view returns (uint256) {
        if (Pools[_id]._totalSupply == 0) {
            return Pools[_id].rewardPerTokenStored;
        }
        return
            Pools[_id].rewardPerTokenStored.add(
                lastTimeRewardApplicable(_id).sub(Pools[_id].lastUpdateTime).mul(Pools[_id].rewardRate).mul(1e18).div(Pools[_id]._weightedTotalSupply)
            );
    }

    function earned(uint256 _id, address account) public override view returns (uint256) {
        return Pools[_id]._weightedBalances[account].mul(rewardPerToken(_id).sub(Pools[_id].userRewardPerTokenPaid[account])).div(1e18).add(Pools[_id].rewards[account]);
    }

    function getRewardForDuration(uint256 _id) external override view returns (uint256) {
        return Pools[_id].rewardRate.mul(Pools[_id].rewardsDuration);
    }
    
    function whetherToStake(uint256 _id, Badge memory _badge) public view returns (bool) { // stakingBadge: badges going to be staked
        Badge[] memory badge = Pools[_id].stakedBadges[msg.sender]; // already staked badges
        if (badge.length > 0) {
            for (uint256 i = 0; i < badge.length; i++) {
                if ((badge[i].tokenAddress == _badge.tokenAddress && badge[i].tokenId == _badge.tokenId)) {
                    return false;
                }
            }
        }
        return true;
    }
    
    function setPoolStartTime(uint256 _id, uint256 _time) external governance payable poolNotInitialized(_id) returns (bool) {
        Pools[_id].periodStart = _time;
        Pools[_id].rewardsDuration = Pools[_id].periodFinish - Pools[_id].periodStart;
        return true;
    }
    
    function setPoolEndTime(uint256 _id, uint256 _time) external governance payable poolNotInitialized(_id) returns (bool) {
        Pools[_id].periodFinish = _time;
        Pools[_id].rewardsDuration = Pools[_id].periodFinish - Pools[_id].periodStart;
        return true;
    }
    
    function setRewardsToken(uint256 _id, address _address) external governance payable poolNotInitialized(_id) returns (bool) {
        Pools[_id].rewardsToken = IERC20(_address);
        return true;
    }
    
    function setStakingToken(uint256 _id, address _address) external governance payable poolNotInitialized(_id) returns (bool) {
        Pools[_id].stakingToken = IERC20(_address);
        return true;
    }

    function stake(uint256 _id, uint256 amount) override external nonReentrant poolInitialized (_id) poolIsNotFinished(_id) updateReward(msg.sender, _id) {
        require(amount > 0, "Cant stake 0");
        if (Pools[_id].userMultiplier[msg.sender] == 0) {
            Pools[_id].userMultiplier[msg.sender] = 1;
        }

        Pools[_id]._totalSupply = Pools[_id]._totalSupply.add(amount);
        require(Pools[_id]._totalSupply < Pools[_id].maxCount, "Pool is full");

        Pools[_id]._weightedTotalSupply = Pools[_id]._weightedTotalSupply.add(amount.mul(Pools[_id].userMultiplier[msg.sender]));
        
        require(Pools[_id]._balances[msg.sender].add(amount) <= Pools[_id].maxCountPerUser, "user max count reached");
        Pools[_id]._balances[msg.sender] = Pools[_id]._balances[msg.sender].add(amount);
        Pools[_id]._weightedBalances[msg.sender] = Pools[_id]._weightedBalances[msg.sender].add(amount.mul(Pools[_id].userMultiplier[msg.sender]));
        
        Pools[_id].stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, _id, amount);
    }

    function withdraw(uint256 _id, uint256 amount) override public nonReentrant poolInitialized (_id) updateReward(msg.sender, _id) {
        require(amount > 0, "Cant withdraw 0");
        uint256 weightedAmount = amount.mul(Pools[_id].userMultiplier[msg.sender]);

        Pools[_id]._totalSupply = Pools[_id]._totalSupply.sub(amount);
        Pools[_id]._weightedTotalSupply = Pools[_id]._weightedTotalSupply.sub(weightedAmount);
         
        Pools[_id]._balances[msg.sender] = Pools[_id]._balances[msg.sender].sub(amount);
        Pools[_id]._weightedBalances[msg.sender] = Pools[_id]._weightedBalances[msg.sender].sub(weightedAmount);
        
        Pools[_id].stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, _id, amount);
    }

    function getReward(uint256 _id) override public nonReentrant poolInitialized (_id) updateReward(msg.sender, _id) {
        uint256 reward = Pools[_id].rewards[msg.sender];
        if (reward > 0) {
            Pools[_id].rewards[msg.sender] = 0;
            Pools[_id].rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, _id, reward);
        }
    }
    
    /* stake badge */
    function stakeBadge(uint256 _id, address _badge, uint256 _tokenId, uint256 _type) public nonReentrant poolIsNotFinished(_id) updateReward(msg.sender, _id) {
        require(_type == 1155, "illegal type.");
        
        uint256 multiplier = Badges[_id][_badge][_tokenId].multiplier;
        require(multiplier > 0, "Badge illegal");
        Badge memory badge = Badge(_badge, _tokenId, _type, multiplier);
        require(whetherToStake(_id, badge) == true, "Badge Duplicated");
        
        IERC1155(_badge).safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
        Pools[_id].stakedBadges[msg.sender].push(badge);
        
        if (Pools[_id].userMultiplier[msg.sender] == 1) {
            Pools[_id].userMultiplier[msg.sender] = multiplier;
        } else {
            Pools[_id].userMultiplier[msg.sender] = Pools[_id].userMultiplier[msg.sender].add(multiplier);
        }
        
        uint256 newWeightedBalance = Pools[_id]._balances[msg.sender].mul(Pools[_id].userMultiplier[msg.sender]);
        Pools[_id]._weightedTotalSupply = Pools[_id]._weightedTotalSupply.sub(Pools[_id]._weightedBalances[msg.sender]).add(newWeightedBalance);
        Pools[_id]._weightedBalances[msg.sender] = newWeightedBalance;

        emit BadgeStaked(msg.sender, _id, badge);
    }
    
    function unstakeBadge(uint256 _id, address _badge, uint256 _tokenId, uint256 _type) public nonReentrant updateReward(msg.sender, _id) {
        require(_type == 1155, "illegal type");
        
        require(Pools[_id].stakedBadges[msg.sender].length > 0, "Not staked");
        Badge[] memory stakedBadges = Pools[_id].stakedBadges[msg.sender];
        Badge memory badge = Badge(_badge, _tokenId, _type, Badges[_id][_badge][_tokenId].multiplier);
        bool badgeUnstaked = false;
        
        for (uint256 i = 0; i < stakedBadges.length; i++) {
            if (stakedBadges[i].tokenAddress == _badge && stakedBadges[i].tokenId == _tokenId) {
                IERC1155(_badge).safeTransferFrom(address(this), msg.sender, _tokenId, 1, "");
                badgeUnstaked = true;
                delete Pools[_id].stakedBadges[msg.sender][i];
                break;
            }
        }
        
        require(badgeUnstaked == true, "Badge not staked.");

        if (Pools[_id].userMultiplier[msg.sender] != 1) {
            Pools[_id].userMultiplier[msg.sender] = Pools[_id].userMultiplier[msg.sender].sub((Badges[_id][_badge][_tokenId].multiplier));
            if (Pools[_id].userMultiplier[msg.sender] == 0) {
                Pools[_id].userMultiplier[msg.sender] = 1;
            }
        }
        
        uint256 newWeightedBalance = Pools[_id]._balances[msg.sender].mul(Pools[_id].userMultiplier[msg.sender]);
        
        Pools[_id]._weightedTotalSupply = Pools[_id]._weightedTotalSupply.sub(Pools[_id]._weightedBalances[msg.sender]).add(newWeightedBalance);
        Pools[_id]._weightedBalances[msg.sender] = newWeightedBalance;
        
        emit BadgeUnstaked(msg.sender, _id, badge);
    }

    modifier updateReward(address account, uint256 _id) {
        if (block.timestamp >= Pools[_id].periodStart) {
             Pools[_id].rewardPerTokenStored = rewardPerToken(_id);
            Pools[_id].lastUpdateTime = lastTimeRewardApplicable(_id);
            if (account != address(0)) {
                Pools[_id].rewards[account] = earned(_id, account);
                Pools[_id].userRewardPerTokenPaid[account] = Pools[_id].rewardPerTokenStored;
            }
        }
        _;
    }

    modifier poolNotInitialized(uint256 _id) {
        require(_id <= _counter && _id > 0, "Invalid pool id");
        require(Pools[_id].isInitialized == false, 'Pool inited.');
        _;
    }

    modifier poolInitialized(uint256 _id) {
        require(_id <= _counter && _id > 0, "Invalid pool id");
        require(Pools[_id].isInitialized == true, 'Not inited.');
        _;
    }
    
    modifier poolIsNotFinished(uint256 _id) {
        require(Pools[_id].periodFinish > block.timestamp, "Pool finished.");
        _;
    }

    event PoolCreated(uint256 _id, uint256 _periodStart, uint256 _periodFinish, uint256 _totalReward, uint256 _maxCount, uint256 _maxCountPerUser, address _rewardsToken, address _stakingToken);
    event BadgeAdded(uint256 id, Badge badge);
    event PoolInitialized(uint256 _id);
    event Staked(address indexed user, uint256 id, uint256 amount);
    event Withdrawn(address indexed user, uint256 id, uint256 amount);
    event RewardPaid(address indexed user, uint256 id, uint256 reward);
    event BadgeStaked(address indexed user, uint256 id, Badge badge);
    event BadgeUnstaked(address indexed user, uint256 id, Badge badge);
}