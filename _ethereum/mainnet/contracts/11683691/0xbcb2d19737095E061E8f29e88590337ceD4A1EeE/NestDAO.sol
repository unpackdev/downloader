// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./ReentrancyGuard.sol";


import "./INestMining.sol";
import "./INToken.sol";
import "./INestPool.sol";
import "./INestDAO.sol";
import "./INestStaking.sol";
import "./INestQuery.sol";

// import "./console.sol";

/// @dev The contract is for redeeming nest token and getting ETH in return
contract NestDAO is INestDAO, ReentrancyGuard {

    using SafeMath for uint256;

    /* ========== STATE ============== */

    uint8 public flag; 

    /// @dev the block height where DAO was started
    uint32  public startedBlock;
    uint32  public lastCollectingBlock;
    uint184 private _reserved;

    uint8 constant DAO_FLAG_UNINITIALIZED    = 0;
    uint8 constant DAO_FLAG_INITIALIZED      = 1;
    uint8 constant DAO_FLAG_ACTIVE           = 2;
    uint8 constant DAO_FLAG_NO_STAKING       = 3;
    uint8 constant DAO_FLAG_PAUSED           = 4;
    uint8 constant DAO_FLAG_SHUTDOWN         = 127;

    struct Ledger {
        uint128 rewardedAmount;
        uint128 redeemedAmount;
        uint128 quotaAmount;
        uint32  lastBlock;
        uint96  _reserved;
    }

    /// @dev Mapping from ntoken => amount (of ntokens owned by DAO)
    mapping(address => Ledger) public ntokenLedger;

    /// @dev Mapping from ntoken => amount (of ethers owned by DAO)
    mapping(address => uint256) public ethLedger;

    /* ========== PARAMETERS ============== */

    uint256 public ntokenRepurchaseThreshold;
    uint256 public collectInterval;

    uint256 constant DAO_REPURCHASE_PRICE_DEVIATION = 5;  // price deviation < 5% 
    uint256 constant DAO_REPURCHASE_NTOKEN_TOTALSUPPLY = 5_000_000;  // total supply > 5 million 

    uint256 constant DAO_COLLECT_INTERVAL = 5_760;  // 24 hour * 60 min * 4 block/min ~= 1 day

    uint256 constant _ethFee = 0.01 ether;

    /* ========== ADDRESSES ============== */

    address public governance;

    address private C_NestPool;
    address private C_NestToken;
    address private C_NestMining;
    address private C_NestStaking;
    address private C_NestQuery;

    /* ========== CONSTRUCTOR ========== */

    receive() external payable {}

    // NOTE: to support open-zeppelin/upgrades, leave it blank
    constructor() public { }

    /// @dev It is called by the proxy (open-zeppelin/upgrades), only ONCE!
    function initialize(address NestPool) external 
    {
        require(flag == DAO_FLAG_UNINITIALIZED, "Nest:DAO:!flag");
        governance = msg.sender;
        flag = DAO_FLAG_INITIALIZED;
        C_NestPool = NestPool;
        ntokenRepurchaseThreshold = DAO_REPURCHASE_NTOKEN_TOTALSUPPLY;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovernance() 
    {
        require(msg.sender == governance, "Nest:DAO:!governance");
        _;
    }

    modifier onlyGovOrBy(address _contract) 
    {
        require(msg.sender == governance || msg.sender == _contract, "Nest:DAO:!sender");
        _;
    }

    modifier whenActive() 
    {
        require(flag == DAO_FLAG_ACTIVE, "Nest:DAO:!flag");
        _;
    }

    /* ========== GOVERNANCE ========== */

    /// @dev Ensure that all governance-addresses be consistent with each other
    function loadGovernance() override external 
    { 
        governance = INestPool(C_NestPool).governance();
    }

    /// @dev The function loads all nest-contracts, it is supposed to be called by NestPool
    function loadContracts() override external onlyGovOrBy(C_NestPool)
    {
        C_NestToken = INestPool(C_NestPool).addrOfNestToken();
        C_NestStaking = INestPool(C_NestPool).addrOfNestStaking();
        C_NestQuery = INestPool(C_NestPool).addrOfNestQuery();
        C_NestMining = INestPool(C_NestPool).addrOfNestMining();
    }

    function start() override external onlyGovernance
    {  
        require(flag == DAO_FLAG_INITIALIZED, "Nest:DAO:!flag");
        ERC20(C_NestToken).approve(C_NestStaking, uint(-1));
        startedBlock = uint32(block.number);
        lastCollectingBlock = uint32(block.number);
        flag = DAO_FLAG_ACTIVE;
        collectInterval = DAO_COLLECT_INTERVAL;
        emit FlagSet(address(msg.sender), uint256(DAO_FLAG_ACTIVE));
    }

    /// @dev Stop service for emergency
    function pause() external onlyGovernance
    {
        require(flag == DAO_FLAG_ACTIVE, "Nest:DAO:!flag");
        flag = DAO_FLAG_PAUSED;
        emit FlagSet(address(msg.sender), uint256(DAO_FLAG_PAUSED));
    }

    /// @dev Resume service 
    function resume() external onlyGovernance
    {
        require(flag == DAO_FLAG_ACTIVE || flag == DAO_FLAG_PAUSED, "Nest:DAO:!flag");
        flag = DAO_FLAG_ACTIVE;
        emit FlagSet(address(msg.sender), uint256(DAO_FLAG_ACTIVE));
    }

    function setParams(uint256 _ntokenRepurchaseThreshold, uint256 _collectInterval) external onlyGovernance
    {
        emit ParamsSetup(address(msg.sender), ntokenRepurchaseThreshold, _ntokenRepurchaseThreshold);
        ntokenRepurchaseThreshold = _ntokenRepurchaseThreshold;
        emit ParamsSetup(address(msg.sender), collectInterval, _collectInterval);
        collectInterval = _collectInterval;
    }

    function totalETHRewards(address ntoken)
        external view returns (uint256) 
    {
       return  ethLedger[ntoken];
    }

    /// @notice Migrate ethers to a new NestDAO
    /// @param newDAO_ The address of the new contract
    /// @param ntokenL_ The list of ntokens whose ethers are going to be migrated
    function migrateTo(address newDAO_, address[] memory ntokenL_) external onlyGovernance
    {
        require(flag == DAO_FLAG_PAUSED, "Nest:DAO:!flag");
        uint256 _len = ntokenL_.length;
        for (uint256 i; i < _len; i++) {
            address _ntoken = ntokenL_[i];
            uint256 _blncs = ethLedger[_ntoken];

            INestDAO(newDAO_).addETHReward{value:_blncs}(_ntoken);
            
            ethLedger[_ntoken] = 0;

            uint256 _staked = INestStaking(C_NestStaking).stakedBalanceOf(_ntoken, address(this));
            if (_staked > 0) {
                INestStaking(C_NestStaking).unstake(_ntoken, _staked);
            }

            uint256 _ntokenAmount = ERC20(_ntoken).balanceOf(address(this));

            if (_ntokenAmount > 0) {
                ERC20(_ntoken).transfer(newDAO_, _ntokenAmount);

            }
        }
    }

    /// @dev The function shall be called when ethers are taken from Nestv3.0
    function initEthLedger(address ntoken, uint256 amount) 
        override external
        onlyGovernance 
    {
        require (flag == DAO_FLAG_INITIALIZED, "Nest:DAO:!flag");
        ethLedger[ntoken] = amount;

    }

    /* ========== MAIN ========== */

    /// @notice Pump eth rewards to NestDAO for repurchasing `ntoken`
    /// @param ntoken The address of ntoken in the ether Ledger
    function addETHReward(address ntoken) 
        override
        external
        payable
    {
        ethLedger[ntoken] = ethLedger[ntoken].add(msg.value);
    }

    /// @dev Called by NestMining
    function addNestReward(uint256 amount) 
        override 
        external 
        onlyGovOrBy(C_NestMining)
    {
        Ledger storage it = ntokenLedger[C_NestToken];
        it.rewardedAmount = uint128(uint256(it.rewardedAmount).add(amount));
    }

    /// @dev Collect ethers from NestPool
    function collectNestReward() public returns(uint256)
    {
        // withdraw NEST from NestPool (mined by miners)
        uint256 nestAmount = INestPool(C_NestPool).balanceOfTokenInPool(address(this), C_NestToken);
        if (nestAmount == 0) {
            return 0;
        }

        INestPool(C_NestPool).withdrawNest(address(this), nestAmount);

        return nestAmount;
    }


    /// @dev Collect ethers from NestStaking
    function collectETHReward(address ntoken) public returns (uint256)
    {
        // check if ntoken is a NTOKEN
        address _ntoken = INestPool(C_NestPool).getNTokenFromToken(ntoken);
        require (_ntoken == ntoken, "Nest:DAO:!ntoken");

        uint256 ntokenAmount = ERC20(ntoken).balanceOf(address(this));

        // if (ntokenAmount == 0) {
        //     return 0;
        // }
        // // stake new NEST/NTOKENs into StakingPool
        // INestStaking(C_NestStaking).stake(ntoken, ntokenAmount);

        if (ntokenAmount != 0) {
            // stake new NEST/NTOKENs into StakingPool
            INestStaking(C_NestStaking).stake(ntoken, ntokenAmount);
        }

        // claim rewards from StakingPool 
        uint256 _rewards = INestStaking(C_NestStaking).claim(ntoken);
        ethLedger[ntoken] = ethLedger[ntoken].add(_rewards);

        return _rewards;
    }

    function _collect(address ntoken) internal
    {
        if (block.number < uint256(lastCollectingBlock).add(collectInterval)) {
            return;
        }

        uint256 ethAmount = collectETHReward(ntoken);
        
        uint256 nestAmount = collectNestReward();
        
        lastCollectingBlock = uint32(block.number);
        emit AssetsCollected(address(msg.sender), ethAmount, nestAmount);
    }

    /// @dev Redeem ntokens for ethers
    function redeem(address ntoken, uint256 amount) 
        external payable nonReentrant whenActive
    {
        // check if ntoken is a NTOKEN
        address _ntoken = INestPool(C_NestPool).getNTokenFromToken(ntoken);
        require (_ntoken == ntoken, "Nest:DAO:!ntoken");

        require (msg.value >= _ethFee, "Nest:DAO:!ethFee");

        require(INToken(ntoken).totalSupply() >= ntokenRepurchaseThreshold, "Nest:DAO:!total");

        // check if there is sufficient ethers for repurchase
        uint256 bal = ethLedger[ntoken];
        require(bal > 0, "Nest:DAO:!bal");

        // check the repurchasing quota
        uint256 quota = quotaOf(ntoken);

        // check if the price is steady
        uint256 price;
        bool isDeviated;
        
        
        {
            (uint256 ethAmount, uint256 tokenAmount,) = INestMining(C_NestMining).latestPriceOf(ntoken);
            (, uint256 avg, ,) = INestMining(C_NestMining).priceAvgAndSigmaOf(ntoken);
            price = tokenAmount.mul(1e18).div(ethAmount);

            uint256 diff = price > avg? (price - avg) : (avg - price);
            isDeviated = (diff.mul(100) < avg.mul(DAO_REPURCHASE_PRICE_DEVIATION))? false : true;

            if(msg.value > _ethFee){
                TransferHelper.safeTransferETH(msg.sender, msg.value.sub(_ethFee));
            }
            this.addETHReward{value:_ethFee}(address(ntoken));

        }

        require(isDeviated == false, "Nest:DAO:!price");

        // check if there is sufficient quota for repurchase
        require (amount <= quota, "Nest:DAO:!quota");
        // amount.mul(1e18).div(price) < bal
        require (amount.mul(1e18) <= bal.mul(price), "Nest:DAO:!bal2");

        // update the ledger
        Ledger memory it = ntokenLedger[ntoken];

        it.redeemedAmount = uint128(amount.add(it.redeemedAmount));
        it.quotaAmount = uint128(quota.sub(amount));
        it.lastBlock = uint32(block.number);
        ntokenLedger[ntoken] = it;

        // transactions
        ethLedger[ntoken] = ethLedger[ntoken].sub(amount.mul(1e18).div(price));

        ERC20(ntoken).transferFrom(address(msg.sender), address(this), amount);
        TransferHelper.safeTransferETH(msg.sender, amount.mul(1e18).div(price));

        _collect(ntoken); 
    }

    // function _price(address ntoken) internal view 
    //     returns (uint256 price, uint256 avg, bool isDeviated)
    // {
    //     (price, avg, , ) = 
    //         INestQuery(C_NestQuery).queryPriceAvgVola(ntoken, );
    //     uint256 diff = price > avg? (price - avg) : (avg - price);
    //     isDeviated = (diff.mul(100) < avg.mul(DAO_REPURCHASE_PRICE_DEVIATION))? false : true;
    // }

    function _quota(address ntoken) internal view returns (uint256 quota) 
    {
        if (INToken(ntoken).totalSupply() < ntokenRepurchaseThreshold) {
            return 0;
        }

        //  calculate the accumulated amount of NEST/NTOKEN available to repurchasing
        Ledger memory it = ntokenLedger[ntoken];
        uint256 _acc;
        uint256 n;
        if(ntoken == C_NestToken){
             n = 1000;
            uint256 intv = (it.lastBlock == 0) ? 
                (block.number).sub(startedBlock) : (block.number).sub(uint256(it.lastBlock));
            _acc = (n * intv > 300_000)? 300_000 : (n * intv);
        }else{
            n = 10;
            uint256 intv = (it.lastBlock == 0) ? 
                (block.number).sub(startedBlock) : (block.number).sub(uint256(it.lastBlock));
            _acc = (n * intv > 3000)? 3000 : (n * intv);
        }

        uint256 total;
         total = _acc.mul(1e18).add(it.quotaAmount);
        if(ntoken == C_NestToken){
            if(total > uint256(300_000).mul(1e18)){
                quota = uint256(300_000).mul(1e18);
            }else{
                quota = total;
            }   
        }else{
            if(total > uint256(3000).mul(1e18)){
                quota = uint256(3000).mul(1e18);
            }else{
                quota = total;
            }   
        }
        
    }

    /* ========== VIEWS ========== */

    function quotaOf(address ntoken) public view returns (uint256 quota) 
    {
       // check if ntoken is a NTOKEN
        address _ntoken = INestPool(C_NestPool).getNTokenFromToken(ntoken);
        require (_ntoken == ntoken, "Nest:DAO:!ntoken");

        return _quota(ntoken);
    }
}