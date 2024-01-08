// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./Initializable.sol";
import "./Ownable.sol";


//import "./console.sol";

interface IMigratorChef {
    // Perform LP token migration from legacy PactSwap to PactSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to PactSwap LP tokens.
    // PactSwap must mint EXACTLY the same amount of PactSwap LP tokens or
    // else something bad will happen. Traditional PactSwap does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}



// MasterChef is the master of Pact. He can make Pact and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once PACT is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChefEthereum is Initializable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of PACTs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accPactPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accPactPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. PACTs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that PACTs distribution occurs.
        uint256 accPactPerShare; // Accumulated PACTs per share, times 1e12. See below.
    }

    // The PACT TOKEN!
    IERC20 public pact;
    // PACT tokens created per block.
    uint256 public pactPerBlock;
    // Bonus muliplier for early pact makers.
    uint256 public BONUS_MULTIPLIER;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when PACT mining starts.
    uint256 public startBlock;
    // The block number when PACT mining stop.
    uint256 public endBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    function initialize(
        IERC20 _pact,
        uint256 _startBlock,
        uint256 _endBlock

    ) public payable initializer  {
        pact = _pact;
        startBlock = _startBlock;
        endBlock = _endBlock;
        uint256 pactBal = pact.balanceOf(address(this));
        pactPerBlock = pactBal.div(_endBlock.sub(startBlock));
        BONUS_MULTIPLIER = 1;
        _initialize();
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
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
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accPactPerShare: 0
        }));

    }

    // Update the given pool's PACT allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);

        }
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
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending PACTs on frontend.
    function pendingPact(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPactPerShare = pool.accPactPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint256  blockNumber = block.number;

        if (block.number > endBlock){
            blockNumber = endBlock;
        }

        if (blockNumber > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, blockNumber);
            uint256 pactReward = multiplier.mul(pactPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accPactPerShare = accPactPerShare.add(pactReward.mul(1e12).div(lpSupply));
        }

        return user.amount.mul(accPactPerShare).div(1e12).sub(user.rewardDebt);
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

        uint256  blockNumber = block.number;

        if (block.number > endBlock){
            blockNumber = endBlock;
        }

        if (blockNumber <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = blockNumber;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, blockNumber);
        uint256 pactReward = multiplier.mul(pactPerBlock).mul(pool.allocPoint).div(totalAllocPoint);


        pool.accPactPerShare = pool.accPactPerShare.add(pactReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = blockNumber;
    }

    // Deposit LP tokens to MasterChef for PACT allocation.
    function deposit(uint256 _pid, uint256 _amount) public {


        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accPactPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safePactTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accPactPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accPactPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safePactTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accPactPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }


    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }



    //Safe pact transfer function, just in case if rounding error causes pool to not have enough PACTs.
    function safePactTransfer(address _to, uint256 _amount) internal {
        uint256 pactBal = pact.balanceOf(address(this));
        if (_amount > pactBal) {
            pact.transfer(_to, pactBal);
        } else {
            pact.transfer(_to, _amount);
        }
    }

}
