pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

import "./IERC20MintBurn.sol";
import "./IWrapLp.sol";
import "./WrapLp.sol";

import "./console.sol";

// This contract was not tested and fully developed yet.
// It is just a showcase and will be fully tested and finished for the NFT20.io launch

contract DuckChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct NftInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.acctokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `acctokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. tokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that tokens distribution occurs.
        uint256 accTokenPerShare; // Accumulated tokens per share, times 1e12. See below.
    }
    // The token TOKEN!
    IERC20MintBurn public token;

    // the wrapLp Contract
    IWrapLp public wrapLp;

    // Dev address.
    address public devaddr;
    // Block number when bonus token period ends.
    uint256 public bonusEndBlock;
    // token tokens created per block.
    uint256 public tokenPerBlock;
    // Bonus muliplier for early token makers.
    uint256 public constant BONUS_MULTIPLIER = 10;
    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each NFT that registered to get rewards.
    mapping(uint256 => NftInfo) public nftInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when token mining starts.
    uint256 public startBlock;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        IERC20MintBurn _token,
        IWrapLp _wrapLp,
        address _devaddr,
        uint256 _tokenPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        token = _token;
        wrapLp = _wrapLp;
        devaddr = _devaddr;
        tokenPerBlock = _tokenPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accTokenPerShare: 0
            })
        );
    }

    // Update the given pool's token allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    // View function to see pending tokens on frontend.
    function pendingToken(uint256 _pid, uint256 _nftId)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        NftInfo storage nft = nftInfo[_nftId];
        console.log("amount", nft.amount);
        uint256 accTokenPerShare = pool.accTokenPerShare;
        console.log("accTokenPerShare", accTokenPerShare);

        uint256 lpSupply = wrapLp.totalStaked(address(pool.lpToken));

        console.log("lpSupply", lpSupply);

        // uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward =
                multiplier.mul(tokenPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accTokenPerShare = accTokenPerShare.add(
                tokenReward.mul(1e12).div(lpSupply)
            );

            console.log("accTokenPerShare", accTokenPerShare);
        }

        console.log(
            "last",
            nft.amount.mul(accTokenPerShare).div(1e12).sub(nft.rewardDebt)
        );
        console.log("nft.rewardDebt", nft.rewardDebt);

        return nft.amount.mul(accTokenPerShare).div(1e12).sub(nft.rewardDebt);
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

        uint256 lpSupply = wrapLp.totalStaked(address(pool.lpToken));
        // uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward =
            multiplier.mul(tokenPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        token.mint(devaddr, tokenReward.div(10));
        token.mint(address(this), tokenReward);
        pool.accTokenPerShare = pool.accTokenPerShare.add(
            tokenReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Register WrapLp token to DuckChef for $TOKEN allocation.
    function register(uint256 _pid, uint256 _nftId) public {
        PoolInfo storage pool = poolInfo[_pid];
        (address _erc20address, uint256 _amount, ) = wrapLp.getNFTInfo(_nftId);
        require(_erc20address == address(pool.lpToken), "NFT don't match pool");
        require(wrapLp.ownerOf(_nftId) == msg.sender, "!owner");
        NftInfo storage nft = nftInfo[_nftId];

        require(nft.amount == 0, "Can't register twice");

        updatePool(_pid);

        nft.amount = _amount;

        // @Maybe we can ake this out as it will be by single NFT each time and when withdraw
        // NFT info is deleted.

        // TODO! check this, without this was returning 0 all the time.
        // nft.rewardDebt = nft.amount.mul(pool.accTokenPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _nftId);
    }

    // Withdraw all earnings and unregister NFT.
    function withdraw(uint256 _pid, uint256 _nftId) public {
        PoolInfo storage pool = poolInfo[_pid];
        // does nft token match pool?
        (address _erc20address, , ) = wrapLp.getNFTInfo(_nftId);
        require(_erc20address == address(pool.lpToken), "NFT don't match pool");
        // make sure msg.sender is owner of nft
        require(wrapLp.ownerOf(_nftId) == msg.sender, "!owner");
        NftInfo storage nft = nftInfo[_nftId];

        updatePool(_pid);
        uint256 pending =
            nft.amount.mul(pool.accTokenPerShare).div(1e12).sub(nft.rewardDebt);
        if (pending > 0) {
            safeTokenTransfer(msg.sender, pending);
        }

        // delete this NFT as it is paying off all earnings up until this point.
        delete nftInfo[_nftId];

        emit Withdraw(msg.sender, _pid, _nftId);
    }

    //if staker owned many NFTs with same lp tokens use batch withdraw
    function withdrawBatch(uint256 _pid, uint256[] memory _nftIds) public {
        for (uint256 i = 0; i < _nftIds.length; i++) {
            withdraw(_pid, _nftIds[i]);
        }
    }

    // Safe token transfer function, just in case if rounding error causes pool to not have enough tokens.
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = token.balanceOf(address(this));
        if (_amount > tokenBal) {
            token.transfer(_to, tokenBal);
        } else {
            token.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}
