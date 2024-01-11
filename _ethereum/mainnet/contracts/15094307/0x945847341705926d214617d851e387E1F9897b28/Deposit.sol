// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ITornadoStakingRewards.sol";
import "./ITornadoGovernanceStaking.sol";
import "./IRelayerRegistry.sol";
import "./RootDB.sol";
import "./ProfitRecord.sol";
import "./ExitQueue.sol";
import "./Initializable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./draft-IERC20PermitUpgradeable.sol";

/**
 * @title Deposit contract
 * @notice this is a Deposit contract
 */

contract Deposit is  ReentrancyGuardUpgradeable {

    /// the address of  torn token contract
    address immutable public TORN_CONTRACT;
    /// the address of  torn gov staking contract
    address immutable public TORN_GOVERNANCE_STAKING;
    /// the address of  torn relayer registry contract
    address immutable public TORN_RELAYER_REGISTRY;
    /// the address of  torn ROOT_DB contract
    address immutable public ROOT_DB;

    /// the address of  dev's rewards
    address public rewardAddress;
    /// the ratio of  dev's rewards which is x/1000
    uint256 public profitRatio;
    /// the max torn in the Deposit contact ,if over this amount it will been  staking to gov staking contract
    uint256 public maxReserveTorn;
    /// the max reward torn in  gov staking contract  ,if over this amount it will been claimed
    uint256 public maxRewardInGov;

    /// this  is the max uint256 , this flag is used to indicate insufficient
    uint256 constant public  IN_SUFFICIENT = 2**256 - 1;
    /// this  is the max uint256 , this flag is used to indicate sufficient
    uint256 constant public  SUFFICIENT = 2**256 - 2;


    /// @notice An event emitted when lock torn to gov staking contract
    /// @param _amount The amount which staked to gov staking contract
    event lock_to_gov(uint256 _amount);

    /// @notice An event emitted when user withdraw
    /// @param  _account The: address of user
    /// @param _token_qty: voucher of the deposit
    /// @param _torn: the amount of torn in this withdarw
    /// @param _profit: the profi of torn in this withdarw
    event with_draw(address  _account,uint256 _token_qty,uint256 _torn,uint256 _profit);

    constructor(
        address _torn_contract,
        address _torn_governance_staking,
        address _torn_relayer_registry,
        address _root_db
    ) {
        TORN_CONTRACT = _torn_contract;
        TORN_GOVERNANCE_STAKING = _torn_governance_staking;
        TORN_RELAYER_REGISTRY = _torn_relayer_registry;
        ROOT_DB = _root_db;
    }


    modifier onlyOperator() {
        require(msg.sender == RootDB(ROOT_DB).operator(), "Caller is not operator");
        _;
    }

    modifier onlyExitQueue() {
        require(msg.sender == RootDB(ROOT_DB).exitQueueContract(), "Caller is not exitQueue");
        _;
    }


    function __Deposit_init() public initializer {
        __ReentrancyGuard_init();
    }

    /**
    * @notice setPara used to set parameters called by Operator
    * @param _index index para
            * index 1 maxReserveTorn;
            * index 2 _maxRewardInGov;
            * index 3 _rewardAddress
            * index 4 profitRatio  x/1000
    * @param _value
   **/
    function setPara(uint256 _index,uint256 _value) external onlyOperator {
        if(_index == 1){
            maxReserveTorn = _value;
        }else if(_index == 2){
            maxRewardInGov = _value;
        }else if(_index == 3){
            rewardAddress = address(uint160(_value));
        }else  if(_index == 4){
            profitRatio = _value;
        }
        else{
            require(false,"Invalid _index");
        }
    }

    /**
    * @notice _checkLock2Gov used to check whether the TORN balance of the contract  is over maxReserveTorn
              if it is ture ,lock it to TORN_GOVERNANCE_STAKING
   **/
    function _checkLock2Gov() internal  {
        uint256 balance = IERC20Upgradeable(TORN_CONTRACT).balanceOf(address(this));
        if(maxReserveTorn >= balance){
            return ;
        }
        SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(TORN_CONTRACT),TORN_GOVERNANCE_STAKING, balance);
        ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).lockWithApproval(balance);
        emit lock_to_gov(balance);
    }

    /**
     * @notice _nextExitQueueValue used to get the exitQueue next user's waiting Value
      if no one is waiting or all users are prepared return 0
     * return the Value waiting for
    **/
    function  _nextExitQueueValue()  view internal returns(uint256 value){
        value = ExitQueue(RootDB(ROOT_DB).exitQueueContract()).nextValue();
    }

    /**
     * @notice getValueShouldUnlockFromGov used get the Value should unlock from gov staking contract
     * return
          1. if noneed to unlock return 0

          2. if there is not enough torn to unlock for exit queue retrun  IN_SUFFICIENT
          3. other values are the value should to unlock
    **/
    function getValueShouldUnlockFromGov() public view returns (uint256) {

        uint256 next_value = _nextExitQueueValue();
        if(next_value == 0 ){
            return 0;
        }
        uint256 this_balance = IERC20Upgradeable(TORN_CONTRACT).balanceOf(address(this));

        if(next_value <= this_balance){
            return 0;
        }
        uint256 shortage =  next_value -IERC20Upgradeable(TORN_CONTRACT).balanceOf(address(this)) ;
        if(shortage <= ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).lockedBalance(address(this)))
        {
            return shortage;
        }
        return  IN_SUFFICIENT;
    }

    /**
       * @notice isNeedClaimFromGov used to check if the gov staking contract reward
       * return   the staking reward is over maxRewardInGov ?
    **/
    function isNeedClaimFromGov() public view returns (bool) {
        uint256 t = ITornadoStakingRewards(ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).Staking()).checkReward(address(this));
        return t > maxRewardInGov;
    }

    /**
       * @notice isNeedTransfer2Queue used to check if need to Transfer torn to exit queue
       * return   true if the balance of torn is over the next value
    **/
    function isNeedTransfer2Queue() public view returns (bool) {
       uint256 next_value = _nextExitQueueValue();
        if(next_value == 0 ){
            return false;
        }
        return IERC20Upgradeable(TORN_CONTRACT).balanceOf(address(this)) > next_value;
    }

    /**
       * @notice stake2Node used to stake TORN to relayers  when it is necessary call by Operator
       * @param  index: the index of the relayer
       * @param qty: the amount of TORN to be stake
    **/
    function stake2Node(uint256 index, uint256 qty) external onlyOperator {
        address _relayer = RootDB(ROOT_DB).mRelayers(index);
        require(_relayer != address(0), 'Invalid index');
        SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(TORN_CONTRACT),TORN_RELAYER_REGISTRY, qty);
        IRelayerRegistry(TORN_RELAYER_REGISTRY).stakeToRelayer(_relayer, qty);
    }


   /**
       * @notice deposit used to deposit TORN to relayers dao  with permit param
       * @param  _torn_qty: the amount of torn want to stake
       * @param   deadline ,v,r,s  permit param
    **/
    function deposit(uint256 _torn_qty,uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        IERC20PermitUpgradeable(TORN_CONTRACT).permit(msg.sender, address(this), _torn_qty, deadline, v, r, s);
        depositWithApproval(_torn_qty);
    }

    /**
       * @notice deposit used to deposit TORN to relayers dao  with approval
       * @param  _token_qty: the amount of torn want to stake
       * @dev
           1. mint the voucher of the deposit.
           2. TransferFrom TORN to this contract
           3. recorde the raw 'price' of the voucher for compute profit
           4. check the auto work to do
                1.  isNeedTransfer2Queue
                2.  isNeedClaimFromGov
                3.  checkLock2Gov
                4. or unlock for the gov prepare to Transfer2Queue
    **/
    function depositWithApproval(uint256 _token_qty) public nonReentrant {
        address _account = msg.sender;
        require(_token_qty > 0,"error para");
        uint256 root_token = RootDB(ROOT_DB).safeMint(_account, _token_qty);
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(TORN_CONTRACT),_account, address(this), _token_qty);
        //record the deposit
        ProfitRecord(RootDB(ROOT_DB).profitRecordContract()).deposit(msg.sender, _token_qty,root_token);

        // this is designed to avoid pay too much gas by one user
         if(isNeedTransfer2Queue()){
             ExitQueue(RootDB(ROOT_DB).exitQueueContract()).executeQueue();
        }else if(isNeedClaimFromGov()){
             _claimRewardFromGov();
         } else{
             uint256 need_unlock =  getValueShouldUnlockFromGov();

             if(need_unlock == 0){
                 _checkLock2Gov();
                 return ;
             }
            if(need_unlock != IN_SUFFICIENT){
                ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).unlock(need_unlock);
             }
         }

    }

    /**
       * @notice getValueShouldUnlock used to get the amount of TORN and the shortage of TORN
       * @param  _token_qty:  the amount of the voucher
       * return (shortage ,torn)
              shortage:  the shortage of TRON ,if the user want to with draw the _token_qty voucher
                        1. if the balance of TORN in this contract is enough return SUFFICIENT
                        2. if the balance of TORN added the lock balance in gov are not enough return IN_SUFFICIENT
                        3. others is the amount which show unlock for the withdrawing
              torn    :  the amount of TORN if the user with draw the qty of  _token_qty
    **/
    function getValueShouldUnlock(uint256 _token_qty)  public view  returns (uint256 shortage,uint256 torn){
        uint256 this_balance_tron = IERC20Upgradeable(TORN_CONTRACT).balanceOf(address(this));
        // _amount_token
         torn = RootDB(ROOT_DB).valueForTorn(_token_qty);
        if(this_balance_tron >= torn){
            shortage = SUFFICIENT;
            return (shortage,torn);
        }
        uint256 _lockingAmount = ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).lockedBalance(address(this));
         shortage = torn - this_balance_tron;
        if(_lockingAmount < shortage){
            shortage = IN_SUFFICIENT;
        }
    }


    /**
       * @notice _safeWithdraw used to withdraw
       * @param  _token_qty:  the amount of the voucher
       * @return  the amount of TORN user get
       * @dev
             1. Unlock torn form gov if necessary
             2. burn the _token_qty of the voucher
    **/
   function _safeWithdraw(uint256 _token_qty) internal  returns (uint256){
       require(_token_qty > 0,"error para");
       uint256  shortage;
       uint256 torn;
       (shortage,torn) = getValueShouldUnlock(_token_qty);
       require(shortage != IN_SUFFICIENT, 'pool Insufficient');
       if(shortage != SUFFICIENT) {
           ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).unlock(shortage);
       }
       RootDB(ROOT_DB).safeBurn(msg.sender, _token_qty);
       return torn;
   }

    /**
       * @notice _safeSendTorn used to send TORN to withdrawer and profit to dev team
       * @param  _torn: amount of TORN user got
       * @param  _profit: the profit of the user got
       * return  the user got TORN which subbed the dev profit
    **/
    function _safeSendTorn(uint256 _torn,uint256 _profit) internal returns(uint256 ret) {
        _profit = _profit *profitRatio/1000;
        //send to  profitAddress
        if(_profit > 0){
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(TORN_CONTRACT),rewardAddress, _profit);
        }
        ret = _torn - _profit;
        //send to  user address
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(TORN_CONTRACT),msg.sender, ret);
    }

    /**
       * @notice  used to  withdraw
       * @param  _token_qty:  the amount of the voucher
       * @dev inorder to save gas we had modified erc20 token which no need to approve
    **/
    function withDraw(uint256 _token_qty)  public nonReentrant {
        require( _nextExitQueueValue() == 0,"Queue not empty");
        address profit_address = RootDB(ROOT_DB).profitRecordContract();
        uint256 profit = ProfitRecord(profit_address).withDraw(msg.sender, _token_qty);
        uint256 torn = _safeWithdraw(_token_qty);
        _safeSendTorn(torn,profit);
        emit with_draw(msg.sender, _token_qty,torn,profit);
    }

    /**
       * @notice  used to  withdraw
       * @param  _addr:  the addr of user
       * @param  _token_qty:  the amount of the voucher
       * @dev    because of nonReentrant have to supply this function for exitQueue
       * return  the user got TORN which subbed the dev profit
    **/
    function withdraw_for_exit(address _addr,uint256 _token_qty)  external onlyExitQueue returns (uint256 ret) {
        address profit_address = RootDB(ROOT_DB).profitRecordContract();
        uint256 profit = ProfitRecord(profit_address).withDraw(_addr, _token_qty);
        uint256 torn = _safeWithdraw(_token_qty);
        ret =  _safeSendTorn(torn,profit);
        emit with_draw(_addr, _token_qty,torn,profit);
    }


    /**
       * @notice totalBalanceOfTorn
       * return  the total Balance Of  TORN which controlled  buy this contract
    **/
    function totalBalanceOfTorn()  external view returns (uint256 ret) {
        ret = IERC20Upgradeable(TORN_CONTRACT).balanceOf(address(this));
        ret += balanceOfStakingOnGov();
        ret += checkRewardOnGov();
    }

    /**
       * @notice isBalanceEnough
       *  return whether is Enough TORN for user to withdraw the _token_qty
    **/
    function isBalanceEnough(uint256 _token_qty)  external view returns (bool) {
        if( _nextExitQueueValue() != 0){
            return false;
        }
        uint256  shortage;
        (shortage,) = getValueShouldUnlock(_token_qty);
        return shortage < IN_SUFFICIENT;
    }

    function balanceOfStakingOnGov() public view returns (uint256 ) {
        return ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).lockedBalance(address(this));
    }

    function checkRewardOnGov()  public view returns (uint256) {
        return ITornadoStakingRewards(ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).Staking()).checkReward(address(this));
    }

    /**
       * @notice claim Reward From Gov staking
    **/
    function _claimRewardFromGov() internal {
        address _stakingRewardContract = ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).Staking();
        ITornadoStakingRewards(_stakingRewardContract).getReward();
    }

    function depositIni(address addr,uint256 _torn) external onlyOperator {
        uint256 root_token = RootDB(ROOT_DB).safeMint(addr, _torn);
        ProfitRecord(RootDB(ROOT_DB).profitRecordContract()).deposit(addr,_torn,root_token);
    }

}
