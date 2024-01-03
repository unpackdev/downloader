// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./KingToken.sol";

interface IMigratorChef {
    // Perform LP token migration from legacy UniswapV2 to KingSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // KingSwap must mint EXACTLY the same amount of KingSwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

// Archbishop will crown the King and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once KING is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract Archbishop is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of KINGs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accKingPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accKingPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. KINGs to distribute per block.
        uint256 lastRewardBlock; // Last block number that KINGs distribution occurs.
        uint256 accKingPerShare; // Accumulated KINGs per share, times 1e12. See below.
    }

    // The KING TOKEN!
    KingToken public king;

    // Stakeholder Address
    address public stakeholderaddress;
    // Block number when bonus KING period ends.
    uint256 public bonusEndBlock;
    // KING tokens created per block.
    uint256 public kingPerBlock;
    // Mintage End Bloc
    uint256 public mintEndBlock;
    // Bonus muliplier for early king makers.
    uint256 public constant BONUS_MULTIPLIER = 10;
    // Bonus block num,about 15 days.
    uint256 public constant BONUS_BLOCKNUM = 100000; // testing value = 200 real value = 100000
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Record whether the pair has been added.
    mapping(address => uint256) public lpTokenPID;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when KING mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        KingToken _king,
        address _stakeholderaddress,
        uint256 _kingPerBlock
    ) public {
        king = _king;
        stakeholderaddress = _stakeholderaddress;
        kingPerBlock = _kingPerBlock;
        startBlock = block.number + 1400;
        bonusEndBlock = startBlock.add(BONUS_BLOCKNUM);
        mintEndBlock = startBlock.add(BONUS_BLOCKNUM);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        require(lpTokenPID[address(_lpToken)] == 0, "Archbishop:duplicate add.");
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        require(poolInfo.length <= 100, "Excess pool in Pool storage, has reached 100 limit");
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accKingPerShare: 0
            })
        );
        lpTokenPID[address(_lpToken)] = poolInfo.length;
    }

    // Update the given pool's KING allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
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
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        uint256 _toFinal = _to > mintEndBlock ? mintEndBlock : _to;

        if(_from < mintEndBlock){
            if (_toFinal <= bonusEndBlock) {
                return _toFinal.sub(_from).mul(BONUS_MULTIPLIER);
            } else if (_from >= bonusEndBlock) {
                return _toFinal.sub(_from);
            } else {
                return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _toFinal.sub(bonusEndBlock)
                );
            }
        }else{
            return 0;
        }
    }

    // View function to see pending KINGs on frontend.
    function pendingKing(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accKingPerShare = pool.accKingPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 kingReward = multiplier.mul(kingPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            uint256 kingReward2nd = kingReward.mul(9).div(25);
            
            kingReward = kingReward.sub(kingReward2nd);
            uint256 balance = 0;

            // Balance in Archbishop less than 10 due to corrections will be placed back into pool.
            if(king.balanceOf(address(this))  <= 10){
                balance = king.balanceOf(address(this));
            }

            accKingPerShare = accKingPerShare.add(kingReward.add(balance).mul(1e12).div(lpSupply));
            
        }
        return user.amount.mul(accKingPerShare).div(1e12).sub(user.rewardDebt);
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
        if (multiplier == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        
        
        // King Rewards meant for Community
        uint256 kingReward = multiplier.mul(kingPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        // King Rewards meant for Stake Holders
        
        uint256 kingReward2nd = kingReward.mul(9).div(25);

        kingReward = kingReward.sub(kingReward2nd);

        uint256 balance = 0;

        // Balance in Archbishop less than 10 due to corrections will be placed back into pool.
        if(king.balanceOf(address(this))  <= 10){
            balance = king.balanceOf(address(this));
        }

        king.mint(stakeholderaddress, kingReward2nd);
        king.mint(address(this), kingReward);

        pool.accKingPerShare = pool.accKingPerShare.add(kingReward.add(balance).mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;

    }

    // Deposit LP tokens to Archbishop for KING allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accKingPerShare).div(1e12).sub(user.rewardDebt);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accKingPerShare).div(1e12);
        if (pending > 0) safeKingTransfer(msg.sender, pending);
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from Archbishop.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accKingPerShare).div(1e12).sub(user.rewardDebt);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accKingPerShare).div(1e12);
        safeKingTransfer(msg.sender, pending);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY. // what is the difference?
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0, "emergencyWithdraw: not good");
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    // Safe king transfer function, just in case if rounding error causes pool to not have enough KINGs.
    function safeKingTransfer(address _to, uint256 _amount) internal {
        uint256 kingBal = king.balanceOf(address(this));
        if (_amount > kingBal) {
            king.transfer(_to, kingBal);
        } else {
            king.transfer(_to, _amount);
        }
    }



    // Update dev address by the previous dev.
    function stakeholder(address _stakeholderaddress) public {
        require(msg.sender == stakeholderaddress, "stakeholder: wut?");
        stakeholderaddress = _stakeholderaddress;
    }

    function transferOwnerShipKingToken(address _newOwner) public onlyOwner{
        king.transferOwnership(_newOwner);

    }
    //Once change must wait till block no passes Mint End Block
    function changeMintEndBlock(uint _amount) public onlyOwner{
        require(block.number >= mintEndBlock, "mint end block has not ended");
        mintEndBlock = _amount;
    }
    //Once change must wait till block no passes Bonus End Block. Please change Bonus End Block first before changing Mint End Block
    function changeBonusEndBlock(uint _amount) public onlyOwner{
        require(block.number >= bonusEndBlock, "bonus end block has not ended");
        require(block.number >= mintEndBlock, "mint end block has not ended");
        bonusEndBlock = _amount;
    }


}
