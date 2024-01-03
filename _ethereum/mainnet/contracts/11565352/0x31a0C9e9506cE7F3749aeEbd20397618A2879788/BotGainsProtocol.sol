pragma solidity ^0.5.0;

import "./console.sol";

import "./BotGainsProtocolStorage.sol";

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract BotGainsProtocol is Ownable,ReentrancyGuard {
    using SafeMath for uint256;
    
    BotGainsProtocolStorage private _protocol_storage;
    
    //state variables
    bool public locked = false;
    
    uint256 public cycle;
    uint256 public lossAmount;
    uint256 public users;
    
    bool public loss;
    
    uint256 private fragsPerETH;
    uint256 public timeLocked;
    uint256 public timeUnlocked;
    
    //cycle mappings
    mapping(uint256 => mapping(address => bool)) private userExistOnCycle;
    mapping(uint256 => uint256) private TOTAL_FRAGS_ON_CYCLE; //tracks total frags on a given cycle
    mapping(uint256 => uint256) private FRAGS_PER_ETH_ON_CYCLE;
    mapping(uint256 => mapping(address => uint256)) private USER_FRAGS_ON_CYCLE; //tracks capital on a given cycle
    mapping(uint256 => mapping(address => bool)) private USER_CAPITAL_USED_ON_CYCLE;
    
    mapping(uint256 => uint256) private FRAGS_PER_DIVIDEND_ON_CYCLE; //tracks a user's dividends on a cycle
    mapping(uint256 => mapping(address => bool)) private USER_DIVS_USED_ON_CYCLE;
    mapping(uint256 => bool) private DIVS_EXIST_THIS_CYCLE;
    mapping(uint256 => uint256) private TOTAL_DIVS_ON_CYCLE;
    
    mapping(uint256 => uint256) private FRAGS_PER_BONUS_ON_CYCLE; //tracks a user's bonus on a cycle
    mapping(uint256 => mapping(address => bool)) private USER_BONUS_USED_ON_CYCLE;
    mapping(uint256 => bool) private BONUS_EXIST_THIS_CYCLE;
    mapping(uint256 => uint256) private TOTAL_BONUS_ON_CYCLE;
    
    mapping(uint256 => uint256) private POOL_ON_CYCLE;
    
    modifier cycleHappend(){
        require(cycle > 0, "no cycles have occured yet");
        _;
    }
    modifier isUnlocked() {
        require(!locked, "The bot is current trading!");
        _;
    }
    modifier isNotUnlocked() {
        require(locked, "The bot is currently trading!");
        _;
    }
    modifier onlyBot() {
        require(msg.sender == _protocol_storage._tradingWallet(), "Not the trader!");
        _;
    }
    modifier onlyBonus() {
        require(msg.sender == _protocol_storage._bonusWallet(), "Not the Bonus Wallet");
        _;
    }
    
    constructor (address _storage) public {
        _protocol_storage = BotGainsProtocolStorage(_storage);
        
        //assign state variables
        cycle = 0;
        fragsPerETH = 1e30;
        FRAGS_PER_ETH_ON_CYCLE[0] = fragsPerETH;
        timeUnlocked = now;
        timeLocked=0;
        users = 0;
    }
    
    //revert payable fallback
    function() payable external {
        revert("Use userDeposit");
    }
    
    /*****************
    * USER FUNCTIONS * 
    ******************/

    //userDeposit:
    function userDeposit() public payable isUnlocked nonReentrant {
        
        require(_protocol_storage._minETH() <= msg.value, "Minimum not met");

        /*
        **** Unlocked Deposit into the current cycle
        */
        incrementUser(msg.sender);
        
        uint256 userETHamount = msg.value.mul(97750).div(1e5); //97.75%
        uint256 userFeeAmount = msg.value.mul(2000).div(1e5); //2%
        uint256 userDivFeeAmount = msg.value.mul(250).div(1e5); //.25%
        
        checkUserLimit(msg.sender, userETHamount);
        
        //update this user's balance for this investment cycle
        uint256 fragAmount = (userETHamount).mul(FRAGS_PER_ETH_ON_CYCLE[cycle]);
        USER_FRAGS_ON_CYCLE[cycle][msg.sender] = USER_FRAGS_ON_CYCLE[cycle][msg.sender].add(fragAmount);
        
        //update thier usage flag to false
        USER_CAPITAL_USED_ON_CYCLE[cycle][msg.sender] = false;
        
        //keep track of total frags on this cycle
        TOTAL_FRAGS_ON_CYCLE[cycle] = TOTAL_FRAGS_ON_CYCLE[cycle].add(fragAmount);
        
        //add liquidity to pool for this round of investment
        POOL_ON_CYCLE[cycle] = POOL_ON_CYCLE[cycle].add(userETHamount);
        
        //transfer fees
        transferToAdmin(userFeeAmount);
        transferToDivs(userDivFeeAmount);
 
    }
    //add user withdraw current capital
    function userWithdrawCurrentCapital() public payable isUnlocked{
        
        userWithdrawCapitalOnCycle(cycle);
        
        //if successful remove their capital from this pool completely
        USER_FRAGS_ON_CYCLE[cycle][msg.sender] = 0;
        
        //update users
        userExistOnCycle[cycle][msg.sender] = false;
    }
    function userReinvestCapital() public payable isUnlocked cycleHappend{
        userReinvestCapitalOnCycle(cycle-1);
    }
    
    /* Current Divs */
    function userReinvestCurrentDivs() public isUnlocked cycleHappend {
        userReinvestDivsOnCycle(cycle-1);
        
        //reset used flag for the current cycle, now that they have added back to it
        USER_CAPITAL_USED_ON_CYCLE[cycle][msg.sender] = false;
        
    }
    function userWithdrawCurrentDivs() public payable cycleHappend {
        userWithdrawDivsOnCycle(cycle-1);
    }
    
    /***
     * * BONUS WITHDRAW/REINVEST
     * */
     
    function userReinvestCurrentBonus() public isUnlocked cycleHappend {
        userReinvestBonusOnCycle(cycle-1);
    }
    
    function userWithdrawCurrentBonus() public payable cycleHappend{
        userWithdrawBonusOnCycle(cycle-1);
    }
    
    //userWithdraw:
    function userWithdrawCapitalOnCycle(uint256 _cycle) public payable nonReentrant {
        if(USER_CAPITAL_USED_ON_CYCLE[_cycle][msg.sender]){
            revert("Capital already withdraw for this cycle");
        }

        //get user frags on this cycle
        uint256 fragAmount = USER_FRAGS_ON_CYCLE[_cycle][msg.sender];
        
        //convert these frags to eth amount
        uint256 ETHamount = calculateEth(fragAmount, _cycle);
        
        //send to user
        msg.sender.transfer(ETHamount);
        
        //update their paid flag on this cycle
        USER_CAPITAL_USED_ON_CYCLE[_cycle][msg.sender] = true;
        
        if(_cycle == cycle){
            //update the pool amount 
            POOL_ON_CYCLE[_cycle] = POOL_ON_CYCLE[_cycle].sub(ETHamount);    
            
            //subtract FRAGS
            TOTAL_FRAGS_ON_CYCLE[_cycle] = TOTAL_FRAGS_ON_CYCLE[_cycle].sub(fragAmount);
            
            //update the users
            users = users.sub(1);
        }
    }
    
     function userReinvestCapitalOnCycle(uint256 _cycle) public payable isUnlocked cycleHappend nonReentrant {
        if(USER_CAPITAL_USED_ON_CYCLE[_cycle][msg.sender]){
            revert("Capital already withdraw for this cycle");
        }
        incrementUser(msg.sender);
        if(USER_FRAGS_ON_CYCLE[cycle][msg.sender].div(FRAGS_PER_ETH_ON_CYCLE[cycle]) >= _protocol_storage._maxETH()){
            revert("This user has reached the maximum limit!");
        }
        //get user frags on this cycle if they exist
        uint256 fragAmount = USER_FRAGS_ON_CYCLE[_cycle][msg.sender];
        
        //convert this amount to ETH
        uint256 ETHamount = calculateEth(fragAmount,_cycle);
        
        checkUserLimit(msg.sender, ETHamount);
        
        reinvest(msg.sender,ETHamount);
        
        
        //update their paid flag on this cycle
        USER_CAPITAL_USED_ON_CYCLE[_cycle][msg.sender] = true;
    }
    
    //userWithdrawDivs
    function userWithdrawDivsOnCycle(uint256 _cycle) public payable cycleHappend nonReentrant{
        
        if(!DIVS_EXIST_THIS_CYCLE[_cycle]) {
            revert("No dividends can be paid out for this cycle.");
        }
        
        require(DIVS_EXIST_THIS_CYCLE[_cycle], "No dividends can be paid out for this cycle.");
        
        if (USER_DIVS_USED_ON_CYCLE[_cycle][msg.sender]){
            revert("User has already used their divs on this cycle");
        }
        
        //if divs exist and divs werent used this cycle -- continue
        uint256 fragsPerDividend = FRAGS_PER_DIVIDEND_ON_CYCLE[_cycle];
        uint256 fragAmount = USER_FRAGS_ON_CYCLE[_cycle][msg.sender];
        
        uint256 totalDivToPay = fragAmount.div(fragsPerDividend);
        uint256 userDivamount = totalDivToPay.mul(80000).div(1e5); //80%
        uint256 userFeeAmount = totalDivToPay.mul(20000).div(1e5); //20%
        
        //send to the user
        msg.sender.transfer(userDivamount);
        
        //management fee
        transferToManagement(userFeeAmount);

        //update their paid flag
        USER_DIVS_USED_ON_CYCLE[_cycle][msg.sender] = true;
    }
    
    //userReinvestDividends
    function userReinvestDivsOnCycle(uint256 _cycle) public isUnlocked cycleHappend nonReentrant{
        
        if(!DIVS_EXIST_THIS_CYCLE[_cycle]) {
            revert("No dividends can be paid out for this cycle.");
        }
        require(DIVS_EXIST_THIS_CYCLE[_cycle], "No dividends can be paid out for this cycle.");
        if (USER_DIVS_USED_ON_CYCLE[_cycle][msg.sender]){
            revert("User has already used their divs on this cycle");
        }
        incrementUser(msg.sender);
        if(USER_FRAGS_ON_CYCLE[cycle][msg.sender].div(FRAGS_PER_ETH_ON_CYCLE[cycle]) >= _protocol_storage._maxETH()){
            revert("This user has reached the maximum limit!");
        }
        
        //if divs exist and divs werent used this cycle -- continue
        uint256 fragsPerDividend = FRAGS_PER_DIVIDEND_ON_CYCLE[_cycle];
        uint256 fragAmount = USER_FRAGS_ON_CYCLE[_cycle][msg.sender];
        
        uint256 totalDivToPay = fragAmount.div(fragsPerDividend);
        uint256 userDivamount = totalDivToPay.mul(98000).div(1e5); //98%
        uint256 userFeeAmount = totalDivToPay.mul(2000).div(1e5); //2%
        
        checkUserLimit(msg.sender, userDivamount);
        
        reinvest(msg.sender,userDivamount);
        
        //update their paid flag for dividend cycle theyre withdrawing from
        USER_DIVS_USED_ON_CYCLE[_cycle][msg.sender] = true;
        
        transferToAdmin(userFeeAmount);
    }
    
    
    function userWithdrawBonusOnCycle(uint256 _cycle) public payable cycleHappend nonReentrant {
        if(!BONUS_EXIST_THIS_CYCLE[_cycle]) {
            revert("No bonus can be paid out for this cycle.");
        }
        
        require(BONUS_EXIST_THIS_CYCLE[_cycle], "No bonus can be paid out for this cycle.");
        
        
        if (USER_BONUS_USED_ON_CYCLE[_cycle][msg.sender]){
            revert("User has already used their bonus on this cycle");
        }
        
        //if divs exist and divs werent used this cycle -- continue
        uint256 fragsPerBonus = FRAGS_PER_BONUS_ON_CYCLE[_cycle];
        uint256 fragAmount = USER_FRAGS_ON_CYCLE[_cycle][msg.sender];
        
        uint256 totalDivToPay = fragAmount.div(fragsPerBonus);
        uint256 userDivamount = totalDivToPay.mul(80000).div(1e5); //80%
        uint256 userFeeAmount = totalDivToPay.mul(20000).div(1e5); //20%
        
        //send to the user
        (msg.sender).transfer(userDivamount);
        
        //management fee
        transferToManagement(userFeeAmount);
        
        //update their paid flag
        USER_BONUS_USED_ON_CYCLE[_cycle][msg.sender] = true;
    }
    
    function userReinvestBonusOnCycle(uint256 _cycle) public isUnlocked cycleHappend nonReentrant{
        if(!BONUS_EXIST_THIS_CYCLE[_cycle]) {
            revert("No bonus can be paid out for this cycle.");
        }
        require(BONUS_EXIST_THIS_CYCLE[_cycle], "No bonus can be paid out for this cycle.");
        if (USER_BONUS_USED_ON_CYCLE[_cycle][msg.sender]){
            revert("User has already used their bonus on this cycle");
        }
        incrementUser(msg.sender);
        
        //if bonus exist and bonus werent used this cycle -- continue
        uint256 fragsPerBonus = FRAGS_PER_BONUS_ON_CYCLE[_cycle];
        uint256 fragAmount = USER_FRAGS_ON_CYCLE[_cycle][msg.sender];
        
        uint256 totalDivToPay = fragAmount.div(fragsPerBonus);
        uint256 bonusToPay = totalDivToPay.mul(98000).div(1e5); //98%
        uint256 userFeeAmount = totalDivToPay.mul(2000).div(1e5); //2%
        
        checkUserLimit(msg.sender, bonusToPay);
        reinvest(msg.sender,bonusToPay);
        
        //update their paid flag for dividend cycle withdrawing from
        USER_BONUS_USED_ON_CYCLE[_cycle][msg.sender] = true;
        
        //admin fee
        transferToAdmin(userFeeAmount);
    }

    /****************
    * BOT FUNCTIONS * 
    *****************/
    function BOTwithdraw() payable onlyBot external isUnlocked returns(uint256) {
        //withdraw the pool amount for this investment cycle
        uint256 poolAmount = POOL_ON_CYCLE[cycle];
        _protocol_storage._tradingWallet().transfer(poolAmount);
        
        //lock the user FUNCTIONS
        locked = true;
        timeLocked = now;
        return (poolAmount);
    }
    
    function BOTdeposit() payable onlyBot isNotUnlocked external {
        uint256 ETHamount = msg.value;
        
        if(ETHamount == 0){
            //if the eth amount here is 0 the previous cycle pool amount can NOT be 0 as well
            if(POOL_ON_CYCLE[cycle] != 0)  {
                revert("deposit and pool funds must both be zero or both be non zero");
            }
            FRAGS_PER_ETH_ON_CYCLE[cycle+1] = fragsPerETH;
            
        } else{
            //previous pool cycle CANNOT BE ZERO
            if(POOL_ON_CYCLE[cycle] == 0){
                revert("deposit and pool funds must both be zero or both be non zero");
            }
            
            if (POOL_ON_CYCLE[cycle] < ETHamount){
                
                //caluclate dividends
                uint256 dividends = ETHamount.sub(POOL_ON_CYCLE[cycle]);
                
                //update total divs for this cycle
                TOTAL_DIVS_ON_CYCLE[cycle] = dividends;
                
                //caluclate FRAGS_PER_DIVIDEND_ON_CYCLE -- 1e30 order of magnitude greater in numerator, therefore numerical instability is nil
                uint256 fragsPerDividend = TOTAL_FRAGS_ON_CYCLE[cycle].div(dividends);
                
                //update the frags per dividend on this cycle
                FRAGS_PER_DIVIDEND_ON_CYCLE[cycle] = fragsPerDividend;
                
                //dividends DO exist on this investment cycle
                DIVS_EXIST_THIS_CYCLE[cycle] = true;
                
                //update the frags per eth on this cycle
                //+1 TO ACCOUNT FOR THE NEXT CYCLE's FRAG CONVERSION
                FRAGS_PER_ETH_ON_CYCLE[cycle+1] = fragsPerETH;
                
                loss = false;
            
            } else{
                
                //calculate the lossAmount
                uint originalAmount = TOTAL_FRAGS_ON_CYCLE[cycle].div(FRAGS_PER_ETH_ON_CYCLE[cycle]);
                
                //dividends do no exist on this investment cycle
                DIVS_EXIST_THIS_CYCLE[cycle] = false;
                
                //update total divs for this cycle
                TOTAL_DIVS_ON_CYCLE[cycle] = 0;
                
                //update the fragsPerETH on this cycle -- to match this cycles total frags
                //+1 TO ACCOUNT FOR THE NEXT CYCLE's FRAG CONVERSION
                FRAGS_PER_ETH_ON_CYCLE[cycle] = TOTAL_FRAGS_ON_CYCLE[cycle].div(ETHamount);
                FRAGS_PER_ETH_ON_CYCLE[cycle+1] = fragsPerETH;
                
                uint newAmount = TOTAL_FRAGS_ON_CYCLE[cycle].div(FRAGS_PER_ETH_ON_CYCLE[cycle]);
                
                lossAmount = originalAmount.sub(newAmount);
                
                loss = true;
        }
        
        }
        
        //increment cycle
        cycle = cycle + 1;
        
        //reset users
        users = 0;
        
        //unlock
        locked = false;
        
        timeUnlocked = now;
    }
    
    
    function BonusLoyaltyDeposit() external payable isUnlocked onlyBonus {
        uint256 ETHamount = msg.value;
        if(BONUS_EXIST_THIS_CYCLE[cycle-1]){
            revert("Only one bonus deposit allowed per cycle!");
        }
        require(cycle > 0, "Cycle has not completed");
        //ALL BONUS'S ARE CALUCLATED BASED ON THE PREVIOUSLY COMPLETED CYCLE
        if (POOL_ON_CYCLE[cycle-1] < ETHamount){
            revert("Bonus amount cannot be greater than the pool amount on this cycle!");
        }
        
        if(ETHamount == 0) {
            revert("BONUS deposited must be greater than 0");
        }
            
        //update total bonus for this cycle
        TOTAL_BONUS_ON_CYCLE[cycle-1] = TOTAL_BONUS_ON_CYCLE[cycle-1].add(ETHamount);
        
        //caluclate FRAGS_PER_BONUS_ON_CYCLE -- 1e30 order of magnitude greater in numerator, therefore numerical instability is nil
        uint256 fragsPerBONUS = TOTAL_FRAGS_ON_CYCLE[cycle-1].div(TOTAL_BONUS_ON_CYCLE[cycle-1]);
        
        //update the frags per bonus on this cycle
        FRAGS_PER_BONUS_ON_CYCLE[cycle-1] = fragsPerBONUS;
        
        //Bonus's DO exist on this investment cycle
        BONUS_EXIST_THIS_CYCLE[cycle-1] = true;
        
    }
    
    /*internal utils*/
    function incrementUser(address _user) internal {
        if(!userExistOnCycle[cycle][_user]){
            userExistOnCycle[cycle][_user] = true;
            users += 1;
        }
    }
    function transferToDivs(uint256 amount) internal{
        _protocol_storage._divsFeeWallet().transfer(amount);
    }
    function transferToAdmin(uint256 amount) internal{
        _protocol_storage._adminFeeWallet().transfer(amount);   
    }
    function transferToManagement(uint256 amount) internal{
        _protocol_storage._managementFeeWallet().transfer(amount);
    }
    function checkUserLimit(address _user, uint256 amount) view internal{
        if((USER_FRAGS_ON_CYCLE[cycle][_user].div(FRAGS_PER_ETH_ON_CYCLE[cycle])).add(amount) > _protocol_storage._maxETH()){
            revert("This user has reached the maximum limit for deposits!");
        }
        if(POOL_ON_CYCLE[cycle].add(amount) > _protocol_storage._maxPoolSize()){
            revert("Maximum amount of ETH reached");
        }
    }
    function calculateEth(uint256 fragAmount, uint256 _cycle) internal view returns(uint256){
        return fragAmount.div(FRAGS_PER_ETH_ON_CYCLE[_cycle]);    
    }
    function reinvest(address _user, uint256 ETHamount) internal{
        //add to current pool for next investment cycle
        POOL_ON_CYCLE[cycle] = POOL_ON_CYCLE[cycle].add(ETHamount);
        
        //caluclate new fragamount based on the frags per eth on the current cycle
        uint256 newFragAmount = ETHamount.mul(FRAGS_PER_ETH_ON_CYCLE[cycle]);
        
        //keep track of total frags on this cycle
        TOTAL_FRAGS_ON_CYCLE[cycle] = TOTAL_FRAGS_ON_CYCLE[cycle].add(newFragAmount);
        
        //update the users balance for the current investment cycle
        USER_FRAGS_ON_CYCLE[cycle][_user] = USER_FRAGS_ON_CYCLE[cycle][_user].add(newFragAmount);
    }
    
    
    /***********************
    * ADMIN UTIL FUNCTIONS * 
    ************************/
    
    /***********************
    * PUBLIC UTIL FUNCTIONS * 
    ************************/
    
    /*DIVIDENDS*/
    function viewDividendsOnCycle(uint256 _cycle) external view returns(uint256){
        return TOTAL_DIVS_ON_CYCLE[_cycle];
    }
    function viewDividendsEarned(uint256 _cycle, address _user) external view returns (uint256){
        if(!DIVS_EXIST_THIS_CYCLE[_cycle]){
            return 0;
        }
        uint256 fragsPerDiv = FRAGS_PER_DIVIDEND_ON_CYCLE[_cycle];
        uint256 frags = USER_FRAGS_ON_CYCLE[_cycle][_user];
        return frags.div(fragsPerDiv);
    }
    function viewDividendsAvailable(uint256 _cycle, address _user) external view returns(uint256) {
        if(!DIVS_EXIST_THIS_CYCLE[_cycle]){
            return 0;
        }
        if(USER_DIVS_USED_ON_CYCLE[_cycle][_user]){
            return 0;
        }
        uint256 fragsPerDiv = FRAGS_PER_DIVIDEND_ON_CYCLE[_cycle];
        uint256 frags = USER_FRAGS_ON_CYCLE[_cycle][_user];
        return frags.div(fragsPerDiv);
    }
    
    /*BONUS*/
    function viewBonusOnCycle(uint256 _cycle) external view returns(uint256){
        return TOTAL_BONUS_ON_CYCLE[_cycle];
    }
    function viewBonusEarned(uint256 _cycle, address _user) external view returns (uint256){
        if(!BONUS_EXIST_THIS_CYCLE[_cycle]){
            return 0;
        }
        uint256 fragsPerDiv = FRAGS_PER_BONUS_ON_CYCLE[_cycle];
        uint256 frags = USER_FRAGS_ON_CYCLE[_cycle][_user];
        return frags.div(fragsPerDiv);
    }
    function viewBonusAvailable(uint256 _cycle, address _user) external view returns(uint256) {
        if(!BONUS_EXIST_THIS_CYCLE[_cycle]){
            return 0;
        }
        if(USER_BONUS_USED_ON_CYCLE[_cycle][_user]){
            return 0;
        }
        uint256 fragsPerDiv = FRAGS_PER_BONUS_ON_CYCLE[_cycle];
        uint256 frags = USER_FRAGS_ON_CYCLE[_cycle][_user];
        return frags.div(fragsPerDiv);
    }
    
    function viewCapitalAvailable(uint256 _cycle, address _user) external view returns(uint256) {
        if(USER_CAPITAL_USED_ON_CYCLE[_cycle][_user]){
            return 0;
        }
        uint256 _userFrags = USER_FRAGS_ON_CYCLE[_cycle][_user];
        if(_userFrags == 0){
            return 0;
        }
        uint256 _fragsPerETH = FRAGS_PER_ETH_ON_CYCLE[_cycle];
        return _userFrags.div(_fragsPerETH);
        
    }
    function viewCurrentlyInvested(address _user) external view returns(uint256) {
        if(USER_FRAGS_ON_CYCLE[cycle][_user] == 0){
            return 0;
        }
        if(USER_CAPITAL_USED_ON_CYCLE[cycle][_user]){
            return 0;
        }
        return USER_FRAGS_ON_CYCLE[cycle][_user].div(FRAGS_PER_ETH_ON_CYCLE[cycle]);
    }
    
    function viewPool(uint256 _cycle) external view returns(uint256){
        return POOL_ON_CYCLE[_cycle];
    }
}
    