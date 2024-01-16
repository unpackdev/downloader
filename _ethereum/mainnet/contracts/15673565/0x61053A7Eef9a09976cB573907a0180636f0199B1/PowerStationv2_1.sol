// SPDX-License-Identifier: MIT

import "./IPowerStationV2_1.sol";
pragma solidity ^0.8.4;


import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20.sol";

contract DuoPowerStation is Initializable, UUPSUpgradeable, OwnableUpgradeable,IDUOPowerStation{
    using SafeMathUpgradeable for uint256;

    IERC20 public usdt;
    IERC20 public rgp;
    IERC20 public renFil;

    // Dev address.
    address public filAddr;
    address public usdAddr;

    // Staking user for a pool
    struct Staker {
        uint256 redeemedRewards; // The reward tokens quantity the user already redeemed
        uint256 shares; 
        bool exists;
    }

    // Staking pool
    struct Pool {
        string poolInfo;      //name and description of the pool
        uint256 totalRewards; // Total amout of tokens
        bool isOpen;        //the opening status of the pool
        uint256 remainBalance;   //the remaining balance after distributing rewards
        uint256 allocatedShares;  //The shares that have already been sold
        address[] stakerAddr;      //All user address in the pool
        uint256 [] dailyRewardPershare; //
        uint256 totalDailyRewardPershare;
        bool exists;
        address poolMiner;
        
        // buyEndTime, startTime, endingTime
        uint256 [3] timing;
        //DataFee, GasFee, IDCfee, RGPtoShare, pricePerShare, pledgePerShare, maxShares
        uint256[7]  poolInfoVars;
    }

    // Info of each pool.
  Pool[] public pools; // Staking pools
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => Staker)) public poolStaker;

    function initialize(
            address _usdt,
            address _renFil,
            address _rgp,
            address _filAddr,
            address _usdAddr
        ) public initializer {
            usdt = IERC20(_usdt);
            renFil = IERC20(_renFil);
            rgp = IERC20(_rgp);
            filAddr = _filAddr;
            usdAddr =_usdAddr;

            ///@dev as there is no constructor, we need to inititalze the OwnableUpgradeable explicitly
            __Ownable_init();
        }
    
    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @dev Add staker address to the pool stakers if it's not there already
     * This is for init the pool members. No individual can be add.
     */
    function stakerJoinPool(uint256 _pid, uint256 shares, string memory payby) public override {

        _poolExist(_pid);
        
        Pool storage poolUSDT = pools[_pid*2];
        Pool storage poolRGP = pools[_pid*2 + 1];

        ///TODO: removed for testing, should add back when depoloy
        _poolIsOpen(_pid);

        //0 DataFee,1 GasFee,2 IDCfee,3 rgptoShare,4 pricePerShare,5 pledgePerShare,6 maxShares

        // a single deal may exceed the total shares of a pool
        require(poolUSDT.allocatedShares+ poolRGP.allocatedShares + shares <= poolUSDT.poolInfoVars[6], "over sell");

        ///@dev pay for the pledge
   
        require(renFil.transferFrom(msg.sender,filAddr, poolUSDT.poolInfoVars[5] * shares),"transfer failed");
        emit PayPledge(msg.sender, poolUSDT.poolInfoVars[5] * shares);

        ///@dev pay for expenses

        //Data+Gas
 
        require(renFil.transferFrom(msg.sender, filAddr, 
                    ( ( poolUSDT.poolInfoVars[0]+poolUSDT.poolInfoVars[1]) * shares)),"transfer failed");          // 15/10 is ultility/T/month

        emit PayDataGas(msg.sender, (poolUSDT.poolInfoVars[0]+poolUSDT.poolInfoVars[1]) * shares);


        ///@dev pay for the contract by usdt or RGP
        if (keccak256(abi.encodePacked(payby)) == keccak256(abi.encodePacked("USDT"))){
           
            require(usdt.transferFrom(msg.sender,usdAddr, (poolUSDT.poolInfoVars[4] + (poolUSDT.timing[2]-poolUSDT.timing[1])/30 days * 
                                                           poolUSDT.poolInfoVars[2]) * shares),"transfer failed");
            emit PayPower(msg.sender, poolUSDT.poolInfoVars[4] * shares);
            emit PayIDC(msg.sender, (poolUSDT.timing[2]-poolUSDT.timing[1])/30 days * poolUSDT.poolInfoVars[2] * shares);
            poolUSDT.allocatedShares += shares;
            
            if (stakerExistsInPool(_pid, msg.sender)== false){
                poolUSDT.stakerAddr.push(msg.sender);
            }
            Staker storage stakerUSDT = poolStaker[_pid*2][msg.sender];
            
            stakerUSDT.exists = true;
            stakerUSDT.shares += shares;
            }

        else if (keccak256(abi.encodePacked(payby)) == keccak256(abi.encodePacked("RGP"))){

            //RGP
            require(rgp.transferFrom(msg.sender,usdAddr, poolRGP.poolInfoVars[3] * shares),"transfer failed");
            emit PayPower(msg.sender, poolRGP.poolInfoVars[3] * shares);

            //IDC
            require(usdt.transferFrom(msg.sender, usdAddr, (poolUSDT.timing[2]-poolUSDT.timing[1])/30 days * 
                                                            poolRGP.poolInfoVars[2]*shares),"transfer failed");
            emit PayIDC(msg.sender, (poolUSDT.timing[2]-poolUSDT.timing[1])/30 days * poolRGP.poolInfoVars[2] * shares);
            poolRGP.allocatedShares += shares;
            if (stakerExistsInPool(_pid, msg.sender)== false){
                poolUSDT.stakerAddr.push(msg.sender);
            }
            Staker storage stakerUSDT = poolStaker[_pid*2][msg.sender];
            Staker storage stakerRGP = poolStaker[_pid*2 + 1][msg.sender];
            stakerUSDT.exists = true;
            stakerRGP.shares += shares;     
        }

        else {
            revert("not legit");
        }

        //if reach max shares, close the pool
        if(poolUSDT.allocatedShares +poolRGP.allocatedShares == poolRGP.poolInfoVars[6]){
            
            poolRGP.isOpen = false;
            poolUSDT.isOpen = false;
            emit PoolIsFull(_pid);
        }
    }
    
    function _poolIsOpen(uint256 _pid) internal{
        Pool storage poolUSDT = pools[_pid*2];
        Pool storage poolRGP = pools[_pid*2 + 1];
        if (block.timestamp > poolUSDT.timing[0]){      // buy end time
            poolUSDT.isOpen = false;
            poolRGP.isOpen = false;
        }
        require(poolUSDT.isOpen, "pool closed");
    }
    function _poolExist(uint256 _pid)internal view virtual{
        require(poolExists(_pid),"pool is not exist");
        
    }
    
    function _stakerExist(uint256 _pid, address stakerAddr)internal view virtual{
        require(stakerExistsInPool(_pid, stakerAddr),"not in the pool");
    
    }

    function withdraw(uint256 _pid) public override{
        _stakerExist(_pid, msg.sender);
        Staker storage stakerUSDT = poolStaker[_pid*2][msg.sender];
        Staker storage stakerRGP =  poolStaker[_pid*2 + 1][msg.sender];
        _poolExist(_pid);
        Pool storage poolUSDT = pools[_pid*2];
        Pool storage poolRGP = pools[_pid*2 + 1];

        uint256 remainingRewardsPerShareUSDT;
        uint256 remainingRewardsPerShareRGP;

        if(stakerUSDT.shares ==0){
            remainingRewardsPerShareUSDT = 0;
                }
        else{
            remainingRewardsPerShareUSDT = poolUSDT.totalDailyRewardPershare -stakerUSDT.redeemedRewards / stakerUSDT.shares;
                }
        if(stakerRGP.shares ==0){
            remainingRewardsPerShareRGP = 0;
                }
        else{
            remainingRewardsPerShareRGP = poolRGP.totalDailyRewardPershare -stakerRGP.redeemedRewards / stakerRGP.shares;
                }

        require(remainingRewardsPerShareRGP + remainingRewardsPerShareUSDT > 0, "insufficient rewards");
        require(renFil.transfer(msg.sender, remainingRewardsPerShareUSDT* stakerUSDT.shares + 
                                        remainingRewardsPerShareRGP* stakerRGP.shares),"transfer failed");
        stakerUSDT.redeemedRewards += remainingRewardsPerShareUSDT* stakerUSDT.shares;
        stakerRGP.redeemedRewards += remainingRewardsPerShareRGP* stakerRGP.shares;
    }


    function poolLength() public override view returns (uint256) {

        return pools.length;
    }

    function numberOfstakers(uint256 _pid) public override view returns (uint256) {
        _poolExist(_pid);
        Pool storage pool = pools[_pid];
        return pool.stakerAddr.length;
    }
    /**
     * @dev Create a new staking pool
     */

    function addPool(uint256 periods,  uint256 pricePerShare, uint256 pledgePerShare, address poolMiner, 
                    string memory poolInfo,uint256 maxShares, uint256 startTime, 
                    uint256 dataFee, uint256 gasFee, uint256 rgptoShare, uint256 idcFee, uint256 buyEndTime)
        public override onlyOwner{
        Pool memory pool;
        uint256[7] memory poolInfoVars;
        poolInfoVars = [dataFee,gasFee, idcFee, rgptoShare, pricePerShare, pledgePerShare, maxShares];
        pool.poolInfoVars = poolInfoVars;

        pool.poolMiner = poolMiner;
        pool.poolInfo = poolInfo;
        ///TODO this is for testing convience
        // startTime =block.timestamp;

        uint256 endingTime = startTime + periods*30 days;

        uint256[3] memory timing = [buyEndTime,startTime, endingTime];
        pool.timing =timing;
        pool.exists = true;
        pool.isOpen = true;
      
        pools.push(pool);
        pools.push(pool);
        uint256 poolId = pools.length/2 - 1;
        emit PoolCreated(poolId);
    }
            
    ///@dev admin top up the daily rewards into the pool

    function topUpPool(uint256 _pid, uint256 _allocPoint) public override{
        
        _poolExist(_pid);
        Pool storage poolUSDT = pools[_pid*2];
        Pool storage poolRGP = pools[_pid*2 + 1];
        require(msg.sender == poolUSDT.poolMiner,"not allowed");

        uint256 rewardPerShareRGP = _allocPoint*  1/poolRGP.poolInfoVars[6] * 85/100;    // allocPoint* 1/maxShares *0.85
        uint256 rewardPerShareUSDT = _allocPoint*  1/poolRGP.poolInfoVars[6] * 80/100;    // allocPoint* 1/maxShares *0.8
        uint256 allocatedRewardsRGP = rewardPerShareRGP * poolRGP.allocatedShares;
        uint256 allocatedRewardsUSDT = rewardPerShareUSDT * poolUSDT.allocatedShares;

        require(renFil.transferFrom(msg.sender, filAddr, _allocPoint - allocatedRewardsRGP - allocatedRewardsUSDT),"dev not received");
        require(renFil.transferFrom(msg.sender, address(this), allocatedRewardsRGP + allocatedRewardsUSDT),"pool not received");
        emit TopUp(_pid, _allocPoint);

        ///update the total rewards that has been sent in this pool
        poolUSDT.totalRewards += _allocPoint;
        poolUSDT.dailyRewardPershare.push(rewardPerShareUSDT);
        poolRGP.dailyRewardPershare.push(rewardPerShareRGP);
        poolUSDT.totalDailyRewardPershare += rewardPerShareUSDT;
        poolRGP.totalDailyRewardPershare += rewardPerShareRGP;
        poolUSDT.remainBalance +=  _allocPoint - allocatedRewardsRGP - allocatedRewardsUSDT;
   
        emit TopUp(_pid, _allocPoint);
    }
    
    function poolAvailable(uint256 _pid) public override view returns(bool){
        _poolExist(_pid);
    
        Pool storage pool = pools[_pid*2];
        return(pool.timing[1] < block.timestamp && block.timestamp < pool.timing[2]);
    }

    function poolRemainingTime(uint256 _pid) public override view returns(uint256){
        _poolExist(_pid);

        Pool storage pool = pools[_pid*2];
        return(pool.timing[2] - block.timestamp);
    }

    function pendingRewards(address stakerAddr, uint256 _pid) public override view returns (uint256){
        _stakerExist(_pid, stakerAddr);
        Staker storage stakerUSDT = poolStaker[_pid*2][stakerAddr];
        Staker storage stakerRGP =  poolStaker[_pid*2 + 1][stakerAddr];
        _poolExist(_pid);
        Pool storage poolUSDT = pools[_pid*2];
        Pool storage poolRGP = pools[_pid*2 + 1];
        uint256 remainingRewardsPerShareUSDT;
        uint256 remainingRewardsPerShareRGP;

        if(stakerUSDT.shares == 0){
            remainingRewardsPerShareUSDT = 0;
                }
        else{
            remainingRewardsPerShareUSDT = poolUSDT.totalDailyRewardPershare -stakerUSDT.redeemedRewards / stakerUSDT.shares;
                }
        if(stakerRGP.shares == 0){
            remainingRewardsPerShareRGP = 0;
                }
        else{
            remainingRewardsPerShareRGP = poolRGP.totalDailyRewardPershare -stakerRGP.redeemedRewards / stakerRGP.shares;
                }
        return(remainingRewardsPerShareUSDT * stakerUSDT.shares + remainingRewardsPerShareRGP * stakerRGP.shares);
        }
    
    function pendingRewardsWithInfo(address stakerAddr, uint256 _pid) 
        public view returns (uint256, uint256, uint256 [7] memory,uint256[7] memory){
        _stakerExist(_pid, stakerAddr);
        Staker storage stakerUSDT = poolStaker[_pid*2][stakerAddr];
        Staker storage stakerRGP =  poolStaker[_pid*2 + 1][stakerAddr];
        _poolExist(_pid);
        Pool storage poolUSDT = pools[_pid*2];
        Pool storage poolRGP = pools[_pid*2 + 1];

        uint256[7] memory poolVars = getPoolVars(_pid);
        // (string memory poolName, address miner, bool isOpen, uint256 [7] memory poolInfo)= getPoolInfo(_pid);
        uint256 [7] memory poolInfo= getPoolInfo(_pid);

        uint256 remainingRewardsPerShareUSDT;
        uint256 remainingRewardsPerShareRGP;

        if(stakerUSDT.shares ==0){
            remainingRewardsPerShareUSDT = 0;
                }
        else{
            remainingRewardsPerShareUSDT = poolUSDT.totalDailyRewardPershare -stakerUSDT.redeemedRewards / stakerUSDT.shares;
                }
        if(stakerRGP.shares ==0){
            remainingRewardsPerShareRGP = 0;
                }
        else{
            remainingRewardsPerShareRGP = poolRGP.totalDailyRewardPershare -stakerRGP.redeemedRewards / stakerRGP.shares;
                }
       
        // return(remainingRewardsPerShareUSDT * stakerUSDT.shares + remainingRewardsPerShareRGP * stakerRGP.shares, 
        //     stakerUSDT.shares + stakerRGP.shares, poolName, miner, isOpen, poolInfo, poolVars);
        return(remainingRewardsPerShareUSDT * stakerUSDT.shares + remainingRewardsPerShareRGP * stakerRGP.shares, 
            stakerUSDT.shares + stakerRGP.shares, poolInfo, poolVars);
    }

    function minerWithdraw(uint256 _pid)public override{
        _poolExist(_pid);
        Pool storage pool = pools[_pid*2];
        require(msg.sender == pool.poolMiner,"not allowed");

        renFil.transfer(msg.sender, pool.remainBalance);
        pool.remainBalance = 0;
    }

    function emergencyWithdraw()public override onlyOwner{
        renFil.transfer(filAddr, renFil.balanceOf(address(this)));
        
        for(uint256 i =0; i < pools.length; i + 2){
            Pool storage pool = pools[i];
            pool.remainBalance = 0;
        } 
    }

    // check the total computation powers that have been sold 
    function checkSoldShares(uint256 _pid)public override view returns(uint256){
        _poolExist(_pid);
        Pool storage poolUSDT = pools[_pid*2];
        Pool storage poolRGP = pools[_pid*2 + 1];
        return(poolUSDT.allocatedShares+poolRGP.allocatedShares);
    }

    function poolExists(uint256 _pid) public view override returns(bool){
        Pool storage pool = pools[_pid*2];
        return(pool.exists);
    }

    function stakerExistsInPool(uint256 _pid, address stakerAddr) public override view returns(bool){
        Staker storage staker = poolStaker[_pid*2][stakerAddr];
        return(staker.exists);
    }

    function stakerAddrInPool(uint256 _pid) public view override returns( address [] memory){
        _poolExist(_pid);
        Pool storage pool = pools[_pid*2];
        return(pool.stakerAddr);
    }

    function getPoolVars(uint256 _pid) public view override returns( uint256[7] memory){
        _poolExist(_pid);
        Pool storage pool = pools[_pid*2];
        return(pool.poolInfoVars);
    }

    function getPoolDailyPricePerShare(uint256 _pid) public override view returns(uint256[] memory){
        _poolExist(_pid);

        Pool storage pool = pools[_pid*2];
        return(pool.dailyRewardPershare);
    }
    
    function getStakerInfoNTime(uint256 _pid, address stakerAddr) public override view returns(uint256[6] memory){
        _stakerExist(_pid,stakerAddr);
        Staker storage stakerUSDT = poolStaker[_pid*2][stakerAddr];
        Staker storage stakerRGP =  poolStaker[_pid*2 + 1][stakerAddr];
        uint256[7] memory poolVars = getPoolVars(_pid);
        uint256[3] memory poolTime = getTiming(_pid);
        uint256 rgpTosShare = poolVars[3];
        uint256 pricePerShare = poolVars[4];
        uint256 startTime  = poolTime[1];
        uint256 endTime = poolTime[2];
        uint256[6] memory data = [stakerUSDT.shares, stakerRGP.shares, pricePerShare,
                                rgpTosShare, startTime, endTime];
        return(data);
    }

    function getTiming(uint256 _pid) public override view returns(uint256[3] memory){
        _poolExist(_pid);

        Pool storage pool = pools[_pid*2];
        return(pool.timing);
    }
     function getPoolInfo(uint256 _pid) private view returns(uint256 [7] memory){
        _poolExist(_pid);
        Pool storage pool = pools[_pid*2];
        // return(pool.poolInfo, pool.poolMiner, pool.isOpen, [pool.totalRewards, pool.timing[0],
        // pool.timing[1], pool.timing[2], pool.remainBalance, pool.allocatedShares, pool.totalDailyRewardPershare]);
        
        return([pool.totalRewards, pool.timing[0],
        pool.timing[1], pool.timing[2], pool.remainBalance, pool.allocatedShares, pool.totalDailyRewardPershare]);
    }
}