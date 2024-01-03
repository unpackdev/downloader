// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./YFBitcoin.sol";
import "./UniswapV2Pair.sol";
import "./IUniSwapV2Factory.sol";

// MasterChef is the master of YFBTC. He can make YFBTC and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once YFBTC is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.

// live net token0 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
// livenet factory 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f


// kovan token0 0xd0a1e359811322d97991e03f863a0c30c2cf029c
// kovan token1 0x551733cf73465a007BD441d0A1BBE1b30355B28A
// kovan factory 0x5c69bee701ef814a2b6a3edd4b1652cb9cc5aa6f 

contract MasterChef is Ownable {
    using SafeMath for *;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     
        uint256 rewardDebt;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 lastRewardBlock;  // Last block number that YFBTC distribution occurs.
        uint256 accYfbtcPerShare; // Accumulated YFBTC per share, times 1e12. See below.
        uint256 totalSupply;
    }

    uint256 public lastPrice = 0;

    uint public constant PERIOD = 24 hours;
    
    // holds the WETH address
    address public  token0;

    // holds the YFBTC address
    address public  token1;

    // hold factory address that will be used to fetch pair address
    address public  factory;

    // block time of last update
    uint32 public blockTimestampLast;

    // The YFBTC TOKEN!
    YFBitcoin public yfbtc;
    // Dev address.
    // Block number when bonus YFBTC period ends.
    uint256 public bonusEndBlock;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when YFBTC mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        YFBitcoin _yfbtc,
        address _factory,
        address _token0,
        address _token1,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        yfbtc = _yfbtc;
        factory = _factory;
        token0 = _token0;
        token1 = _token1;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
        address pairAddress = IUniswapV2Factory(factory).getPair(token0, token1);
        (uint112 reserve0, uint112 reserve1, uint32 blockTime) = UniswapV2Pair(pairAddress).getReserves(); // gas savings
        blockTimestampLast = blockTime;
        lastPrice = reserve1.mul(1e18).div(reserve0);
        require(reserve0 != 0 && reserve1 != 0, 'ORACLE: NO_RESERVES'); // ensure that there's liquidity in the pair
    }

    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    function setDevAddress(address _devAddress) public onlyOwner {
        yfbtc.setDevAddress(_devAddress);
    }

    function setTransferFee(uint256 _fee) public onlyOwner {
        require(_fee > 0 && _fee < 1000, "YFBTC: fee should be between 0 and 10");
        yfbtc.setTransferFee(_fee);
    }
    
    function mint(address _to, uint256 _amount) public onlyOwner {
        yfbtc.mint(_to, _amount);
    }

    function update() public returns(bool) {
        
        uint32 blockTimestamp = currentBlockTimestamp();
        address pairAddress = IUniswapV2Factory(factory).getPair(token0, token1);

        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        // ensure that at least one full period has passed since the last update
        if(timeElapsed >= PERIOD){
        (uint112 _reserve0, uint112 _reserve1, ) = UniswapV2Pair(pairAddress).getReserves(); // gas savings
        
        uint256 curretPrice = _reserve1.mul(1e18).div(_reserve0);

        if ( curretPrice < lastPrice){
        uint256 change = lastPrice.sub(curretPrice).mul(100).div(lastPrice);
        lastPrice = curretPrice;
        blockTimestampLast = blockTimestamp;

        if ( change >= 5 )
        return false;

        }
        }
        
        return true;
    }

    function updateOwnerShip(address newOwner) public onlyOwner{
      yfbtc.transferOwnership(newOwner);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(IERC20 _lpToken) public onlyOwner {
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            lastRewardBlock: lastRewardBlock,
            accYfbtcPerShare: 0,
            totalSupply: 0
        }));
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
         uint256 difference = _to.sub(_from);
        if ( difference <=0 ){
            difference = 1;
        }
        if (_from >= startBlock && _to <= startBlock.add(1036800)){
            
            if (_to <= startBlock.add(172800)){
              uint256 rewardPerBlock = 26871140040000000;
              return rewardPerBlock.mul(difference);
            }
            else{
              uint256 rewardPerBlock = 8641973370000000;
              return rewardPerBlock.mul(difference);
            }
        }else if(_from >= startBlock && _to <= startBlock.add(2073600)){
           uint256 rewardPerBlock = 4320987650000000;
           return rewardPerBlock.mul(difference);
        }
        else if(_from >= startBlock && _to <= startBlock.add(3110400)){
           uint256 rewardPerBlock = 2160493820000000;
           return rewardPerBlock.mul(difference);
        }
        else if(_from >= startBlock && _to <= startBlock.add(4147200)){
          uint256 rewardPerBlock = 1080246910000000;
          return rewardPerBlock.mul(difference);
        }
        else if(_from >= startBlock && _to <= startBlock.add(5184000)){
                uint256 rewardPerBlock = 540123450000000;
                return rewardPerBlock.mul(difference);
        }
        else if(_from >= startBlock && _to <= startBlock.add(6220800)){
          uint256 rewardPerBlock = 270061720000000;
          return rewardPerBlock.mul(difference);
        }
        else if(_from >= startBlock && _to <= startBlock.add(7257600)){
          uint256 rewardPerBlock = 135030860000000;
          return rewardPerBlock.mul(difference);
        }
        else if(_from >= startBlock && _to <= startBlock.add(8294400)){
          uint256 rewardPerBlock = 67515430000000;
          return rewardPerBlock.mul(difference);
        }
        return 0;
    }

    // View function to see pending YFBTC on frontend.
    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accYfbtcPerShare = pool.accYfbtcPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 yfbtcReward = getMultiplier(pool.lastRewardBlock, block.number);
            uint totalPoolsEligible = getEligiblePools();
            uint256 rewardPerPool = yfbtcReward.div(totalPoolsEligible);
            accYfbtcPerShare = accYfbtcPerShare.add(rewardPerPool.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accYfbtcPerShare).div(1e12).sub(user.rewardDebt);
    }

    // View function to see rewardPer YFBTC block  on frontend.
    function rewardPerBlock(uint256 _pid) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 accYfbtcPerShare = pool.accYfbtcPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 yfbtcReward = getMultiplier(pool.lastRewardBlock, block.number);
            uint totalPoolsEligible = getEligiblePools();
            uint256 rewardPerPool = yfbtcReward.div(totalPoolsEligible);
            accYfbtcPerShare = accYfbtcPerShare.add(rewardPerPool.mul(1e12).div(lpSupply));
        }
        return accYfbtcPerShare;
    }


    function getEligiblePools() internal view returns(uint){
        uint totalPoolsEligible = 0;
        uint256 length = poolInfo.length;

        // Reward will only be assign to pools when they the staked balance is > 0  
        for (uint256 pid = 0; pid < length; ++pid) {
            if( poolInfo[pid].totalSupply > 0){
              totalPoolsEligible = totalPoolsEligible.add(1);
            }
        }
        return totalPoolsEligible;
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
        bool doMint = update();

         if ( doMint ){
        uint256 yfbtcReward = getMultiplier(pool.lastRewardBlock, block.number);
        if ( yfbtcReward <= 0 ){
          return;
        }
        yfbtc.mint(address(this), yfbtcReward);
        uint totalPoolsEligible = getEligiblePools();
        uint256 rewardPerPool = yfbtcReward.div(totalPoolsEligible);
        pool.accYfbtcPerShare = pool.accYfbtcPerShare.add(rewardPerPool.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
        }
    }

    // Deposit LP tokens to MasterChef for YFBTC allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accYfbtcPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeYfbtcTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            pool.totalSupply = pool.totalSupply.add(_amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accYfbtcPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accYfbtcPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeYfbtcTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.totalSupply = pool.totalSupply.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accYfbtcPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }
  
   // let user exist in case of emergency
   function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        pool.totalSupply = pool.totalSupply.sub(amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe yfbtcReward transfer function, just in case if rounding error causes pool to not have enough YFBTC.
    function safeYfbtcTransfer(address _to, uint256 _amount) internal {
        uint256 yfbtcBal = yfbtc.balanceOf(address(this));
        if (_amount > yfbtcBal) {
            yfbtc.transfer(_to, yfbtcBal);
        } else {
            yfbtc.transfer(_to, _amount);
        }
    }
}