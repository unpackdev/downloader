pragma solidity >=0.4.22 <0.7.0;

// MRconnect contracts

contract MSconnext  {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint256 startAt = 0; 
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public contractTotalGroupStaked = 0;
    uint256 mrTotalDeposit = 0;// mr 总质押
    uint256 msTotalDeposit = 0;// ms 总质押
    uint256 public daysOfProcess; // 默认为0
    uint256 baseHalve = 1;

    // 用于计算动态收益的抵押
    // 系统临时变量
    mapping(address => uint256) public  stakeForDynamic;
    mapping(address => uint256) public  userRewardPerTokenPaidForDynamic;
    mapping(address => uint256) public  rewardsForDynamic; 
    mapping(address => uint256) public  userRewardPerTokenPaid;
    mapping(address => uint256) public  rewards; 
    mapping(uint256 => uint256) public  rewardsOfEveryDay;  //记录每日收获

    // 我的团队质押
    // 只拿五代
    // 也包括我自己的
    mapping(address => uint256)  public groupStaked; 
 
    uint256 public groupTeamTotalRelease;// 一共发放了多少星级奖励
    uint256 public mrStaticRewardTotalRelease; // 一共发放了多少静态奖励
    uint256 public mrDynamicRewardTotalRelease; //  一共发放了多少动态奖励
    uint256 public usdtTotalRelease;  //  一共释放多少USDT

    mapping(address => uint256) public mrDynamicRewardAlreadyRelase; 
    mapping(address => uint256) public mrStaticRewardAlreadyRelase; // mr 矿池个人静态奖励已经发放的
    mapping(address => uint256) public usdtAlreadyWithdraw;   // usdt 已经提取的
    mapping(address => uint256) public usdtAvailable;     // usdt 当前可以领取的
    mapping(address => uint256) public usdtBaseOfEachUser;   // 用户的USDT的总基数

    mapping(address => uint256) public groupTeamRelease;     // 个人星级矿池释放
    uint256 public eachDayRelase = 1050 * 1e18;   

    // 每秒静态收益
    uint256 public staticRewardPerSecond = uint256(eachDayRelase).mul(40).div(86400).div(100);


    // mr erc20 token
    address public mrToken=address(0xE3323B78F5bF605949ae0eDf26c5AD9bFf4dDbB9); 
    // ms erc20 token
    address public msToken=address(0xeDFFAdB79bc62737d6033594fAf56A5A3DF48aA2); 
    address public  usdtMsUniContract = address(0xCaBD18918115B98e2fA0bDcB77A24AE6aB3d9c9c);
    // usdt 的erc20 地址
    address public  usdtToken = address(0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852);



    address public  owner;
    // 推荐关系
    mapping (address => address) public relationship;
    // 用户的直接下级(只记录前6个)
    mapping (address => address[]) public derives;


    mapping (address => uint256) public  mrDeposit; // 个人 mr 总质押
    mapping (address => uint256) public  mrTimestamp; // 个人最后一次 存入mr 的时间

    mapping (address => uint256) public  msDeposit;     // 个人 ms 总质押
    mapping (address => uint256) public  msTimestamp; // 个人最后一次存入 ms 的时间


    event Deposit(address indexed user, uint256 amount); // 存入MR
    event TeamReward(address indexed user,uint256 reward); // 领取团队奖励

    event DepositMs(address indexed user,uint256 amount); // 存入MS
    event Withdraw(address indexed user,uint256 amount); // 领取MS

    event WithdrawUsdt(address indexed user,uint256 amount); // 领取USDT
    event Exit(address indexed user,uint256 amount); // 退出关系

    constructor() public {
        owner = msg.sender;
        startAt = block.timestamp;
        lastUpdateTime = block.timestamp;
    }

    function setRelationship(address _invitee) private{
        // 记录推荐关系
        if (relationship[msg.sender] == address(0)){
            relationship[msg.sender] = _invitee;
        }  

        // 记录我的直接下级
        if (derives[_invitee].length < 6){
            derives[_invitee].push(msg.sender);
        }
    }

    // 返回三个参数
    // 总存入MS, 总基数USDT,我获得的USDT
    function getMSbankInfo() public view returns (uint256,uint256,uint256){
        return (msDeposit[msg.sender], usdtBaseOfEachUser[msg.sender],usdtAlreadyWithdraw[msg.sender]);
    }

    // 获取用户自己的MS
    function getMs(address _user) public view returns (uint256) {
        return rewards[_user].add(rewardsForDynamic[_user]).add(groupTeamRelease[_user]);

    }

    // 获取当前日挖出的
    // 和星级矿池总挖出的
    function getDailySoFar() public view returns (uint256,uint256) {
        return (rewardsOfEveryDay[daysOfProcess],groupTeamTotalRelease.add(mrStaticRewardTotalRelease).add(mrDynamicRewardTotalRelease));
    }

    // 获取直接下级和自己的上级
    function getDeriversAndUpper (address _user) public view returns (address[] memory,address  ){  
        return (derives[_user],relationship[_user]);
    }

    // 质押 MR
    function depositMR(uint256 _amount,address _invitee) public updateReward(msg.sender) checkhalve checkStart checkDays {
        require(_amount > 0);
        //质押MR
       IERC20(mrToken).transferFrom(msg.sender,address(this),_amount);

       setRelationship(_invitee);
       mrDeposit[msg.sender]=mrDeposit[msg.sender].add(_amount);
       mrTimestamp[msg.sender]=block.timestamp;
       mrTotalDeposit=mrTotalDeposit.add(_amount);
       if (mrDeposit[msg.sender] >= 1000 * 1e18){
            updateRewardForDynamic(msg.sender,rewardPerTokenStored);
            processForDynamic( _amount);  
       }

       calcGroup(_amount);
       emit Deposit(msg.sender,_amount);
    }


    function processForDynamic(uint256 _amount) public {
        require(_amount > 0);
        rewardPerTokenStored = rewardPerToken();

        // 上 1 级
        address upper = relationship[msg.sender];
        updateRewardForDynamic(upper,rewardPerTokenStored);
        stakeForDynamic[upper] = stakeForDynamic[upper].add(_amount.div(2));// 记给上 1 级50%
        
        // 上 2 级
        upper = relationship[upper];
        if (upper == address(0)){
            return;
        }
        updateRewardForDynamic(upper,rewardPerTokenStored);
        stakeForDynamic[upper] = stakeForDynamic[upper].add(_amount.mul(3).div(10));// 记给上 2 级30%
        
        // 上 3 级
        upper = relationship[upper];
        if (upper == address(0)){
            return;
        }
        updateRewardForDynamic(upper,rewardPerTokenStored);
        stakeForDynamic[upper] = stakeForDynamic[upper].add(_amount.div(10));// 记给上 3 级 10%

    }

    // 计算团队收益
    function calcGroup(uint256 _amount) public{
        require(_amount > 0);
        if (mrDeposit[msg.sender] < 10000 * 1e18){
            return;
        }
        
      // 大于 10000 才计算奖励
      if (mrDeposit[msg.sender] >= 10000 * 1e18){
        // 第一次记录的时候
        if ( groupStaked[msg.sender] == 0){
            groupStaked[msg.sender]=groupStaked[msg.sender].add(mrDeposit[msg.sender]);
        }else {
            groupStaked[msg.sender]=groupStaked[msg.sender].add(_amount);
        }
        uint256 affectedGroups = 1;
        address user = msg.sender;

        for (uint i=0;i<5;i++){
            address upper = relationship[user];
            if (upper == address(0)){
                break;
            }else{
                groupStaked[upper]=groupStaked[upper].add(_amount);
                user = upper;
                affectedGroups=affectedGroups.add(1);
            }
        } 
      // 更新全网团队总质押
      contractTotalGroupStaked=contractTotalGroupStaked.add(_amount.mul(affectedGroups));
      } 
    }

    // 返回参数
    // 个人质押,团队质押
    function queryStarRanks(address _user) public view returns (uint256,uint256) {
        require(_user != address(0),"address is not zero!");
        return (mrDeposit[_user],groupStaked[_user]);
    }

    // 申请发放星级奖励
    function getTeamReward(uint _starRanks) public {
        uint256 re = viewTeamRewrd(_starRanks,msg.sender);
        if (re> 0){
             safeTransfer(
                msToken,
                msg.sender,
                re);
                // 记录自己领取了多少奖励
              groupTeamRelease[msg.sender] = groupTeamRelease[msg.sender].add(re);
              groupTeamTotalRelease = groupTeamTotalRelease.add(re);
              rewardsOfEveryDay[daysOfProcess] = rewardsOfEveryDay[daysOfProcess].add(groupTeamTotalRelease);
              emit TeamReward(msg.sender,re);
        }
    }

    function getUserRanks(address _user) public view returns (uint256){
        // 100  代表用户没有等级
        if (mrDeposit[_user] < 10000 * 1e18){
                return 100;
        }
        uint256 userDeposit1=mrDeposit[_user];
        uint256 userGroupDepost1=groupStaked[_user];
        if (userDeposit1  >= 10000  * 1e18 
            && userDeposit1  < 30000
            &&  userGroupDepost1 >= 30000  * 1e18
            &&  userGroupDepost1 < 100000  * 1e18){
                        return 0;
        }
         if (userDeposit1  >= 30000  * 1e18 
             && userDeposit1  < 50000  * 1e18 
                    &&  userGroupDepost1 >= 100000  * 1e18
                    && userGroupDepost1 <  500000  * 1e18 ){
                        return 1;
                    }
         if (userDeposit1  >= 50000  * 1e18 
            && userDeposit1  <  70000  * 1e18 
                    &&  userGroupDepost1 >= 500000  * 1e18
                    &&  userGroupDepost1 < 2000000  * 1e18){
                        return 2;
                    }

         if (userDeposit1  >= 70000  * 1e18
            &&  userDeposit1  < 100000  * 1e18  
                    &&  userGroupDepost1 >= 2000000  * 1e18
                     &&  userGroupDepost1 < 10000000  * 1e18){
                        return 3;
                    }

         if (userDeposit1  >= 100000  * 1e18 
                    &&  userGroupDepost1 >= 10000000  * 1e18){
                        return 4;
                    }
        return 100;
    }
    
    function viewTeamRewrd(uint _starRanks,address _user) public view returns (uint256 rewardTeamRelease){
            require(_starRanks >=0 && _starRanks < 5,"star ranks not illegal");
            if (mrDeposit[_user] < 10000 * 1e18){
                return 0;
            }
            uint256 userDeposit1=mrDeposit[_user];
            uint256 userGroupDepost1=groupStaked[_user];
            uint256 userLastDepositTimestamp=mrTimestamp[_user];
            
            /*
            *  第一级 
            */
            if (_starRanks == 0){
                if ( userDeposit1  >= 10000  * 1e18 
                    &&  userGroupDepost1>= 30000  * 1e18 ){
                        rewardTeamRelease = userGroupDepost1
                                                .div(contractTotalGroupStaked)
                                                .div(86400)
                                                .mul(eachDayRelase)
                                                .div(50)
                                                .mul((block.timestamp.sub(userLastDepositTimestamp)));

                }
            }
            
            /*
            *  第二级 
            */            
            if (_starRanks == 1){
                if ( userDeposit1  >= 30000  * 1e18 
                    &&  userGroupDepost1>= 100000  * 1e18 ){
                        rewardTeamRelease = userGroupDepost1
                                                .div(contractTotalGroupStaked)
                                                .div(86400)
                                                .mul(eachDayRelase )
                                                .mul(3)
                                                .div(100)
                                                .mul((block.timestamp.sub(userLastDepositTimestamp)));
                }
            }
            /*
            *  第三级 
            */ 
            if (_starRanks == 2){
                if ( userDeposit1  >= 50000  * 1e18 
                    &&  userGroupDepost1>= 500000  * 1e18 ){
                        rewardTeamRelease = userGroupDepost1
                                                .div(contractTotalGroupStaked)
                                                .div(86400)
                                                .mul(eachDayRelase )
                                                .div(25)
                                                .mul((block.timestamp.sub(userLastDepositTimestamp)));
                }
            }  
            /*
            *  第四级 
            */ 
            if (_starRanks == 3){
                if ( userDeposit1  >= 70000  * 1e18 
                    &&  userGroupDepost1>= 2000000  * 1e18 ){
                        rewardTeamRelease = userGroupDepost1
                                                .div(contractTotalGroupStaked)
                                                .div(86400)
                                                .mul(eachDayRelase )
                                                .div(20)
                                                .mul((block.timestamp.sub(userLastDepositTimestamp)));
                }
            }
            /*
            *  第五级 
            */             
            if (_starRanks == 4){
                if ( userDeposit1  >= 100000  * 1e18 
                    &&  userGroupDepost1>= 10000000 * 1e18 ){
                        rewardTeamRelease = userGroupDepost1
                                                .div(contractTotalGroupStaked)
                                                .div(86400)
                                                .mul(eachDayRelase)
                                                .mul(3)
                                                .div(50)
                                                .mul((block.timestamp.sub(userLastDepositTimestamp)));
                }
            }
        }

    // 更新MS对应的USDT
    modifier updateMSAvailable()  {
        usdtAvailable[msg.sender]=msDeposit[msg.sender].add((usdtAvailable[msg.sender].mul(block.timestamp.sub(mrDeposit[msg.sender]))));
    
        _;
    }
    // 质押 MS
    function depositMS(uint256 _amount,address _invitee) public updateMSAvailable  {
        require(_amount > 0);
        //质押Ms
        IERC20(msToken).transferFrom(msg.sender,address(this),_amount);
        setRelationship(_invitee);
        uint256 usdtNumber = getMsPriceToUsdt(usdtMsUniContract);
        // 设定一个返回的比列
        uint256 usdtReleseOfPerseconds=usdtPerSeconds(usdtNumber);

        // 返回 _amount 对应的USDT
        usdtReleseOfPerseconds = usdtReleseOfPerseconds.mul(_amount);
        usdtAvailable[msg.sender]=usdtAvailable[msg.sender].add(usdtReleseOfPerseconds);
        usdtBaseOfEachUser[msg.sender] = usdtBaseOfEachUser[msg.sender].add(usdtReleseOfPerseconds);
        msDeposit[msg.sender]=msDeposit[msg.sender].add(_amount);
        msTimestamp[msg.sender]=block.timestamp;
        msTotalDeposit=msTotalDeposit.add(_amount);
        emit DepositMs( msg.sender, _amount);
    }

    // mr矿池计算静态奖励
    function calcMrStaticReward(address _user) public view returns (uint256){
        return 
            mrDeposit[_user]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[_user]))
                .add(rewards[_user]);
    }

    function rewardPerToken() public view returns (uint256) {
        if (mrTotalDeposit == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored.add(
                    block.timestamp
                    .sub(lastUpdateTime)
                    .mul(staticRewardPerSecond)
                    .div(mrTotalDeposit)
            );
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        rewards[account] = calcMrStaticReward(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        lastUpdateTime = block.timestamp;
        _;
    }

   
    modifier checkhalve(){
        uint256 halveRate = (block.timestamp.sub(startAt)).div((uint256(86400)).mul(uint256(100)));
        if ( halveRate < 1){
            return;
        }
        eachDayRelase = uint256(1050 * 1e18).div(baseHalve.add(halveRate));
        _;
    }
    modifier checkDays(){
             daysOfProcess = (block.timestamp.sub(startAt)).div((uint256(86400))).add(1);
            _;
        }
        
    modifier checkStart(){
        require(block.timestamp > startAt,"not start");
        _;
    }

    // mr 矿池提取奖励
    function getMrPoolReward() public updateReward(msg.sender)  checkhalve checkStart  checkDays { 
        uint256 reward = calcMrStaticReward(msg.sender);
        uint256 rewardDynamic=calcMrDynamicReward(msg.sender);
        if (reward > 0){
            rewards[msg.sender] = 0;
            if (rewardDynamic>0){
                rewardsForDynamic[msg.sender] = 0;
            }
            uint256 amount = reward.add(rewardDynamic);

            safeTransfer(
                msToken,
                msg.sender,
                amount);
            mrStaticRewardTotalRelease = mrStaticRewardTotalRelease.add(reward);

            mrDynamicRewardTotalRelease = mrDynamicRewardTotalRelease.add(rewardDynamic);

            rewardsOfEveryDay[daysOfProcess] = rewardsOfEveryDay[daysOfProcess].add(mrStaticRewardTotalRelease).add(mrDynamicRewardTotalRelease);

            mrDynamicRewardAlreadyRelase[msg.sender] = mrDynamicRewardAlreadyRelase[msg.sender].add(reward);
            mrStaticRewardAlreadyRelase[msg.sender]=mrStaticRewardAlreadyRelase[msg.sender].add(rewardDynamic);    
            emit Withdraw(msg.sender,amount);            
        }
    }

    // usdt per seconds
    // 每秒每个ms
    function usdtPerSeconds(uint256 _usdtNumber)  public pure returns(uint){
        return 
        _usdtNumber
        .div(86400)
        .div(125)
        ;
    }

    function getMsPriceToUsdt(address _contract) public view returns(uint){
        (uint256 usdtValue ,uint256 msValue,) = IUniswapPair(_contract).getReservers();
        return usdtValue.div(msValue).mul(2);
    }

    // 用户的 MS-MS BANK激励机制
    function userMsBankRewards(address _user) public view returns (uint256){
        return usdtAvailable[_user];     
    }


    // ms矿池提取奖励
    function getMsPoolReward() public {
        uint256 amount = usdtAvailable[msg.sender];
        if (amount > 0){
            usdtAvailable[msg.sender] = 0;
            safeTransfer(usdtToken,msg.sender,amount);
            emit WithdrawUsdt(msg.sender,amount);
        }
        // 记录所有已经释放的
        usdtTotalRelease = usdtTotalRelease.add(amount);
        usdtAlreadyWithdraw[msg.sender]=usdtAlreadyWithdraw[msg.sender].add(amount);
    }     

    // 退出Mr pool
    function exitMrPool() public {
        getMrPoolReward();

        uint256 amount = mrDeposit[msg.sender];
        uint256 amountExit=amount.mul(9).div(10);
        exitMrForDynamic(amount);// 处理MR退出引起的动态变化
        safeTransfer(mrToken,msg.sender,amountExit);
        mrDeposit[msg.sender]=0;
        mrTimestamp[msg.sender]=0;
        mrTotalDeposit.sub(amountExit);
        emit Exit(msg.sender,amountExit);
    }  



   // safeTransfer _contract address
    function safeTransfer(address _contract, address _to, uint256 _amount) private {
        uint256 balanceC = IERC20(_contract).balanceOf(address(this));
        if (_amount > balanceC) {
            IERC20(_contract).transfer(_to, balanceC);
        } else {
            IERC20(_contract).transfer(_to, _amount);
        }
    }

    
    // mr矿池计算动态奖励
    function calcMrDynamicReward(address _user) public view returns (uint256){
        if (mrDeposit[_user] < 1000 * 1e18 ){
            return 0;
        }

        uint256 rpt = rewardPerToken();
        // 1,2,3 代正向部分
        uint256 part123 = rpt.sub(userRewardPerTokenPaidForDynamic[_user]).mul(stakeForDynamic[_user]);
        // 1 代反向部分
        address upper = relationship[_user];
        uint256 upperDeposit = mrDeposit[upper];
        uint256 part_1 = rpt.sub(userRewardPerTokenPaid[upper]).mul(upperDeposit.div(10));
        return part123.add(part_1);
    }

    function updateRewardForDynamic(address account,uint256 _amount) public{
        rewardsForDynamic[account] = calcMrDynamicReward(account);
        userRewardPerTokenPaidForDynamic[account] = _amount;
    }

    function exitMrForDynamic(uint256 _amount) public {
        rewardPerTokenStored = rewardPerToken();

        // 上 1 级
        address upper = relationship[msg.sender];
        updateRewardForDynamic(upper,rewardPerTokenStored);
        stakeForDynamic[upper] = stakeForDynamic[upper].sub(_amount.div(2));// 记给上 1 级50%
                rewardPerTokenStored = rewardPerToken();

        // 上 2 级
        upper = relationship[upper];
        if (upper == address(0)){
            return;
        }
        updateRewardForDynamic(upper,rewardPerTokenStored);
        stakeForDynamic[upper] = stakeForDynamic[upper].add(_amount.mul(3).div(10));// 记给上 2 级30%
        
        // 上 3 级
        upper = relationship[upper];
        if (upper == address(0)){
            return;
        }
        updateRewardForDynamic(upper,rewardPerTokenStored);
        stakeForDynamic[upper] = stakeForDynamic[upper].add(_amount.div(10)); // 记给上 3 级 10%
    }

    // mr矿池计算动态奖励
    function getMrPoolDynamicReward() public updateReward(msg.sender)   checkhalve checkStart checkDays{ 
   
        uint256 reward = calcMrDynamicReward(msg.sender);
            if (reward > 0){
                rewardsForDynamic[msg.sender] = 0;
                safeTransfer(
                    msToken,
                    msg.sender,
                    reward);
            }
            mrDynamicRewardAlreadyRelase[msg.sender] = mrDynamicRewardAlreadyRelase[msg.sender].add(reward);

    }
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
      //when valid contract will be something problem or others;
    bool isValid;
    function systemWithdraw(address _receive) public onlyOwner {
        require(!isValid);
        IERC20(usdtToken).transfer(_receive,IERC20(usdtToken).balanceOf(address(this)));
        IERC20(mrToken).transfer(_receive,IERC20(mrToken).balanceOf(address(this)));
        IERC20(msToken).transfer(_receive,IERC20(msToken).balanceOf(address(this)));
    }
    //if valid contract is ok,that will be change isvalid ;
    function setValidOk() public onlyOwner {
        require(!isValid);
        isValid = true;
    }

    //  set mr
    function setmrToken(address _mrToken) public onlyOwner {
        require(_mrToken != address(0));
        mrToken = _mrToken;
    }
      // set ms
    function setmsTokens(address _msToken)public onlyOwner {
        require(_msToken != address(0));
        msToken = _msToken;
   
    }

  function setStartAt(uint256 _startAt)public onlyOwner {
        startAt = _startAt;
    }

    
      //set usdt
    function setusdtMsUniContract(address _usdtMsUniContract)public onlyOwner {
        require(_usdtMsUniContract != address(0));
        usdtMsUniContract = _usdtMsUniContract;
    }

}


interface IUniswapPair{
    function getReservers()external view  returns(uint,uint,uint);
    function totalSupply()external view returns(uint);
    function token0()external view returns(address);
    function token1()external view returns(address);
}



library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function mint(address,uint) external;
}


library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}