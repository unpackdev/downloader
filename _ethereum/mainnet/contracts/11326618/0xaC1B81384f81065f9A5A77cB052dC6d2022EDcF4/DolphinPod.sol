// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// Adapted from SushiSwap's MasterChef contract
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Ownable.sol";
import "./eeee.sol";

// DolphinPod is the games master of her majesty the Cetacean Queen's games. He shares the bounty with the dolphins and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be burned once the EEEE has been sufficiently
// distributed and the opening ceremony of the games takes place.
//
// Have fun reading it. Hopefully it's bug-free. God save the Cetacean Queen.
//
//////////////////////////////////////////////////////////////////////
//                                       __                         //
//                                   _.-~  )  ___ dolphinPods ____  //
//                        _..--~~~~,'   ,-/     _                   //
//                     .-'. . . .'   ,-','    ,' )                  //
//                   ,'. . . _   ,--~,-'__..-'  ,'                  //
//                 ,'. . .  (@)' ---~~~~      ,'                    //
//                /. . . . '~~             ,-'                      //
//               /. . . . .             ,-'                         //
//              ; . . . .  - .        ,'                            //
//             : . . . .       _     /                              //
//            . . . . .          `-.:                               //
//           . . . ./  - .          )                               //
//          .  . . |  _____..---.._/ ____ dolphins.wtf ____         //
//~---~~~~-~~---~~~~----~~~~-~~~~-~~---~~~~----~~~~~~---~~~~-~~---~~//
//                                                                  //
//////////////////////////////////////////////////////////////////////

contract DolphinPod is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many ERC20/LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of EEEEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accEEEEPerShareTimes1e12) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   Step 1. The pool's `accEEEEPerShareTimes1e12` (and `lastRewardBlock`) gets updated.
        //   Step 2. User receives the pending reward sent to his/her address.
        //   Step 3. User's `amount` gets updated.
        //   Step 4. User's `rewardDebt` gets updated to reflect the reward already sent in Step 2.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 stakedToken;       // Address of staked ERC20 and LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. Weighting of EEEEs to distribute per block vs. other pools.
        uint256 lastRewardBlock;  // Last block number that EEEEs distribution occurs.
        uint256 accEEEEPerShareTimes1e12; // Accumulated EEEEs per share, times 1e12. See below.
    }



    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes ERC20 & LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // Farming of EEEE is enabled over a fixed number of blocks.
    // The start block is configurable until it has passed, at which point it cannot be changed.
    // When altering the start time the owner cannot start a farming sooner than 9200 blocks (~48 hours) in the future.
    IERC20  public immutable dolphinToken;
    uint256 public immutable eeeePerBlock; // Number of tokens minted per block, in phase1, accross all pools
    uint256 public immutable durationInBlocks; // E.g. ~46000 = one week
    uint256 public immutable minElapsedBlocksBeforeStart; // 
    uint256 public startBlock;
    

    // YYY_EEEE
    mapping (IERC20 => bool) public supportedToken;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Schedule(uint256 _eeeePerBlock,
        uint256 _durationInBlocks,
        uint256 _minElapsedBlocksBeforeStart,
        uint256 _startBlock);

    constructor (
        IERC20 eeee,
        uint256 _eeeePerBlock, // 5e17wei = 0.5 eeee per block
        uint256 _durationInBlocks,
        uint256 _minElapsedBlocksBeforeStart,
        uint256 _startBlock
    ) public
      validPhases {
        dolphinToken = eeee;
        require(_durationInBlocks > 0, "invalid duration");
        eeeePerBlock = _eeeePerBlock; // 5e17wei = 0.5 eeee per block
        durationInBlocks = _durationInBlocks;
        startBlock = _startBlock;
        minElapsedBlocksBeforeStart = _minElapsedBlocksBeforeStart;
        require(block.number + _minElapsedBlocksBeforeStart < startBlock, "not enough notice given");

        emit Schedule(_eeeePerBlock,
                        _durationInBlocks,
                        _minElapsedBlocksBeforeStart,
                        _startBlock);
    }

    modifier validPhases {
        _;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Change the start block for dolphin farming, as long as it hasn't started already
    function setStartBlock(uint256 _block) public onlyOwner validPhases {
        require(block.number + minElapsedBlocksBeforeStart < _block, "setStartBlock: not enough notice given");

        if (block.number < startBlock) {
            startBlock = _block;
        } else {
            require(false, "setStartBlock: farming already started");
        }

        emit Schedule(eeeePerBlock,
                durationInBlocks,
                minElapsedBlocksBeforeStart,
                startBlock);
    }


    // Add a new erc20 or lp to the pool and update total allocation points accordingly. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20 _stakedToken, bool _withUpdate) public onlyOwner {

        // Each LP token can only be added once
        require(!supportedToken[_stakedToken], "add: duplicate token");
        supportedToken[_stakedToken] = true;

        // Update rewards for other pools (best to do this if rewards are already active)
        if (_withUpdate) {
            massUpdatePools();
        }


        uint256 lastRewardBlock = block.number;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            stakedToken: _stakedToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accEEEEPerShareTimes1e12: 0
        }));
    }

    // Update the given pool's EEEE allocation point, and the total allocaiton points. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }



    // Return reward multiplier over the given _from to _to block.
    // This is just the number of blocks where rewards were active, unless a bonus was in effect for some or all of the block range.
     function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256 multiplier) {
        uint256 effectiveFrom = Math.max(_from, startBlock);
        uint256 effectiveTo = Math.min(_to, startBlock + durationInBlocks);

        if (effectiveFrom < effectiveTo) {
            multiplier = effectiveTo - effectiveFrom;
        } else {    
            multiplier = 0;
        }
    }

    // View function to see pending EEEEs on frontend.
    function pendingEEEE(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accEEEEPerShareTimes1e12 = pool.accEEEEPerShareTimes1e12;
        uint256 stakedSupply = pool.stakedToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && stakedSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 eeeeReward = multiplier.mul(eeeePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accEEEEPerShareTimes1e12 = accEEEEPerShareTimes1e12.add(eeeeReward.mul(1e12).div(stakedSupply));
        }
        return user.amount.mul(accEEEEPerShareTimes1e12).div(1e12).sub(user.rewardDebt);
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
        uint256 stakedSupply = pool.stakedToken.balanceOf(address(this));
        if (stakedSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        // multiplier = count of blocks since last reward calc (perhaps scaled up for bonuses)
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);

        // eeeeReward = (scaled block count) * (rewards per block) * (this pool's % share of all block rewards)
        uint256 eeeeReward = multiplier.mul(eeeePerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        // Update the reward that each ERC20 / LP token in this pool is due (same for each ERC20 / LP token since last reward calc)
        pool.accEEEEPerShareTimes1e12 = pool.accEEEEPerShareTimes1e12.add(eeeeReward.mul(1e12).div(stakedSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit ERC20 / LP tokens to DolphinPod for EEEE allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accEEEEPerShareTimes1e12).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeEEEETransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.stakedToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accEEEEPerShareTimes1e12).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw ERC20 / LP tokens from DolphinPod.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accEEEEPerShareTimes1e12).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeEEEETransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.stakedToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accEEEEPerShareTimes1e12).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.stakedToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe eeee transfer function, just in case rounding errors cause us not to have enough EEEEs.
    function safeEEEETransfer(address _to, uint256 _amount) internal {
        uint256 eeeeBal = dolphinToken.balanceOf(address(this));
        if (_amount > eeeeBal) {
            dolphinToken.safeTransfer(_to, eeeeBal);
        } else {
            dolphinToken.safeTransfer(_to, _amount);
        }
    }

    // Allows dev to sweep any tokens left in the contract, but only after farming has completed
     function cleanUpFarm() public onlyOwner {
        uint256 farmingEndBlock = startBlock + durationInBlocks;  
        require(block.number > farmingEndBlock, "farming hasn't finished yet");
        safeEEEETransfer(msg.sender, dolphinToken.balanceOf(address(this)));
    }
}
