// SPDX-License-Identifier: MIT


pragma solidity 0.7.6;


import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./DVGToken.sol";


contract DAOstake is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;


    /* 
    Basically, any point in time, the amount of DVGs entitled to a user but is pending to be distributed is:
    
    pending DVG = (user.lpAmount * pool.accDVGPerLP) - user.finishedDVG
    
    Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    1. The pool's `accDVGPerLP` (and `lastRewardBlock`) gets updated.
    2. User receives the pending DVG sent to his/her address.
    3. User's `lpAmount` gets updated.
    4. User's `finishedDVG` gets updated.
    */
    struct Pool {
        // Address of LP token
        address lpTokenAddress;
        // Weight of pool           
        uint256 poolWeight;
        // Last block number that DVGs distribution occurs for pool
        uint256 lastRewardBlock; 
        // Accumulated DVGs per LP of pool
        uint256 accDVGPerLP; 
    }

    struct User {
        // LP token amount that user provided
        uint256 lpAmount;     
        // Finished distributed DVGs to user
        uint256 finishedDVG;
    }
    

    /* 
    END_BLOCK = START_BLOCK + BLOCK_PER_PERIOD * PERIOD_AMOUNT 
    */
    // First block that DAOstake will start from
    uint256 public constant START_BLOCK = 12770000;
    // First block that DAOstake will end from
    uint256 public constant END_BLOCK = 22234000;
    // Amount of block per period: 6500(blocks per day) * 14(14 days/2 weeks) = 91000
    uint256 public constant BLOCK_PER_PERIOD = 91000;
    // Amount of period
    uint256 public constant PERIOD_AMOUNT = 104;

    // Treasury wallet address
    address public treasuryWalletAddr;
    // Community wallet address
    address public communityWalletAddr;

    // DVG token 
    DVGToken public dvg;

    // Percent of DVG is distributed to treasury wallet per block: 24.5%
    uint256 public constant TREASURY_WALLET_PERCENT = 2450;
    // Percent of DVG is distributed to community wallet per block: 24.5%
    uint256 public constant COMMUNITY_WALLET_PERCENT = 2450;
    // Percent of DVG is distributed to pools per block: 51%
    uint256 public constant POOL_PERCENT = 5100;

    // Total pool weight / Sum of all pool weights
    uint256 public totalPoolWeight;
    Pool[] public pool;
    // pool id => user address => user info
    mapping (uint256 => mapping (address => User)) public user;

    // period id => DVG amount per block of period
    mapping (uint256 => uint256) public periodDVGPerBlock;


    event SetWalletAddress(address indexed treasuryWalletAddr, address indexed communityWalletAddr);

    event SetDVG(DVGToken indexed dvg);

    event TransferDVGOwnership(address indexed newOwner);

    event AddPool(address indexed lpTokenAddress, uint256 indexed poolWeight, uint256 indexed lastRewardBlock);

    event SetPoolWeight(uint256 indexed poolId, uint256 indexed poolWeight, uint256 totalPoolWeight);

    event UpdatePool(uint256 indexed poolId, uint256 indexed lastRewardBlock, uint256 totalDVG);

    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);

    event Withdraw(address indexed user, uint256 indexed poolId, uint256 amount);

    event EmergencyWithdraw(address indexed user, uint256 indexed poolId, uint256 amount);


    /**
     * @notice Update DVG amount per block for each period when deploying. Be careful of gas spending!
     */
    constructor(
        address _treasuryWalletAddr,
        address _communityWalletAddr,
        DVGToken _dvg
    ) {
        periodDVGPerBlock[1] = 30 ether;

        for (uint256 i = 2; i <= PERIOD_AMOUNT; i++) {
            periodDVGPerBlock[i] = periodDVGPerBlock[i.sub(1)].mul(9650).div(10000);
        }

        setWalletAddress(_treasuryWalletAddr, _communityWalletAddr);

        setDVG(_dvg);
    }


    /** 
     * @notice Set all params about wallet address. Can only be called by owner
     * Remember to mint and distribute pending DVGs to wallet before changing address
     *
     * @param _treasuryWalletAddr     Treasury wallet address
     * @param _communityWalletAddr    Community wallet address
     */
    function setWalletAddress(address _treasuryWalletAddr, address _communityWalletAddr) public onlyOwner {
        require((_treasuryWalletAddr != address(0)) && (_communityWalletAddr != address(0)), "Any wallet address should not be zero address");
        
        treasuryWalletAddr = _treasuryWalletAddr;
        communityWalletAddr = _communityWalletAddr;
    
        emit SetWalletAddress(treasuryWalletAddr, communityWalletAddr);
    }

    /**
     * @notice Set DVG token address. Can only be called by owner
     */
    function setDVG(DVGToken _dvg) public onlyOwner {
        dvg = _dvg;
    
        emit SetDVG(dvg);
    }

    /**
     * @notice Transfer ownership of DVG token. Can only be called by this smart contract owner
     *
     */
    function transferDVGOwnership(address _newOwner) public onlyOwner {
        dvg.transferOwnership(_newOwner);
        emit TransferDVGOwnership(_newOwner);
    }

    /** 
     * @notice Get the length/amount of pool
     */
    function poolLength() external view returns(uint256) {
        return pool.length;
    } 

    /** 
     * @notice Return reward multiplier over given _from to _to block. [_from, _to)
     * 
     * @param _from    From block number (included)
     * @param _to      To block number (exluded)
     */
    function getMultiplier(uint256 _from, uint256 _to) public view returns(uint256 multiplier) {
        if (_from < START_BLOCK) {_from = START_BLOCK;}
        if (_to > END_BLOCK) {_to = END_BLOCK;}

        uint256 periodOfFrom = _from.sub(START_BLOCK).div(BLOCK_PER_PERIOD).add(1);
        uint256 periodOfTo = _to.sub(START_BLOCK).div(BLOCK_PER_PERIOD).add(1);
        
        if (periodOfFrom == periodOfTo) {
            multiplier = _to.sub(_from).mul(periodDVGPerBlock[periodOfTo]);
        } else {
            uint256 multiplierOfFrom = BLOCK_PER_PERIOD.mul(periodOfFrom).add(START_BLOCK).sub(_from).mul(periodDVGPerBlock[periodOfFrom]);
            uint256 multiplierOfTo = _to.sub(START_BLOCK).mod(BLOCK_PER_PERIOD).mul(periodDVGPerBlock[periodOfTo]);
            multiplier = multiplierOfFrom.add(multiplierOfTo);
            for (uint256 periodId = periodOfFrom.add(1); periodId < periodOfTo; periodId++) {
                multiplier = multiplier.add(BLOCK_PER_PERIOD.mul(periodDVGPerBlock[periodId]));
            }
        }
    }

    /** 
     * @notice Get pending DVG amount of user in pool
     */
    function pendingDVG(uint256 _pid, address _user) external view returns(uint256) {
        Pool storage pool_ = pool[_pid];
        User storage user_ = user[_pid][_user];
        uint256 accDVGPerLP = pool_.accDVGPerLP;
        uint256 lpSupply = IERC20(pool_.lpTokenAddress).balanceOf(address(this));

        if (block.number > pool_.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool_.lastRewardBlock, block.number);
            uint256 dvgForPool = multiplier.mul(POOL_PERCENT).mul(pool_.poolWeight).div(totalPoolWeight).div(10000);
            accDVGPerLP = accDVGPerLP.add(dvgForPool.mul(1 ether).div(lpSupply));
        }

        return user_.lpAmount.mul(accDVGPerLP).div(1 ether).sub(user_.finishedDVG);
    }

    /** 
     * @notice Add a new LP to pool. Can only be called by owner
     * DO NOT add the same LP token more than once. DVG rewards will be messed up if you do
     */
    function addPool(address _lpTokenAddress, uint256 _poolWeight, bool _withUpdate) public onlyOwner {
        require(block.number < END_BLOCK, "Already ended");
        require(_lpTokenAddress.isContract(), "LP token address should be smart contract address");

        if (_withUpdate) {
            massUpdatePools();
        }
        
        uint256 lastRewardBlock = block.number > START_BLOCK ? block.number : START_BLOCK;
        totalPoolWeight = totalPoolWeight + _poolWeight;

        pool.push(Pool({
            lpTokenAddress: _lpTokenAddress,
            poolWeight: _poolWeight,
            lastRewardBlock: lastRewardBlock,
            accDVGPerLP: 0
        }));

        emit AddPool(_lpTokenAddress, _poolWeight, lastRewardBlock);
    }

    /** 
     * @notice Update the given pool's weight. Can only be called by owner.
     */
    function setPoolWeight(uint256 _pid, uint256 _poolWeight, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }

        totalPoolWeight = totalPoolWeight.sub(pool[_pid].poolWeight).add(_poolWeight);
        pool[_pid].poolWeight = _poolWeight;

        emit SetPoolWeight(_pid, _poolWeight, totalPoolWeight);
    }

    /** 
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function updatePool(uint256 _pid) public {
        Pool storage pool_ = pool[_pid];

        if (block.number <= pool_.lastRewardBlock) {
            return;
        }

        uint256 totalDVG = getMultiplier(pool_.lastRewardBlock, block.number).mul(pool_.poolWeight).div(totalPoolWeight);

        uint256 lpSupply = IERC20(pool_.lpTokenAddress).balanceOf(address(this));
        if (lpSupply > 0) {
            uint256 dvgForPool = totalDVG.mul(POOL_PERCENT).div(10000);

            dvg.mint(treasuryWalletAddr, totalDVG.mul(TREASURY_WALLET_PERCENT).div(10000)); 
            dvg.mint(communityWalletAddr, totalDVG.mul(COMMUNITY_WALLET_PERCENT).div(10000));
            dvg.mint(address(this), dvgForPool);

            pool_.accDVGPerLP = pool_.accDVGPerLP.add(dvgForPool.mul(1 ether).div(lpSupply));
        } else {
            dvg.mint(treasuryWalletAddr, totalDVG.mul(TREASURY_WALLET_PERCENT).div(10000)); 
            dvg.mint(communityWalletAddr, totalDVG.mul(COMMUNITY_WALLET_PERCENT.add(POOL_PERCENT)).div(10000));
        }

        pool_.lastRewardBlock = block.number;

        emit UpdatePool(_pid, pool_.lastRewardBlock, totalDVG);
    }

    /** 
     * @notice Update reward variables for all pools. Be careful of gas spending!
     * Due to gas limit, please make sure here no significant amount of pools!
     */
    function massUpdatePools() public {
        uint256 length = pool.length;
        for (uint256 pid = 0; pid < length; pid++) {
            updatePool(pid);
        }
    }

    /** 
     * @notice Deposit LP tokens for DVG rewards
     * Before depositing, user needs approve this contract to be able to spend or transfer their LP tokens
     *
     * @param _pid       Id of the pool to be deposited to
     * @param _amount    Amount of LP tokens to be deposited
     */
    function deposit(uint256 _pid, uint256 _amount) public {
        Pool storage pool_ = pool[_pid];
        User storage user_ = user[_pid][msg.sender];

        updatePool(_pid);

        if (user_.lpAmount > 0) {
            uint256 pendingDVG_ = user_.lpAmount.mul(pool_.accDVGPerLP).div(1 ether).sub(user_.finishedDVG);
            if(pendingDVG_ > 0) {
                _safeDVGTransfer(msg.sender, pendingDVG_);
            }
        }

        if(_amount > 0) {
            IERC20(pool_.lpTokenAddress).safeTransferFrom(address(msg.sender), address(this), _amount);
            user_.lpAmount = user_.lpAmount.add(_amount);
        }

        user_.finishedDVG = user_.lpAmount.mul(pool_.accDVGPerLP).div(1 ether);

        emit Deposit(msg.sender, _pid, _amount);
    }

    /** 
     * @notice Withdraw LP tokens
     *
     * @param _pid       Id of the pool to be withdrawn from
     * @param _amount    amount of LP tokens to be withdrawn
     */
    function withdraw(uint256 _pid, uint256 _amount) public {
        Pool storage pool_ = pool[_pid];
        User storage user_ = user[_pid][msg.sender];

        require(user_.lpAmount >= _amount, "Not enough LP token balance");

        updatePool(_pid);

        uint256 pendingDVG_ = user_.lpAmount.mul(pool_.accDVGPerLP).div(1 ether).sub(user_.finishedDVG);

        if(pendingDVG_ > 0) {
            _safeDVGTransfer(msg.sender, pendingDVG_);
        }

        if(_amount > 0) {
            user_.lpAmount = user_.lpAmount.sub(_amount);
            IERC20(pool_.lpTokenAddress).safeTransfer(address(msg.sender), _amount);
        }

        user_.finishedDVG = user_.lpAmount.mul(pool_.accDVGPerLP).div(1 ether);

        emit Withdraw(msg.sender, _pid, _amount);
    }

    /** 
     * @notice Withdraw LP tokens without caring about DVG rewards. EMERGENCY ONLY
     *
     * @param _pid    Id of the pool to be emergency withdrawn from
     */
    function emergencyWithdraw(uint256 _pid) public {
        Pool storage pool_ = pool[_pid];
        User storage user_ = user[_pid][msg.sender];

        uint256 amount = user_.lpAmount;

        user_.lpAmount = 0;
        user_.finishedDVG = 0;

        IERC20(pool_.lpTokenAddress).safeTransfer(address(msg.sender), amount);

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }
     
    /** 
     * @notice Safe DVG transfer function, just in case if rounding error causes pool to not have enough DVGs
     *
     * @param _to        Address to get transferred DVGs
     * @param _amount    Amount of DVG to be transferred
     */
    function _safeDVGTransfer(address _to, uint256 _amount) internal {
        uint256 dvgBal = dvg.balanceOf(address(this));
        
        if (_amount > dvgBal) {
            dvg.transfer(_to, dvgBal);
        } else {
            dvg.transfer(_to, _amount);
        }
    }
}