pragma solidity 0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
/**
 * @title Voting factory + mapping
 投票工厂+ 映射
 * @dev Vote creating method
 创建与投票方法
 */
contract Nest_3_VoteFactory {
    using SafeMath for uint256;
    
    uint256 _limitTime = 7 days;                                    //  Vote duration投票持续时间
    uint256 _NNLimitTime = 1 days;                                  //  NestNode raising time NestNode筹集时间
    uint256 _circulationProportion = 51;                            //  Proportion of votes to pass 通过票数比例
    uint256 _NNUsedCreate = 10;                                     //  The minimum number of NNs to create a voting contract创建投票合约最小 NN 数量
    uint256 _NNCreateLimit = 100;                                   //  The minimum number of NNs needed to start voting开启投票需要筹集 NN 最小数量
    uint256 _emergencyTime = 0;                                     //  The emergency state start time紧急状态启动时间
    uint256 _emergencyTimeLimit = 3 days;                           //  The emergency state duration紧急状态持续时间
    uint256 _emergencyNNAmount = 1000;                              //  The number of NNs required to switch the emergency state切换紧急状态需要nn数量
    ERC20 _NNToken;                                                 //  NestNode Token守护者节点Token（NestNode）
    ERC20 _nestToken;                                               //  NestToken
    mapping(string => address) _contractAddress;                    //  Voting contract mapping投票合约映射
    mapping(address => bool) _modifyAuthority;                      //  Modify permissions修改权限
    mapping(address => address) _myVote;                            //  Personal voting address我的投票
    mapping(address => uint256) _emergencyPerson;                   //  Emergency state personal voting number紧急状态个人存储量
    mapping(address => bool) _contractData;                         //  Voting contract data投票合约集合
    bool _stateOfEmergency = false;                                 //  Emergency state紧急状态
    address _destructionAddress;                                    //  Destroy contract address销毁合约地址

    event ContractAddress(address contractAddress);
    
    /**
    * @dev Initialization method
    */
    constructor () public {
        _modifyAuthority[address(msg.sender)] = true;
		//将修改权限者（也叫超级用户）。
    }
    
    /** nest
    * @dev Reset contract
	重置合约
    */
    function changeMapping() public onlyOwner {
        _NNToken = ERC20(checkAddress("nestNode"));
        _destructionAddress = address(checkAddress("nest.v3.destruction"));
        _nestToken = ERC20(address(checkAddress("nest")));
    }
	//这个地方刷新nestnode，nest.v3.destruction，以及nestnode
    
    /**
    * @dev Create voting contract
	创建投票合约
    * @param implementContract The executable contract address for voting
	投票可执行合约地址
    * @param nestNodeAmount Number of NNs to pledge
	质押 NN 数量
    */
    function createVote(address implementContract, uint256 nestNodeAmount) public {
        require(address(tx.origin) == address(msg.sender), "It can't be a contract");
        require(nestNodeAmount >= _NNUsedCreate);
        Nest_3_VoteContract newContract = new Nest_3_VoteContract(implementContract, _stateOfEmergency, nestNodeAmount);
        //建立一个新的投票，这里主要是初始化一个Nest_3_VoteContract结构体
		require(_NNToken.transferFrom(address(tx.origin), address(newContract), nestNodeAmount), "Authorization transfer failed");
        //传输nn数量
		_contractData[address(newContract)] = true;
		//新投票成立
        emit ContractAddress(address(newContract));
		//监听新合约地址事件
    }
    
    /**
    * @dev Use NEST to vote
	使用nest投票
    * @param contractAddress Vote contract address
	投票合约地址
    */
    function nestVote(address contractAddress) public {
        require(address(msg.sender) == address(tx.origin), "It can't be a contract");
        require(_contractData[contractAddress], "It's not a voting contract");
		//先检测地址是否合法
        require(!checkVoteNow(address(msg.sender)));
		//如果投票未结束，或者发送者投票为0则继续
		//检查投票者
        Nest_3_VoteContract newContract = Nest_3_VoteContract(contractAddress);
		//建立一个用于投票的合约
        newContract.nestVote();
		//投票
        _myVote[address(tx.origin)] = contractAddress;
		//我的投票地址为contractAddress
    }
    
    /**
    * @dev Vote using NestNode Token
	使用 nestNode 投票
    * @param contractAddress Vote contract address
	投票合约地址
    * @param NNAmount Amount of NNs to pledge
	质押 NN 数量
    */
    function nestNodeVote(address contractAddress, uint256 NNAmount) public {
        require(address(msg.sender) == address(tx.origin), "It can't be a contract");
        require(_contractData[contractAddress], "It's not a voting contract");
        Nest_3_VoteContract newContract = Nest_3_VoteContract(contractAddress);
		//建立一个用于投票的合约
        require(_NNToken.transferFrom(address(tx.origin), address(newContract), NNAmount), "Authorization transfer failed");
		//将币传输到合约地址
        newContract.nestNodeVote(NNAmount);
    }
    
    /**
    * @dev Excecute contract
	执行投票
    * @param contractAddress Vote contract address
	投票合约地址
    */
    function startChange(address contractAddress) public {
        require(address(msg.sender) == address(tx.origin), "It can't be a contract");
        require(_contractData[contractAddress], "It's not a voting contract");
        Nest_3_VoteContract newContract = Nest_3_VoteContract(contractAddress);
		//获得这个地址的智能合约
        require(_stateOfEmergency == newContract.checkStateOfEmergency());
		//检测是不是状态一致
        addSuperManPrivate(address(newContract));
		//使得这个地址获取超级用户权力
        newContract.startChange();
		//运行（但目前没有这个接口文件）
        deleteSuperManPrivate(address(newContract));
		//解除超级用户权限
    }
    
    /**
    * @dev Switch emergency state-transfer in NestNode Token
	切换紧急状态-转入NestNode
    * @param amount Amount of NNs to transfer
	转入 NestNode 数量
    */
    function sendNestNodeForStateOfEmergency(uint256 amount) public {
		//单独调用的函数
        require(_NNToken.transferFrom(address(tx.origin), address(this), amount));
		//用户将自己的nn转入到这个合约地址里面
        _emergencyPerson[address(tx.origin)] = _emergencyPerson[address(tx.origin)].add(amount);
		//_emergencyPerson数组里面的该地址的nn增加。
    }
    
    /**
    * @dev Switch emergency state-transfer out NestNode Token
	切换紧急状态-取出NestNode
    */
    function turnOutNestNodeForStateOfEmergency() public {
        require(_emergencyPerson[address(tx.origin)] > 0);
        require(_NNToken.transfer(address(tx.origin), _emergencyPerson[address(tx.origin)]));
		//检测本地址是否应该有币要转移，然后把nn转移到本地址
        _emergencyPerson[address(tx.origin)] = 0;
        uint256 nestAmount = _nestToken.balanceOf(address(this));
		//检测本地址有多少nest
        require(_nestToken.transfer(address(_destructionAddress), nestAmount));
		//一并销毁
    }
    
    /**
    * @dev Modify emergency state
	修改紧急状态
    */
    function changeStateOfEmergency() public {
        if (_stateOfEmergency) {
            require(now > _emergencyTime.add(_emergencyTimeLimit));
			//now为当前时间戳
            _stateOfEmergency = false;
            _emergencyTime = 0;
			//如果为紧急状态，看是否结束，结束则赋值为false
        } else {
            require(_emergencyPerson[address(msg.sender)] > 0);
			//本人是否为注册
            require(_NNToken.balanceOf(address(this)) >= _emergencyNNAmount);
			//总量是否达标，
            _stateOfEmergency = true;
			//然后就执行
            _emergencyTime = now;
			//
        }
    }
    
    /**
    * @dev Check whether participating in the voting
	查看是否有正在参与的投票
    * @param user Address to check
	参与投票地址
    * @return bool Whether voting
	是否正在参与投票
    */
    function checkVoteNow(address user) public view returns (bool) {
        if (_myVote[user] == address(0x0)) {
            return false;
        } else {
            Nest_3_VoteContract vote = Nest_3_VoteContract(_myVote[user]);
			//建立一个投票者
            if (vote.checkContractEffective() || vote.checkPersonalAmount(user) == 0) {
				//满足一个条件就false，或者投票结束为真，或者投票者的checkPersonalAmount为0（未投票）
                return false;
            }
            return true;
        }
    }
    
    /**
    * @dev Check my voting
	查看我的投票
    * @param user Address to check
	参与投票地址
    * @return address Address recently participated in the voting contract address
	是否正在参与投票
    */
    function checkMyVote(address user) public view returns (address) {
        return _myVote[user];
    }
    
    //  Check the voting time
	//检查投票时间
    function checkLimitTime() public view returns (uint256) {
        return _limitTime;
    }
    
    //  Check the NestNode raising time
	//查看NestNode筹集时间
    function checkNNLimitTime() public view returns (uint256) {
        return _NNLimitTime;
    }
    
    //  Check the voting proportion to pass
	//查看通过投票比例
    function checkCirculationProportion() public view returns (uint256) {
        return _circulationProportion;
    }
    
    //  Check the minimum number of NNs to create a voting contract
	//查看创建投票合约最小 NN 数量
    function checkNNUsedCreate() public view returns (uint256) {
        return _NNUsedCreate;
    }
    
    //  Check the minimum number of NNs raised to start a vote
	//查看创建投票筹集 NN 最小数量
    function checkNNCreateLimit() public view returns (uint256) {
        return _NNCreateLimit;
    }
    
    //  Check whether in emergency state
	//查看是否是紧急状态
    function checkStateOfEmergency() public view returns (bool) {
        return _stateOfEmergency;
    }
    
    //  Check the start time of the emergency state
	//查看紧急状态启动时间
    function checkEmergencyTime() public view returns (uint256) {
        return _emergencyTime;
    }
    
    //  Check the duration of the emergency state
	//查看紧急状态持续时间
    function checkEmergencyTimeLimit() public view returns (uint256) {
        return _emergencyTimeLimit;
    }
    
    //  Check the amount of personal pledged NNs
	//查看个人 NN 存储量
    function checkEmergencyPerson(address user) public view returns (uint256) {
        return _emergencyPerson[user];
    }
    
    //  Check the number of NNs required for the emergency
	// 查看紧急状态需要 NN 数量
    function checkEmergencyNNAmount() public view returns (uint256) {
        return _emergencyNNAmount;
    }
    
    //  Verify voting contract data
	//验证投票合约
    function checkContractData(address contractAddress) public view returns (bool) {
        return _contractData[contractAddress];
    }
    
    //  Modify voting time
	//修改投票时间
    function changeLimitTime(uint256 num) public onlyOwner {
        require(num > 0, "Parameter needs to be greater than 0");
        _limitTime = num;
    }
    
    //  Modify the NestNode raising time
	//修改NestNode筹集时间
    function changeNNLimitTime(uint256 num) public onlyOwner {
        require(num > 0, "Parameter needs to be greater than 0");
        _NNLimitTime = num;
    }
    
    //  Modify the voting proportion
	//修改通过投票比例
    function changeCirculationProportion(uint256 num) public onlyOwner {
        require(num > 0, "Parameter needs to be greater than 0");
        _circulationProportion = num;
    }
    
    //  Modify the minimum number of NNs to create a voting contract
	//修改创建投票合约最小 NN 数量
    function changeNNUsedCreate(uint256 num) public onlyOwner {
        _NNUsedCreate = num;
    }
    
    //  Modify the minimum number of NNs to raised to start a voting
	//修改创建投票筹集 NN 最小数量
    function checkNNCreateLimit(uint256 num) public onlyOwner {
        _NNCreateLimit = num;
    }
    
    //  Modify the emergency state duration
	//修改紧急状态持续时间
    function changeEmergencyTimeLimit(uint256 num) public onlyOwner {
        require(num > 0);
        _emergencyTimeLimit = num.mul(1 days);
    }
    
    //  Modify the number of NNs required for emergency state
	//修改紧急状态需要 NN 数量
    function changeEmergencyNNAmount(uint256 num) public onlyOwner {
        require(num > 0);
        _emergencyNNAmount = num;
    }
    
    //  Check address
    function checkAddress(string memory name) public view returns (address contractAddress) {
        return _contractAddress[name];
    }
	//查看合约地址
    
    //  Add contract mapping address
    function addContractAddress(string memory name, address contractAddress) public onlyOwner {
        _contractAddress[name] = contractAddress;
    }
	//将合约名称与地址对应
    
    //  Add administrator address 
    function addSuperMan(address superMan) public onlyOwner {
        _modifyAuthority[superMan] = true;
    }
	//增加管理地址
	
    function addSuperManPrivate(address superMan) private {
        _modifyAuthority[superMan] = true;
    }
    
    //  Delete administrator address
	//删除管理地址
    function deleteSuperMan(address superMan) public onlyOwner {
        _modifyAuthority[superMan] = false;
    }
    function deleteSuperManPrivate(address superMan) private {
        _modifyAuthority[superMan] = false;
    }
	//解除合约管理员权限
    
    //  Delete voting contract data
	//删除投票合约集合
    function deleteContractData(address contractAddress) public onlyOwner {
        _contractData[contractAddress] = false;
    }
    
    //  Check whether the administrator
	//查看是否管理员
    function checkOwners(address man) public view returns (bool) {
        return _modifyAuthority[man];
    }
    
    //  Administrator only
	//仅管理员操作
    modifier onlyOwner() {
        require(checkOwners(msg.sender), "No authority");
        _;
    }
}

/**
 * @title Voting contract
 合约投票
 */
contract Nest_3_VoteContract {
    using SafeMath for uint256;
    
    Nest_3_Implement _implementContract;                //  Executable contract
    Nest_3_TokenSave _tokenSave;                        //  Lock-up contract
    Nest_3_VoteFactory _voteFactory;                    //  Voting factory contract
    Nest_3_TokenAbonus _tokenAbonus;                    //  Bonus logic contract
    ERC20 _nestToken;                                   //  NestToken
    ERC20 _NNToken;                                     //  NestNode Token
    address _miningSave;                                //  Mining pool contract
    address _implementAddress;                          //  Executable contract address
    address _destructionAddress;                        //  Destruction contract address
    uint256 _createTime;                                //  Creation time
    uint256 _endTime;                                   //  End time
    uint256 _totalAmount;                               //  Total votes
    uint256 _circulation;                               //  Passed votes
    uint256 _destroyedNest;                             //  Destroyed NEST
    uint256 _NNLimitTime;                               //  NestNode raising time
    uint256 _NNCreateLimit;                             //  Minimum number of NNs to create votes
    uint256 _abonusTimes;                               //  Period number of used snapshot in emergency state
    uint256 _allNNAmount;                               //  Total number of NNs
    bool _effective = false;                            //  Whether vote is effective
    bool _nestVote = false;                             //  Whether NEST vote can be performed
    bool _isChange = false;                             //  Whether NEST vote is executed
    bool _stateOfEmergency;                             //  Whether the contract is in emergency state
    mapping(address => uint256) _personalAmount;        //  Number of personal votes
    mapping(address => uint256) _personalNNAmount;      //  Number of NN personal votes
    
    /**
    * @dev Initialization method
    * @param contractAddress Executable contract address
    * @param stateOfEmergency Whether in emergency state
    * @param NNAmount Amount of NNs
    */
    constructor (address contractAddress, bool stateOfEmergency, uint256 NNAmount) public {
        Nest_3_VoteFactory voteFactory = Nest_3_VoteFactory(address(msg.sender));
        _voteFactory = voteFactory;
        _nestToken = ERC20(voteFactory.checkAddress("nest"));
        _NNToken = ERC20(voteFactory.checkAddress("nestNode"));
        _implementContract = Nest_3_Implement(address(contractAddress));
        _implementAddress = address(contractAddress);
        _destructionAddress = address(voteFactory.checkAddress("nest.v3.destruction"));
        _personalNNAmount[address(tx.origin)] = NNAmount;
        _allNNAmount = NNAmount;
        _createTime = now;                                    
        _endTime = _createTime.add(voteFactory.checkLimitTime());
        _NNLimitTime = voteFactory.checkNNLimitTime();
        _NNCreateLimit = voteFactory.checkNNCreateLimit();
        _stateOfEmergency = stateOfEmergency;
        if (stateOfEmergency) {
            //  If in emergency state, read the last two periods of bonus lock-up and total circulation data
            _tokenAbonus = Nest_3_TokenAbonus(voteFactory.checkAddress("nest.v3.tokenAbonus"));
            _abonusTimes = _tokenAbonus.checkTimes().sub(2);
            require(_abonusTimes > 0);
            _circulation = _tokenAbonus.checkTokenAllValueHistory(address(_nestToken),_abonusTimes).mul(voteFactory.checkCirculationProportion()).div(100);
        } else {
            _miningSave = address(voteFactory.checkAddress("nest.v3.miningSave"));
            _tokenSave = Nest_3_TokenSave(voteFactory.checkAddress("nest.v3.tokenSave"));
            _circulation = (uint256(10000000000 ether).sub(_nestToken.balanceOf(address(_miningSave))).sub(_nestToken.balanceOf(address(_destructionAddress)))).mul(voteFactory.checkCirculationProportion()).div(100);
        }
        if (_allNNAmount >= _NNCreateLimit) {
            _nestVote = true;
        }
    }
    
    /**
    * @dev NEST voting
    */
    function nestVote() public onlyFactory {
        require(now <= _endTime, "Voting time exceeded");
        require(!_effective, "Vote in force");
        require(_nestVote);
        require(_personalAmount[address(tx.origin)] == 0, "Have voted");
		//做各种检测，比如是否投票过了
        uint256 amount;
        if (_stateOfEmergency) {
            //  If in emergency state, read the last two periods of bonus lock-up and total circulation data
			//紧急状态读取前两期分红锁仓及总流通量数据
            amount = _tokenAbonus.checkTokenSelfHistory(address(_nestToken),_abonusTimes, address(tx.origin));
        } else {
            amount = _tokenSave.checkAmount(address(tx.origin), address(_nestToken));
		//否则就获取其nest的值
        }
        _personalAmount[address(tx.origin)] = amount;
		//设置已经投票过
        _totalAmount = _totalAmount.add(amount);
		//增加投票总数
        ifEffective();
    }
    
    /**
    * @dev NEST voting cancellation
    */
    function nestVoteCancel() public {
        require(address(msg.sender) == address(tx.origin), "It can't be a contract");
        require(now <= _endTime, "Voting time exceeded");
        require(!_effective, "Vote in force");
        require(_personalAmount[address(tx.origin)] > 0, "No vote");                     
        _totalAmount = _totalAmount.sub(_personalAmount[address(tx.origin)]);
        _personalAmount[address(tx.origin)] = 0;
    }
    
    /**
    * @dev  NestNode voting
	NN投票
    * @param NNAmount Amount of NNs
    */
    function nestNodeVote(uint256 NNAmount) public onlyFactory {
		//只能是factory智能合约调用
        require(now <= _createTime.add(_NNLimitTime), "Voting time exceeded");
        require(!_nestVote);
		//满足nn投票条件
        _personalNNAmount[address(tx.origin)] = _personalNNAmount[address(tx.origin)].add(NNAmount);
        _allNNAmount = _allNNAmount.add(NNAmount);
        if (_allNNAmount >= _NNCreateLimit) {
            _nestVote = true;
        }
		//如果符合条件则表示成功。
    }
    
    /**
    * @dev Withdrawing lock-up NNs
    */
    function turnOutNestNode() public {
        if (_nestVote) {
            //  Normal NEST voting
            if (!_stateOfEmergency || !_effective) {
                //  Non-emergency state
                require(now > _endTime, "Vote unenforceable");
            }
        } else {
            //  NN voting
            require(now > _createTime.add(_NNLimitTime));
        }
        require(_personalNNAmount[address(tx.origin)] > 0);
        //  Reverting back the NNs
        require(_NNToken.transfer(address(tx.origin), _personalNNAmount[address(tx.origin)]));
        _personalNNAmount[address(tx.origin)] = 0;
        //  Destroying NEST Tokens 
        uint256 nestAmount = _nestToken.balanceOf(address(this));
        _destroyedNest = _destroyedNest.add(nestAmount);
        require(_nestToken.transfer(address(_destructionAddress), nestAmount));
    }
    
    /**
    * @dev Execute the contract
	以超级用户的权力运行合约
    */
    function startChange() public onlyFactory {
        require(!_isChange);
        _isChange = true;
        if (_stateOfEmergency) {
            require(_effective, "Vote unenforceable");
        } else {
            require(_effective && now > _endTime, "Vote unenforceable");
        }
        //  Add the executable contract to the administrator list
        _voteFactory.addSuperMan(address(_implementContract));
		//将这个可运行的智能合约添加到超级用户
        //  Execute
        _implementContract.doit();
        //  Delete the authorization
        _voteFactory.deleteSuperMan(address(_implementContract));
    }
    
    /**
    * @dev check whether the vote is effective
	如果超过需求值，则有效
    */
    function ifEffective() private {
        if (_totalAmount >= _circulation) {
            _effective = true;
        }
    }
    
    /**
    * @dev Check whether the vote is over
    */
    function checkContractEffective() public view returns (bool) {
        if (_effective || now > _endTime) {
            return true;
        } 
        return false;
    }
    
    //  Check the executable implement contract address
    function checkImplementAddress() public view returns (address) {
        return _implementAddress;
    }
    
    //  Check the voting start time
    function checkCreateTime() public view returns (uint256) {
        return _createTime;
    }
    
    //  Check the voting end time
    function checkEndTime() public view returns (uint256) {
        return _endTime;
    }
    
    //  Check the current total number of votes
    function checkTotalAmount() public view returns (uint256) {
        return _totalAmount;
    }
    
    //  Check the number of votes to pass
    function checkCirculation() public view returns (uint256) {
        return _circulation;
    }
    
    //  Check the number of personal votes
    function checkPersonalAmount(address user) public view returns (uint256) {
        return _personalAmount[user];
    }
    
    //  Check the destroyed NEST
    function checkDestroyedNest() public view returns (uint256) {
        return _destroyedNest;
    }
    
    //  Check whether the contract is effective
    function checkEffective() public view returns (bool) {
        return _effective;
    }
    
    //  Check whether in emergency state
    function checkStateOfEmergency() public view returns (bool) {
        return _stateOfEmergency;
    }
    
    //  Check NestNode raising time
    function checkNNLimitTime() public view returns (uint256) {
        return _NNLimitTime;
    }
    
    //  Check the minimum number of NNs to create a vote
    function checkNNCreateLimit() public view returns (uint256) {
        return _NNCreateLimit;
    }
    
    //  Check the period number of snapshot used in the emergency state
    function checkAbonusTimes() public view returns (uint256) {
        return _abonusTimes;
    }
    
    //  Check number of personal votes
    function checkPersonalNNAmount(address user) public view returns (uint256) {
        return _personalNNAmount[address(user)];
    }
    
    //  Check the total number of NNs
    function checkAllNNAmount() public view returns (uint256) {
        return _allNNAmount;
    }
    
    //  Check whether NEST voting is available
    function checkNestVote() public view returns (bool) {
        return _nestVote;
    }
    
    //  Check whether it has been excecuted
    function checkIsChange() public view returns (bool) {
        return _isChange;
    }
    
    //  Vote Factory contract only
    modifier onlyFactory() {
        require(address(_voteFactory) == address(msg.sender), "No authority");
        _;
    }
}

//  Executable contract
interface Nest_3_Implement {
    //  Execute
    function doit() external;
}

//  NEST lock-up contract
interface Nest_3_TokenSave {
    //  Check lock-up amount
    function checkAmount(address sender, address token) external view returns (uint256);
}

//  Bonus logic contract
interface Nest_3_TokenAbonus {
    //  Check NEST circulation snapshot
    function checkTokenAllValueHistory(address token, uint256 times) external view returns (uint256);
    //  Check NEST user balance snapshot
    function checkTokenSelfHistory(address token, uint256 times, address user) external view returns (uint256);
    //  Check bonus ledger period
    function checkTimes() external view returns (uint256);
}

//  Erc20 contract
interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}