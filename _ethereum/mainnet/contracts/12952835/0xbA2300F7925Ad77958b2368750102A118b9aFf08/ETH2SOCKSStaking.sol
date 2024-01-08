// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./RewardToken.sol";

contract ETH2SOCKSStaking is Ownable, IERC721Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    struct UserInfo {
        uint256 tokensStaked;
        uint256 rewardDebt;
        uint[] stakedNFTIds;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC721 nftToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accRewardTokenPerShare;
    }

    RewardToken public rewardToken;
    // tokens created per block.
    uint256 public rewardTokenPerBlock;
    // Bonus multipler for early stakers.
    uint256 public constant BONUS_MULTIPLIER = 1;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes nft tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when mining starts.
    uint256 public startBlock;

    event Activate(address indexed user, uint256 indexed pid, uint256 nftId);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 nftId);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 nftId);

    bool private initialized = false;

    constructor() {}

    function initialize(RewardToken _rewardToken, uint256 _rewardTokenPerBlock, uint256 _startBlock) public onlyOwner {
        require(initialized == false);
        rewardToken = _rewardToken;
        rewardTokenPerBlock = _rewardTokenPerBlock;
        startBlock = _startBlock;
        initialized = true;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new nft to the pool. Can only be called by the owner.
    // XXX DO NOT add the same nft token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC721 _nftToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
        nftToken : _nftToken,
        allocPoint : _allocPoint,
        lastRewardBlock : lastRewardBlock,
        accRewardTokenPerShare : 0
        }));
    }

    // Update the given pool's allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending rewards on frontend.
    function pendingRewardTokens(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardTokenPerShare = pool.accRewardTokenPerShare;
        uint256 nftSupply = pool.nftToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && nftSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 rewardTokenReward = multiplier.mul(rewardTokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accRewardTokenPerShare = accRewardTokenPerShare.add(rewardTokenReward.mul(1e12).div(nftSupply));
        }

        if (user.tokensStaked == 0) {
            return 0;
        }
        return user.tokensStaked.mul(accRewardTokenPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 nftSupply = pool.nftToken.balanceOf(address(this));
        if (nftSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 rewardTokenReward = multiplier.mul(rewardTokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        rewardToken.mint(address(this), rewardTokenReward);
        pool.accRewardTokenPerShare = pool.accRewardTokenPerShare.add(rewardTokenReward.mul(1e12).div(nftSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit nft tokens to staking for allocation.
    function deposit(uint256 _pid, uint256 _tokenId) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(_tokenId > 0, "Unable to stake. Invalid NFT.");

        updatePool(_pid);
        pool.nftToken.safeTransferFrom(address(msg.sender), address(this), _tokenId);
        user.stakedNFTIds.push(_tokenId);
        user.tokensStaked = user.stakedNFTIds.length;
        user.rewardDebt = user.tokensStaked.mul(pool.accRewardTokenPerShare).div(1e12);


        emit Activate(msg.sender, _pid, _tokenId);
    }

    function withdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.tokensStaked > 0, "withdraw: not good");

        updatePool(_pid);

        uint256 pending = user.tokensStaked.mul(pool.accRewardTokenPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeRewardTokenTransfer(msg.sender, pending);
        }

        for (uint i = 0; i < user.stakedNFTIds.length; i++) {
            pool.nftToken.safeTransferFrom(address(this), address(msg.sender), user.stakedNFTIds[i]);
            emit Withdraw(msg.sender, _pid, user.stakedNFTIds[i]);
        }

        delete user.stakedNFTIds;
        user.tokensStaked = 0;
        user.rewardDebt = 0;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.tokensStaked > 0, "withdraw: no good");
        for (uint i = 0; i < user.stakedNFTIds.length; i++) {
            pool.nftToken.safeTransferFrom(address(this), address(msg.sender), user.stakedNFTIds[i]);
            emit EmergencyWithdraw(msg.sender, _pid, user.stakedNFTIds[i]);
        }
        user.tokensStaked = 0;
        delete user.stakedNFTIds;
        user.rewardDebt = 0;
    }

    function harvest(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.tokensStaked > 0, "Harvest: no good");
        updatePool(_pid);
        uint256 pending = user.tokensStaked.mul(pool.accRewardTokenPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeRewardTokenTransfer(msg.sender, pending);
            user.rewardDebt = user.tokensStaked.mul(pool.accRewardTokenPerShare).div(1e12);
            emit Harvest(msg.sender, _pid, pending);
        }
    }

    // Safe transfer function, just in case if rounding error causes pool to not have enough.
    function safeRewardTokenTransfer(address _to, uint256 _amount) internal {
        uint256 rewardTokenBal = rewardToken.balanceOf(address(this));
        if (_amount > rewardTokenBal) {
            rewardToken.transfer(_to, rewardTokenBal);
        } else {
            rewardToken.transfer(_to, _amount);
        }
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        return MAGIC_ON_ERC721_RECEIVED;
    }

    function setRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner returns (uint256) {
        require(_rewardPerBlock > 0, "Reward must be greater than 0.");
        massUpdatePools();
        rewardTokenPerBlock = _rewardPerBlock;
        return rewardTokenPerBlock;
    }

}
