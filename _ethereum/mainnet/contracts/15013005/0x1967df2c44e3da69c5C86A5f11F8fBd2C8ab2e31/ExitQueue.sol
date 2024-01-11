pragma solidity ^0.8.0;

import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./draft-IERC20PermitUpgradeable.sol";
import "./IExitQueue.sol";
import "./IRootManger.sol";
import "./IDepositContract.sol";

contract ExitQueue is OwnableUpgradeable,IExitQueue, ReentrancyGuardUpgradeable{


    struct QUEUE_INFO {
        uint256 v;
        address addr;
    }


    address immutable public ROOT_MANAGER;
    address immutable  public TORN_CONTRACT;


    uint256 public preparedIndex=0;  //begin with 0
    uint256 public maxIndex = 0;   //begin with 0
    mapping(address => uint256) public addr2index;
    mapping(uint256 => QUEUE_INFO) public index2value;

    uint256 constant public  INDEX_ERR = 2**256 - 1;
    uint256 constant public  MAX_QUEUE_CANCEL = 100;
    function __ExitQueue_init() public initializer {
        __ReentrancyGuard_init();
    }


    /** ---------- constructor ---------- **/
    constructor(address _tornContract, address _root_manager ) {
        TORN_CONTRACT = _tornContract;
        ROOT_MANAGER = _root_manager;
    }



    function address2Value(address addr) view public returns (uint256 v,bool prepared){
        uint256 index = addr2index[addr];
        v = index2value[index].v;
        prepared = preparedIndex >= index;
    }

    function nextSkipIndex() view public returns (uint256){

        uint256 maxIndex_ = maxIndex;             // save gas
        uint256 preparedIndex_ = preparedIndex;   // save gas

        uint256 next_index = 0;
        uint256 index ;
        if(maxIndex_ <= preparedIndex_){
            return 0;
        }
         // MAX_QUEUE_CANCEL avoid out of gas
        for(index = 1 ;index < MAX_QUEUE_CANCEL ;index++){
            next_index = preparedIndex_+index;
            uint256 next_value = index2value[next_index].v;
            if( maxIndex_ ==  next_index|| next_value > 0){
                return index;
            }
        }
        return INDEX_ERR;
    }


    // to avoid out of gas everyone would call this function to update the index
    // those codes are not elegant code ,is any better way?
    function UpdateSkipIndex()  public nonReentrant{
       uint256 next_index = nextSkipIndex();
       require(next_index == INDEX_ERR,"skip is too short");
       preparedIndex = preparedIndex+99;// skip the index
    }

    event add_queue(uint256 _amount_token);
    function addQueue(uint256 _amount_token) override public  nonReentrant{
        maxIndex += 1;
        require(_amount_token > 0,"error para");
        require(addr2index[_msgSender()] == 0 && index2value[maxIndex].v==0,"have pending");
        addr2index[_msgSender()] = maxIndex;
        index2value[maxIndex] = QUEUE_INFO(_amount_token,_msgSender());
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(ROOT_MANAGER),_msgSender(), address(this), _amount_token);
        emit add_queue(_amount_token);
    }

    event cancel_queue(address account, uint256 _amount_token);
    function  cancelQueue() override external  nonReentrant{
        uint256 index = addr2index[_msgSender()];
        uint256 value = index2value[index].v;
        require(value > 0,"empty");
        require(index > preparedIndex,"prepared");
        delete addr2index[_msgSender()];
        delete index2value[index];
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(ROOT_MANAGER),_msgSender(),value);
        emit cancel_queue(_msgSender(),value);
    }

    function  executeQueue() override external  nonReentrant{
        address deposit_addr = IRootManger(ROOT_MANAGER).depositContract();
        uint256 value = 0;
        require(maxIndex >=  preparedIndex+1,"no pending");
        uint256 next = nextSkipIndex();
        require(INDEX_ERR != next,"too many skips");
        preparedIndex+=next;
         QUEUE_INFO memory info = index2value[preparedIndex];
        value = IDepositContract(deposit_addr).withdraw_for_exit(info.addr,info.v);
        index2value[preparedIndex].v = value;
    }

    function  nextValue() override view external returns(uint256 value) {
        uint256 next = nextSkipIndex();
        if(next == 0) {
            return 0;
        }
        require(INDEX_ERR != next,"too many skips");

        // avoid the last one had canceled;
        uint256 nextValue = index2value[preparedIndex+next].v;
        if(nextValue == 0)
        {
            return 0;
        }

       return IRootManger(ROOT_MANAGER).valueForTorn(nextValue);
    }
    function  withDraw() override external nonReentrant {
        uint256 index =addr2index[_msgSender()];
        require(index <= preparedIndex,"not prepared");
        uint256 value =index2value[index].v;
        require(value > 0 ,"have no pending");
        delete addr2index[_msgSender()];
        delete index2value[index];
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(TORN_CONTRACT),_msgSender(),value);
    }
}
