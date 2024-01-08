// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./AccessControlEnumerable.sol";

interface IStrategy{
    function withdrawAll() external;
    function withdrawMDXReward() external;
    function contain(address) external  view returns (bool);
    function paused() external  view returns (bool);
    function want() external  view returns (address[] memory);
    function deposit() external;
    function withdraw(address _token,uint _amount) external returns (uint256); 
    function controller() external  view returns (address); 
}

interface VaultPool{
    function available(address _singleToken) external view returns (uint256); 
    function getPoolTotalDeposit(address _singleToken) external view returns (uint256 totaldeposit);
    function poolInfoExist(address _singleToken) external view returns (bool); 
    
}


contract ControllerHub is AccessControlEnumerable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address public vault;
    bool public paused;
    


    address[] public strategieList;
    mapping  (address => bool) public strategieListExist;//存在性判断，判断一个地址是不是strategieList
    mapping  (address => uint256) public strategieListNumber; //用于快速获取strategieList的序号、使用前必须判断一个地址是不是strategieList
    address[] public strategieListPrioritySort; //strategieList的优先级排序,从小到大 优先级从低到高;

    address[] public rewardToken;
    mapping  (address => bool) public rewardTokenExist;//存在性判断，判断一个地址是不rewardTokenList
    mapping  (address => uint256) public rewardTokenNumber; //用于快速获取rewardToken的序号、使用前必须判断一个token是不是rewardToken
    
    mapping  (address => mapping (uint256 => uint256))  public strategieListEarned;//  strategieListEarned[stategy][rewardTokenNumber]
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");//管理员权限
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");//紧急使用，此权限需加TimeLock或多签
    bytes32 public constant INTERFACE_ROLE = keccak256("INTERFACE_ROLE"); //交互白名单：vault/stategy等自有使用，目的是控制合约的调用权限，进一步提升安全性  
    
    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());//全部配置完成后，admin权限需加Timelock或多签
        _setupRole(GOVERNANCE_ROLE, _msgSender());
        _setupRole(WITHDRAW_ROLE, _msgSender());  


    }
    
    modifier onlyGovernance() {
        require(
            hasRole(GOVERNANCE_ROLE, _msgSender()),
            'Caller is not governance'
        );
        _;
    }
    
    modifier onlyWhiteList() {
        require(
            hasRole(INTERFACE_ROLE, _msgSender())||hasRole(GOVERNANCE_ROLE, _msgSender()),
            'Caller not have INTERFACE_ROLE'
        );
        _;
    }
    
     modifier onlyEmergencyWithdraw() {
        require(hasRole(WITHDRAW_ROLE, _msgSender()), "must have withdraw role to withdraw"); 
        _;
    }   
            
    
    function harvestSingleTokenReward(address _singleToken) onlyWhiteList public{
            require(_singleToken!=address(0),"singleToken shouldn't 0x0");
            IStrategy _strategy;
            for(uint i = 0;i < strategieList.length; i++){
                if(strategieList[i] == address(0) ){
                    continue;
                }
                _strategy = IStrategy(strategieList[i]);
                 //策略包含指定token
                if(!_strategy.contain(_singleToken)){
                    continue;
                }
                
                //策略停止使用
                if(_strategy.paused()) {
                    continue;
                }
                _strategy.withdrawMDXReward();
            }        
    }
    
	//stategy使用 回调   
    function CollectMdxBlockReward(uint256 _amount, address _rewardToken) public onlyWhiteList  {
        require(rewardTokenExist[_rewardToken],"no this reward token");
        IERC20(_rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
        strategieListEarned[msg.sender][rewardTokenNumbers(_rewardToken)]+=_amount;
        
    }
    
    //返回的_rewardTokens数量数组与rewardToken地址数组相对应
    function getSingleTokenReward(address _singleToken) public view returns(uint256[] memory _rewardTokens){
        require(_singleToken!=address(0),"singleToken shouldn't 0x0");
        
        IStrategy _strategy;
        
        _rewardTokens=new uint256[](rewardToken.length);
        for(uint i=0; i<strategieList.length; i++){
            if(strategieList[i] == address(0) ){
                    continue;
            }
           _strategy = IStrategy(strategieList[i]);            
            //策略包含指定token
            if(!_strategy.contain(_singleToken)) {
                continue;
            }
            
            
            address[] memory tokenStrategyNeed= _strategy.want();
            for(uint ii=0; ii<rewardToken.length; ii++){
                _rewardTokens[ii] +=  strategieListEarned[strategieList[i]][ii]/tokenStrategyNeed.length;//多个单币均分奖励代币
            }
        }
    }
    

    
    function setVault(address _vault)external onlyGovernance{
		require(vault==address(0));
        vault=_vault;
        _setupRole(INTERFACE_ROLE, _vault); //交互白名单
    }


    
    function addRewardToken(address _rewardToken) public onlyGovernance{//关键参数，禁止edit，只增
        require(!rewardTokenExist[_rewardToken],"this rewardToken have added");
        require(rewardToken.length<10,"to many rewardToken");
        rewardTokenExist[_rewardToken]=true;
        rewardTokenNumber[_rewardToken]=rewardToken.length;
        rewardToken.push(_rewardToken);
    }
    
    //paused仅限制了earn()
    function setPaused(bool _paused)external onlyGovernance{
        paused=_paused;
    }
    
    function addStrategieList(address _strategy)external onlyGovernance{//关键参数，禁止edit，只增
        require(!strategieListExist[_strategy],"this strategy have added");
        IStrategy strategy;
        strategy = IStrategy(_strategy); 
        
        //校验策略是否正确
        require(strategy.controller()==address(this),"this strategy illegal");          
        
        //校验策略需要的币是否都上架了
        address[] memory tokenStrategyNeed = strategy.want();
        for(uint ii=0;ii<tokenStrategyNeed.length;ii++){
            require(VaultPool(vault).poolInfoExist(tokenStrategyNeed[ii]));

        }
        
        //校验策略是否有所需接口
        require(!strategy.paused());
        require(strategy.contain(tokenStrategyNeed[0]));        
        
        strategieListExist[_strategy]=true;
        strategieListNumber[_strategy]=strategieList.length;
        strategieList.push(_strategy);
        strategieListPrioritySort.push(_strategy);//加到最后，也就是优先级最高
         _setupRole(INTERFACE_ROLE, _strategy); //交互白名单    
    }
    
    function setstrategieListPrioritySort(address[] memory prioritys) external onlyGovernance{//批量修改策略优先级
        require(strategieList.length==prioritys.length,"shortage in number");
        for(uint i =0;i< prioritys.length; i++){
            require(strategieListExist[prioritys[i]]);
        }
        strategieListPrioritySort=prioritys;
        
    }
    
    function vaults() external view returns(address){
        return(vault);
    }
    
    function rewardTokens() external view returns(address[] memory){
        return(rewardToken);
    }
    
    function rewardTokenNumbers(address _rewardToken) public view returns(uint256 _number){
        _number=rewardTokenNumber[_rewardToken];
    }    
    function strategieLists() external view returns(address[] memory){
        return(strategieList);
    }
    
    
    function earn(address _singleToken) onlyWhiteList public {
        if(paused) {
            return;
        }

        IStrategy _strategy;

        //对应币对的erc20余额
        uint balance1 = VaultPool(vault).available(_singleToken);
        if(balance1 <= 0){
             return;           
        }
        // uint balance2;
        //尝试所有策略，按照策略优先级（从大往小）（从高到低）
        require(strategieListPrioritySort.length>=1,"need at less one strategy");
        for(uint i=strategieListPrioritySort.length; true; ){
            if(i==0){
                break;
            }else{
                i-=1;
            }

            if(strategieListPrioritySort[i] == address(0)){
                continue;
            }
            
            _strategy = IStrategy(strategieListPrioritySort[i]);
            if(!_strategy.contain(_singleToken)) {
                continue;
            }
            
            //策略停止使用
            if(_strategy.paused()) {
                continue;
            }
            
            //策略希望提供的币种
            address[] memory tokenStrategyNeed= _strategy.want();
            uint256[] memory balanceStrategyNeed=new uint256[](tokenStrategyNeed.length);
            bool continueStatus;//跳出本次循环的指示标识
            
            //币种在金库中的余额
            for(uint ii=0;ii<tokenStrategyNeed.length;ii++){
                balanceStrategyNeed[ii]=VaultPool(vault).available(tokenStrategyNeed[ii]);
                if(balanceStrategyNeed[ii]==0){
                    continueStatus=true;
                    break;
                }
            }
            
            //跳出本次循环的指示标识
            if(continueStatus){
                continue;
            }
            //有资产将所有资产给到策略
            for(uint ii=0;ii<tokenStrategyNeed.length;ii++){
                IERC20(tokenStrategyNeed[ii]).safeTransferFrom(vault, strategieListPrioritySort[i], balanceStrategyNeed[ii]);
            }            
            _strategy.deposit();
            

        }
    }
    
    function govEarn(uint256 _sid) public onlyGovernance {
        require(_sid< strategieList.length, "strategy error");
        require(strategieList[_sid] != address(0),"strategy not exists");
        
        IStrategy _strategy = IStrategy(strategieList[_sid]);
        
        
            address[] memory tokenStrategyNeed= _strategy.want();
            uint256[] memory balanceStrategyNeed=new uint256[](tokenStrategyNeed.length);
            
            //币种在金库中的余额
            for(uint ii=0;ii<tokenStrategyNeed.length;ii++){
                balanceStrategyNeed[ii]=VaultPool(vault).available(tokenStrategyNeed[ii]);
                IERC20(tokenStrategyNeed[ii]).safeTransferFrom(vault, strategieList[_sid], balanceStrategyNeed[ii]);
            } 
			_strategy.deposit();

    }
	
	
    function govEarnbyStrategyAddress(address stategyAddress) public onlyGovernance {
        IStrategy _strategy = IStrategy(stategyAddress);
        
        
            address[] memory tokenStrategyNeed= _strategy.want();
            uint256[] memory balanceStrategyNeed=new uint256[](tokenStrategyNeed.length);
            
            //币种在金库中的余额
            for(uint ii=0;ii<tokenStrategyNeed.length;ii++){
                balanceStrategyNeed[ii]=VaultPool(vault).available(tokenStrategyNeed[ii]);
                IERC20(tokenStrategyNeed[ii]).safeTransferFrom(vault, stategyAddress, balanceStrategyNeed[ii]);
            } 
			_strategy.deposit();

    }	
    
    function withdrawAll(address _singleToken) public onlyGovernance{ 
        address _strategy;
        for(uint i=0; i<strategieList.length; i++){
            _strategy = strategieList[i];
            //判断策路币对是否有此币种
            if(_strategy != address(0) && IStrategy(_strategy).contain(_singleToken)) {
                IStrategy(_strategy).withdrawAll();
            }
        }
    }
    
    function withdrawLp(address _singleToken,uint256 _amount) public onlyWhiteList {
        //require(msg.sender == vault || msg.sender == governance,"!vault");
        require(address(0) != vault,"!vault");
        require(_amount > 0,"amount error");
        require(strategieList.length > 0, "strategie is empty");
        
        IStrategy _strategy;
        //策略实际转到vault的数量
        uint r;
        
        //从低优先级策略开始释放
        for(uint i=0; i<strategieListPrioritySort.length; i++){

            if(strategieListPrioritySort[i] == address(0)) {
                continue;
            }
            
            _strategy = IStrategy(strategieListPrioritySort[i]);
            //判断策略币对是否有此币种
            if(!_strategy.contain(_singleToken)) {
                continue;
            }
            //策略停止使用 
            if(_strategy.paused()) {
                continue;
            }            
            
            r = _strategy.withdraw(_singleToken, _amount);
            if(r >= _amount){
                break;
            }
            
            _amount = _amount.sub(r);
        }
    }
    
    
    //此方法使用参考：在一个合约中完成以下动作：withdrawAll(token)、govWithdrawSingleTokenForRebalance(token,0)、earn(token)或govEarn
    function govWithdrawSingleTokenForRebalance(address _singleToken,uint256 value) public onlyGovernance{ //将合约里面超过用户存款的部分提取出来，用于对冲无常
        uint256 available=VaultPool(vault).available(_singleToken);
        uint256 totalDeposit=VaultPool(vault).getPoolTotalDeposit(_singleToken);
        if(available>totalDeposit){
            if(value==0){//0就是取全部多余的Token
                value=available-totalDeposit;
            }else if(value>available-totalDeposit){//最大可取 =available-totalDeposit
                value=available-totalDeposit;
            }
            IERC20(_singleToken).safeTransferFrom(vault,msg.sender,value);
        }        
        
    }
    
    
    function govWithdraw(uint256 _sid, address _singleToken,uint256 amount) public onlyGovernance{
        require(_sid < strategieList.length, "strategy error");
        require(strategieList[_sid] != address(0), "strategy not exists");
        require(_singleToken != address(0),"token is zero");
        
        IStrategy _strategy = IStrategy(strategieList[_sid]);
        //策略希望提供的市种
        if(_strategy.contain(_singleToken)){
            _strategy.withdraw(_singleToken, amount);
        }
    }
	
    function govWithdrawStrategyAddress(address stategyAddress, address _singleToken,uint256 amount) public onlyGovernance{
        require(_singleToken != address(0),"token is zero");
        
        IStrategy _strategy = IStrategy(stategyAddress);
        //策略希望提供的市种
        if(_strategy.contain(_singleToken)){
            _strategy.withdraw(_singleToken, amount);
        }
    }
    	
    
    //提现奖励代币 一次性全提现
    function withdrawReward(address _rewardToken,address receiver) public onlyGovernance returns (bool){
        require(rewardTokenExist[_rewardToken], "rewardToken address error");
        
        uint256 balance = IERC20(_rewardToken).balanceOf(address(this));
        
        if(balance > 0){
            require(address(0) != receiver,"address is zero");

            IERC20(_rewardToken).safeTransfer(receiver, balance);
        }

        return true;
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
            require(!rewardTokenExist[_token],"this is rewardToken!");
        }
        IERC20(_token).safeTransfer(withdrawaddress, _amount);
    }    
    

    
    
}