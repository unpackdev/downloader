pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./ERC20.sol";

// import "./console.sol";

import "./IVNFT.sol";

interface IMigratorChef {
    // Perform LP token migration from legacy UniswapV2 to SushiSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // SushiSwap must mint EXACTLY the same amount of SushiSwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

import "./IERC721.sol";

contract VnftLp is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 vnftId; //he needs to provide a pet id that will have to stay alive for him to keep getting reward
        //how many pets address redeemed in pool

        uint256 redeemed;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Points to distribute per block.
        uint256 lastRewardBlock; // Last block number that Points distribution occurs.
        uint256 accPointsPerShare; // Accumulated points per share, times 1e12. See below.
    }

    // The vNFTs
    IVNFT public vnft;

    // Block number when bonus Points period ends.
    uint256 public bonusEndBlock;
    // Points created per block.
    uint256 public pointsPerBlock;
    // points needed to withdraw vnft
    uint256 public vnftPrice = 400 * 10**18;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;

    // Bonus muliplier for early Point makers.
    uint256 public constant BONUS_MULTIPLIER = 10;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when Points mining starts.
    uint256 public startBlock;

    mapping(uint256 => uint256) public vnftRedeemed;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Redeem(address indexed user, uint256 indexed pid, uint256 newvnftid);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(uint256 _pointsPerBlock, address _vnft) public {
        pointsPerBlock = _pointsPerBlock;
        vnft = IVNFT(_vnft);
        // bonusEndBlock = block.number.add(46523);
        bonusEndBlock = 2;
        // startBlock = block.number;
        startBlock = 1;
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
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accPointsPerShare: 0
            })
        );
    }

    // Update the given pool's Points allocation point. Can only be called by the owner.
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

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
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

    // View function to see pending Points on frontend.
    function pendingPoints(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        // if the staker doesn't own an nft then return 0 reward.
        if (vnft.balanceOf(_user) == 0) {
            return 0;
        } else {
            PoolInfo storage pool = poolInfo[_pid];
            UserInfo storage user = userInfo[_pid][_user];
            uint256 accPointsPerShare = pool.accPointsPerShare;

            uint256 lpSupply = pool.lpToken.balanceOf(address(this));

            if (block.number > pool.lastRewardBlock && lpSupply != 0) {
                uint256 multiplier = getMultiplier(
                    pool.lastRewardBlock,
                    block.number
                );

                uint256 pointsReward = multiplier
                    .mul(pointsPerBlock)
                    .mul(pool.allocPoint)
                    .div(totalAllocPoint);

                accPointsPerShare = accPointsPerShare.add(
                    pointsReward.mul(1e12).div(lpSupply)
                );
            }
            return
                user.amount.mul(accPointsPerShare).div(1e12).sub(user.redeemed);
        }
    }

    // Update reward vairables for all pools. Be careful of gas spending!
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
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);

        uint256 pointsReward = multiplier
            .mul(pointsPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        pool.accPointsPerShare = pool.accPointsPerShare.add(
            pointsReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for points allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        // require to own at least one vNFT
        require(
            vnft.balanceOf(msg.sender) > 0,
            "You must own at least 1 vNFT to stake"
        );
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        user.amount = user.amount.add(_amount);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function redeem(uint256 _pid) public {
        // if he doesn't own a vNFT when withdrawing, send him stake without rewards
        if (vnft.balanceOf(msg.sender) == 0) {
            withdraw(_pid);
        } else {
            updatePool(_pid);

            UserInfo storage user = userInfo[_pid][msg.sender];

            uint256 pending = pendingPoints(_pid, msg.sender);

            require(
                pending >= vnftPrice,
                "You don't have enough points to redeem"
            );
            // here mints nft
            vnft.mint(msg.sender);
            uint256 newvnftid = vnft.tokenOfOwnerByIndex(address(msg.sender), vnft.balanceOf(address(msg.sender)) - 1);
            vnftRedeemed[newvnftid] = block.number;

            user.redeemed = user.redeemed.add(vnftPrice);

            emit Redeem(msg.sender, _pid, newvnftid);
        }
    }

    // Withdraw without rewards.
    function withdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.redeemed = 0;
    }

    function setPointsPerBlock(uint256 _pointsPerBlock) public onlyOwner {
        pointsPerBlock = _pointsPerBlock;
    }

    function setVnftPrice(uint256 _vnftPrice) public onlyOwner {
        vnftPrice = _vnftPrice * 10**18;
    }
}
