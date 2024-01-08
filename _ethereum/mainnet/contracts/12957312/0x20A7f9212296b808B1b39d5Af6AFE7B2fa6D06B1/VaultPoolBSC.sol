
// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./AccessControlEnumerable.sol";

interface IController{
    function earn(address _singleToken) external;
    function withdrawLp(address _singleToken,uint256 _amount) external;
    function getSingleTokenReward(address _singleToken) external view returns(uint256[] memory _rewardTokens);
    function harvestSingleTokenReward(address _singleToken) external;
    function rewardTokens() external view returns(address[] memory);
    function rewardTokenNumbers(address _rewardToken) external view returns(uint256 _number);
}


contract VaultPool is AccessControlEnumerable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    bool public paused;//白名单交互的开关
    
    //下面数组顺序是rewardTokenNumbers(_rewardToken)的顺序，统一全部预留最多10个rewardToken
    uint256[10] public govTotalProfit;
    uint256[10] public userTotalProfit;
    uint256[10] public govTotalSendProfit;
    uint256[10] public userTotalSendProfit;
    
    address public controller;
    
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");//管理员权限
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");//紧急使用，此权限需加TimeLock或多签
    bytes32 public constant INTERFACE_ROLE = keccak256("INTERFACE_ROLE"); //交互白名单：vault/stategy等自有使用，目的是控制合约的调用权限，进一步提升安全性      
    
    constructor(address _controller){
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());//全部配置完成后，admin权限需加Timelock或多签
        _setupRole(GOVERNANCE_ROLE, _msgSender());
        _setupRole(WITHDRAW_ROLE, _msgSender());  
        setController(_controller);

    }   
    
    modifier onlyGovernance() {
        require(
            hasRole(GOVERNANCE_ROLE, _msgSender()),
            'Caller is not governance'
        );
        _;
    }
    

    
    modifier onlyEmergencyWithdraw() {
        require(hasRole(WITHDRAW_ROLE, _msgSender()), "must have withdraw role to withdraw"); 
        _;
    }   
    
    modifier notPause() {
        require(paused != true,'has been paused');
        require(hasRole(INTERFACE_ROLE, _msgSender())||hasRole(GOVERNANCE_ROLE, _msgSender()),'Caller not have INTERFACE_ROLE');
        _;
    }
    
    function setPaused(bool _paused)external onlyGovernance{
        paused=_paused;
    }
    

    function setController(address _controller)internal {
        controller=_controller;
         _setupRole(INTERFACE_ROLE, _controller); //交互白名单  
    }
    
    function available(address _singleToken) external view returns (uint256){//controllerHub使用
        return(IERC20(_singleToken).balanceOf(address(this)));       
    }
    
    
    function addPoolInfo(uint256 _totalAmountLimit, uint256 _earnLowerlimit, IERC20 _singleToken)external onlyGovernance{
            require(!poolInfoExist[address(_singleToken)],"pool have added");
            poolInfoNumber[address(_singleToken)]=PoolInfonum;
            poolInfoExist[address(_singleToken)]=true;
            PoolInfo storage pool = poolInfo[PoolInfonum++];
            pool.totalAmountLimit=_totalAmountLimit;
            pool.earnLowerlimit=_earnLowerlimit;
            pool.token=_singleToken;
            pool.govshare=100;
            pool.usershare=0;
            approveCtr(address(_singleToken));

    }
    
    function getPoolInfobynum(uint256 _num) public view returns(PoolInfo memory pool){
        pool = poolInfo[_num];
    }
    

    function setPoolInfobynum(uint256 _num,uint256 _totalAmountLimit,uint256 _earnLowerlimit) external onlyGovernance {
            PoolInfo storage pool = poolInfo[_num];
            pool.totalAmountLimit=_totalAmountLimit;
            pool.earnLowerlimit=_earnLowerlimit;
            
    }
    
    function rewardTokens() public view returns(address[] memory rewardTokenArr){
        rewardTokenArr=IController(controller).rewardTokens();
        if(rewardTokenArr.length>10){
            //严禁rewardTokenArr超过10个元素，否则合约全面报错
            address[] memory rewardTokenArr1=new address[](10);
            rewardTokenArr1[0]=rewardTokenArr[0];
            rewardTokenArr1[1]=rewardTokenArr[1];
            rewardTokenArr1[2]=rewardTokenArr[2];
            rewardTokenArr1[3]=rewardTokenArr[3];
            rewardTokenArr1[4]=rewardTokenArr[4];
            rewardTokenArr1[5]=rewardTokenArr[5];
            rewardTokenArr1[6]=rewardTokenArr[6];
            rewardTokenArr1[7]=rewardTokenArr[7];
            rewardTokenArr1[8]=rewardTokenArr[8];
            rewardTokenArr1[9]=rewardTokenArr[9];
            return(rewardTokenArr1);
        }else{
            return(rewardTokenArr);
        }
    }

    function rewardTokenNumbers(address _rewardToken) public view returns(uint256){
        return(IController(controller).rewardTokenNumbers(_rewardToken));
    }

    struct PoolInfo{
         //下面数组顺序是rewardTokenNumbers(_rewardToken)的顺序
        uint256 lastRewardBlock;
        uint256[10] accMdxShare;//每个Token累计获得的MDX=accMdxPerShare+govAccMdxPerShare
        uint256 totalAmount;//总存入量
        uint256[10] profit;//总利润   不等于 accMdxShare*totalAmount，因为totalAmount是当前的总存入量；应该=getSingleTotalReward
        uint256[10] accMdxPerShare;//无效 
        uint256[10] govAccMdxPerShare;//平台收益 每个token累计获得的MDX
        uint256[10] lastRewardBlockProflt;//收益率 APY(per Token、per RewardToken)
        uint256 totalAmountLimit;//此币种在平台的存入总上限
        uint256 earnLowerlimit;//此币种投入策略的下限
        uint256 govshare;//总收益中平台的份额
        uint256 usershare;//总收益中归属用户的份额
        IERC20 token;
    }
    
    struct UserInfo{
        uint256 amount;
        uint256[10] rewardDebt;
    }
    
    mapping  (uint256 => PoolInfo) public poolInfo;
    mapping  (address => bool) public poolInfoExist;//存在性判断
    mapping  (address => uint256 )public poolInfoNumber;//快速获取poolInfo序号、使用前必须判断poolInfoExist
    uint256 public PoolInfonum;    
    
    mapping  (uint256 => mapping (address => UserInfo)) public userInfo;
 
    event Deposit(address,uint256,uint256);
    event Withdraw(address,uint256,uint256);
    event Emergencywithdraw(address,uint256,uint256);

    
    //获取单币已收获的MDX reward （整个平台某特定单币总收益）
    function getSingleTotalReward(address _singleToken) public view returns (uint256[] memory reward) {//updatePool用到
        reward=IController(controller).getSingleTokenReward(_singleToken);
    }
    
    function getPoolInfo(address _singleToken) public view returns (PoolInfo memory pool) {
        require(poolInfoExist[address(_singleToken)],"pool havn't exist");
        uint256 _num=poolInfoNumber[address(_singleToken)];
        pool=getPoolInfobynum(_num);
    }

    function getPoolNumBySingleToken(address _singleToken) public view returns (uint256 num) {
        require(poolInfoExist[address(_singleToken)],"pool havn't exist");
        num=poolInfoNumber[address(_singleToken)];
    }    
    
    function getPoolTotalDeposit(address _singleToken) public view returns (uint256 totaldeposit) {
        PoolInfo memory pool1;
        require(poolInfoExist[address(_singleToken)],"pool havn't exist");
        uint256 _num=poolInfoNumber[address(_singleToken)];
        pool1=getPoolInfobynum(_num);
        return(pool1.totalAmount);
    }


    function getPoolInfoDetail(uint256 _pid,uint256 _rewardid) public view returns (uint256 ,uint256,uint256,uint256,uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        return (pool.accMdxShare[_rewardid],pool.profit[_rewardid],pool.accMdxPerShare[_rewardid],pool.govAccMdxPerShare[_rewardid],pool.lastRewardBlockProflt[_rewardid]);
    }
    
    


    function approveCtr(address _singleToken) internal {
        uint256  max =  type(uint256).max;
        IERC20(_singleToken).approve(controller,max);
    }
    

    
    function updatePool(uint256 _pid) public notPause { 
        
        PoolInfo storage pool = poolInfo[_pid];
        
        if(pool.totalAmount<=0){
            return;            
        }
        
        if(block.number <= pool.lastRewardBlock){
            return;
        }
        
        
        //收菜，所有涉及此singleToken的策略都收
        IController(controller).harvestSingleTokenReward(address(pool.token));
        
        //singleToken目前累计的总rewardToken数量
        uint256[] memory _singleTokenTotalReward = getSingleTotalReward(address(pool.token));
        

        
        for(uint i=0; i<rewardTokens().length; i++){
            uint256 tokenTotalReward=_singleTokenTotalReward[i];
            if(tokenTotalReward <=0 ){
                continue;
            }
            
            if(pool.profit[i] >= tokenTotalReward){
                //没有生成此rewardToken的奖励
                continue;
            }
           
           
           //本次结算增量(单位：rewardTokens)
            uint256 increment = tokenTotalReward-pool.profit[i];
            //平台总收益 增量(单位：rewardTokens)
            govTotalProfit[i]+=increment;
          
            
            //accMdxShare每个Token累计获得的MDX=govAccMdxPerShare,注意放大了10的12次方！
            pool.accMdxShare[i]+=increment*1e12/pool.totalAmount;
            pool.govAccMdxPerShare[i] += increment*1e12/pool.totalAmount;   
            
            
            //收益平台APY(APR per block，单位MDX),注意放大了10的12次方
            pool.lastRewardBlockProflt[i]=increment*1e12/pool.totalAmount/(block.number-pool.lastRewardBlock);
           
            //从第0块到lastRewardBlock 累计产生的mdx收益
            pool.profit[i]=tokenTotalReward;
            
        }
        
         //最新结算收益的块高
        pool.lastRewardBlock = block.number;
    }
    
    function depositWithPid(uint256 _pid, uint256 _amount) public notPause {
        require(_amount >= 0,"deposit: not good");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if(pool.totalAmountLimit >0){
            //限制投资总量
            require(pool.totalAmountLimit >= (pool.totalAmount + _amount), "deposit amount limit");
        }
        

        //执行扣用户的single Token
        if (_amount > 0){
            uint256 beforeToken = pool.token.balanceOf(address(this));
            pool.token.safeTransferFrom(msg.sender, address(this), _amount);
            uint256 afterToken = pool.token.balanceOf(address(this));
			require(_amount == afterToken-beforeToken);            
            if(_amount > 0){
                user.amount += _amount;
                pool.totalAmount +=_amount;
            }
        }
        
        //防止闪电贷,投资改为 手动触发  

        
        emit Deposit(msg.sender, _pid, _amount);
    }
    

    
    function earn(address token) public notPause {
        PoolInfo memory pool = getPoolInfo(token);
        //授权
        approveCtr(token);
        if (IERC20(token).balanceOf(address(this)) > pool.earnLowerlimit){
            IController(controller).earn(token);
        }
    }
            
    
    function withdrawWithPid(uint256 _pid, uint256 _amount) public notPause {
        require(_amount >= 0,"withdraw: not good");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount,"withdraw:Insufficient balance");
        updatePool(_pid);
        

        //提现本金
        if(_amount >0){
            uint256 poolBalance = pool.token.balanceOf(address(this));
            if(poolBalance < _amount) {
                //当前合约余额不足，调用上游释放投资 
                IController(controller).withdrawLp(address(pool.token), _amount-poolBalance);
                poolBalance = pool.token.balanceOf(address(this));
                //上游资金不足需要对冲
                require(poolBalance >= _amount,"withdraw: ask admin for help");
            }
            
            user.amount= user.amount- _amount;
            pool.totalAmount = pool.totalAmount- _amount;
            
            pool.token.safeTransfer(msg.sender, _amount);
        }
        
        //防止闪电贷,投资改为 手动触发  
        
        emit Withdraw(msg.sender, _pid, _amount);
    }
    
    function emergencyWithdraw(uint256 _pid) public notPause  { //For User，放弃收益！！！
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        
        uint256 poolBalance = pool.token.balanceOf(address(this));
        if(poolBalance < amount){
            //当前合约余额不足,调用上游释放投资
            IController(controller).withdrawLp(address(pool.token), amount-poolBalance);
            
            poolBalance = pool.token.balanceOf(address(this));
            //上游资金不足需要对冲
            require(poolBalance >= amount,"withdraw: ask admin for help");
        }
        
        user.amount = 0;
        for(uint i=0; i<rewardTokens().length; i++){
            user.rewardDebt[i] = 0;
        }
        pool.token.safeTransfer(msg.sender, amount);
        pool.totalAmount = pool.totalAmount-amount;
        emit Emergencywithdraw(msg.sender, _pid, amount);
    }
    

    bool public afterBeta;//公测状态指示
    
    //公测结束后调用此方法，将inCaseTokensGetStuck设置成严格的安全模式。
    function setAfterBeta() public onlyEmergencyWithdraw {
        afterBeta=true;
    }

     //only used emergency   
    function inCaseTokensGetStuck(address withdrawaddress,address _token,uint _amount)  public onlyEmergencyWithdraw {
        require(withdrawaddress != address(0), "WITHDRAW-ADDRESS-REQUIRED");  
        if(afterBeta){
            require(!poolInfoExist[_token],"this is singleToken!");
        }
        IERC20(_token).safeTransfer(withdrawaddress, _amount);
    }   

    
    
    
}