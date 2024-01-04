// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

//*****************************************************************************//
//                        Coin Name : NEXON                                    //
//                           Symbol : NEX                                      //
//                     Total Supply : 10,000,000,000                           //
//                         Decimals : 18                                       //
//                    Functionality : Staking, Rewards, Burn, Mint, Claim      //
//*****************************************************************************//

 /**
 * @title SafeMath
 * @dev   Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
  /**
  * @dev Multiplies two unsigned integers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256){
    if (a == 0){
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b,"Calculation error");
    return c;
  }

  /**
  * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256){
    // Solidity only automatically asserts when dividing by 0
    require(b > 0,"Calculation error");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256){
    require(b <= a,"Calculation error");
    uint256 c = a - b;
    return c;
  }

  /**
  * @dev Adds two unsigned integers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256){
    uint256 c = a + b;
    require(c >= a,"Calculation error");
    return c;
  }

  /**
  * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256){
    require(b != 0,"Calculation error");
    return a % b;
  }
}

 /**
 * @title HexInterface 
 * @dev see https://etherscan.io/address/0x2b591e99afe9f32eaa6214f7b7629768c40eeb39#code
 */
contract IDelegate {
  function balanceOf(address) public pure returns (uint256){}
  function decimals() public pure returns (uint8){}
}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
* @title Nexon Contract For ERC20 Tokens
* @dev NEXON tokens as per ERC20 Standards
*/
contract Nexon is IERC20 {

  using SafeMath for uint256;

  address private _owner;                         // Owner of the Contract.
  string  private _name;                          // Name of the token.
  string  private _symbol;                        // symbol of the token.
  uint8   private _decimals;                      // variable to maintain decimal precision of the token.
  uint256 private _totalSupply;                   // total supply of token.
  bool    private _stopped = false;               // state variable to check fail-safe for contract.
  address private _tokenPoolAddress;              // Pool Address to manage Staking user's Token.
  uint256 private _tokenPriceETH=100;             // Set price of token with respect to ETH.
  uint256 public airdropcount = 0;                // Variable to keep track on number of airdrop
    
  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  constructor (string memory name, string memory symbol, uint8 decimals, uint256 totalSupply, address owner, address tokenPoolAddress) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
    _totalSupply = totalSupply*(10**uint256(decimals));
    _balances[owner] = _totalSupply;
    _owner = owner;
    _tokenPoolAddress = tokenPoolAddress;
  }
 
  /*
  * ----------------------------------------------------------------------------------------------------------------------------------------------
  * Functions for owner
  * ----------------------------------------------------------------------------------------------------------------------------------------------
  */

  /**
  * @dev get address of smart contract owner
  * @return address of owner
  */
  function getowner() public view returns (address) {
    return _owner;
  }

  /**
  * @dev modifier to check if the message sender is owner
  */
  modifier onlyOwner() {
    require(isOwner(),"You are not authenticate to make this transfer");
    _;
  }

  /**
   * @dev Internal function for modifier
   */
  function isOwner() internal view returns (bool) {
      return msg.sender == _owner;
  }

  /**
   * @dev Transfer ownership of the smart contract. For owner only
   * @return request status
   */
  function transferOwnership(address newOwner) public onlyOwner returns (bool){
    _owner = newOwner;
    return true;
  }
      
  /*
   * ----------------------------------------------------------------------------------------------------------------------------------------------
   * View only functions
   * ----------------------------------------------------------------------------------------------------------------------------------------------
   */
  
  /**
    * @return the name of the token.
    */
  function name() public view returns (string memory) {
    return _name;
  }

  /**
    * @return the symbol of the token.
    */
  function symbol() public view returns (string memory) {
    return _symbol;
  }

  /**
    * @return the number of decimals of the token.
    */
  function decimals() public view returns (uint8) {
    return _decimals;
  }

  /**
    * @dev Total number of tokens in existence.
    */
  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return A uint256 representing the amount owned by the passed address.
    */
  function balanceOf(address owner) public view override returns (uint256) {
    return _balances[owner];
  }

  /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowed[owner][spender];
  }

  /*
   * ----------------------------------------------------------------------------------------------------------------------------------------------
   * Transfer, allow, mint and burn functions
   * ----------------------------------------------------------------------------------------------------------------------------------------------
   */

  /*
   * @dev Transfer token to a specified address.
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   */
  function transfer(address to, uint256 value) public override returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
    * @dev Transfer tokens from one address to another.
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
  function transferFrom(address from, address to, uint256 value) public override returns (bool) {
    _transfer(from, to, value);
    _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
    return true;
  }

  /**
    * @dev Transfer token for a specified addresses.
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
  */
   function _transfer(address from, address to, uint256 value) internal {
    //require(from != address(0),"Invalid from Address");
    require(to != address(0),"Invalid to Address");
    require(value > 0, "Invalid Amount");
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public override returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Approve an address to spend another addresses' tokens.
   * @param owner The address that owns the tokens.
   * @param spender The address that will spend the tokens.
   * @param value The number of tokens that can be spent.
   */
  function _approve(address owner, address spender, uint256 value) internal {
    require(spender != address(0),"Invalid address");
    require(owner != address(0),"Invalid address");
    require(value > 0, "Invalid Amount");
    _allowed[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * @param spender The address which will spend the funds.
    * @param addedValue The amount of tokens to increase the allowance by.
    */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
    return true;
  }

  /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * @param spender The address which will spend the funds.
    * @param subtractedValue The amount of tokens to decrease the allowance by.
    */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
    return true;
  }
    
  /**
    * @dev Airdrop function to airdrop tokens. Best works upto 50 addresses in one time. Maximum limit is 200 addresses in one time.
    * @param _addresses array of address in serial order
    * @param _amount amount in serial order with respect to address array
    */
  function airdropByOwner(address[] memory _addresses, uint256[] memory _amount) public onlyOwner returns (bool){
    require(_addresses.length == _amount.length,"Invalid Array");
    uint256 count = _addresses.length;
    for (uint256 i = 0; i < count; i++){
      _transfer(msg.sender, _addresses[i], _amount[i]);
      airdropcount = airdropcount + 1;
      }
    return true;
   }

  /**
   * @dev Internal function that burns an amount of the token of a given account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != address(0),"Invalid account");
    require(value > 0, "Invalid Amount");
    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public onlyOwner {
    _burn(msg.sender, _value);
  }

  /**
    * Function to mint tokens
    * @param _value The amount of tokens to mint.
    */
  function mint(uint256 _value) public onlyOwner returns(bool){
    require(_value > 0,"The amount should be greater than 0");
    _mint(_value,msg.sender);
    return true;
  }

  function _mint(uint256 _value,address _tokenOwner) internal returns(bool){
    _balances[_tokenOwner] = _balances[_tokenOwner].add(_value);
    _totalSupply = _totalSupply.add(_value);
    emit Transfer(address(0), _tokenOwner, _value);
    return true;
  }


  /**
   * Get ETH balance from this contract
   */
  function getContractETHBalance() public view returns(uint256){
    return(address(this).balance);
  }

  /*
   * ----------------------------------------------------------------------------------------------
   * Perform Staking || Withdraw Stakes || Check stakes || Check penalty 
   * -----------------------------------------------------------------------------------------------
   */

  // Mappinng for users with id => address Staked Address
  mapping (uint256 => address) private _stakerAddress;

  // Mappinng for users with id => Tokens 
  mapping (uint256 => uint256) private _usersTokens;
  
  // Mappinng for users with id => Staking Time
  mapping (uint256 => uint256) private _stakingStartTime;

  // Mappinng for users with id => End Time
  mapping (uint256 => uint256) private _stakingEndTime;

  // Mappinng for users with id => Status
  mapping (uint256 => bool) private _TokenTransactionstatus;  

    // Mapping for users with id => isClaim or not(ie true/false)
  mapping (uint256 => bool) private _isClaim;

  // Mapping for referral address with user
  mapping (address => address) private _ReferalList;  

  // Mappinng for referral address withdraw status
  mapping (address => bool) private _ReferalStatus;
  
  // Mapping to track purchased token
  mapping(address=>uint256) private _myPurchasedTokens;
  
  // Mapping for open order ETH
  mapping(address=>uint256) private _openOrderETHAmountByAddress;
  
  // Mapping for ETH deposited by user 
  mapping(address=>uint256) private _ethDepositedByUser;
  
  // Mapping to keep track of final withdraw value of staked token
  mapping(uint256=>uint256) private _finalWithdrawlStake;
  
  // Reward Percentage
  uint256 private _rewardPercentage=10;

  // Penalty Percentage
  uint256 private _penaltyPercentage=1;
  
  // Count of no of staking
  uint256 private _stakingCount = 0;

  // BigPayDay Date
  uint256 private _bigPayDayDate = now;

  // BigPayDay Percentage
  uint256 private _bigPayDayPercentage=2;
  
  // Total ETH
  uint256 private _totalETH;

  //Mapping referral whitelisted address
  mapping(address=>bool) _referralWhitelist;
  
  // To check the user for staking || Re-enterance Guard
  modifier validatorForStaking(uint256 tokens, uint256 time){
    require( time > now && tokens > 0, "Invalid time and Amount");
    _;
  }
  
  // To check for the payable amount for purchasing the tokens
  modifier payableCheck(){
    require(msg.value > 0 ,
      "Can not buy tokens,");
    _;
  }

    /**
   * @dev modifier to check the failsafe
   */
  modifier failSafe(){
    require(_stopped == false, "Fail Safe check failed");
    _;
  }

  /*
  * ------------------------------------------------------------------------------------
  * Owner functions of get value, set value, blacklist and withdraw ETH Functionality
  * ------------------------------------------------------------------------------------
  */

  /**
   * @dev Function to secure contract from fail by toggling _stopped variable
   */
  function toggleContractActive() public onlyOwner{
    _stopped = !_stopped;
  }


  /**
   * @dev Function to set token pool address
   * @param add Address for token pool that manages supplies for stakes.
   */
  function setTokenPoolAddress(address add) public onlyOwner returns(bool){
    require(add != address(0),"Invalid Address");
    _tokenPoolAddress = add;
    return true;
  }

  /**
   * @dev Function to get Token Pool addresss
   */
  function getTokenpoolAddress() public view returns(address){
    return _tokenPoolAddress;
  }


  /**
   * @dev Function for setting rewards percentage by owner
   * @param rewardsPercentage Reward percentage
   */
  function setRewardPercentage(uint256 rewardsPercentage) public onlyOwner returns(bool){
    require(rewardsPercentage > 0, "Invalid Percentage");
    _rewardPercentage = rewardsPercentage;
    return true;
  }

  /**
   * @dev Function for getting rewards percentage by owner
   */
  function getRewardPercentage() public view returns(uint256){
    return _rewardPercentage;
  }

  /**
   * @dev Function for setting penalty percentage by owner
   * @param penaltyPercentage penalty percentage 
   */
  function setPenaltyPercentage(uint256 penaltyPercentage) public onlyOwner returns(bool){
    require(penaltyPercentage > 0, "Invalid Percentage");
    _penaltyPercentage = penaltyPercentage;
    return true;
  }

  /**
   * @dev Function for getting penalty percentage
   */
  function getPenaltyPercentage() public view returns(uint256){
    return _penaltyPercentage;
  }
  
  /**
   * @dev Function to set Referral Address
   * @param add referral pool address
   */
  
  /**
   * @dev Function to Set the price of each token for ETH purchase
   */
  function setPriceToken(uint256 tokenPriceETH) external onlyOwner returns (bool){
    require(tokenPriceETH >0,"Invalid Amount");
    _tokenPriceETH = tokenPriceETH;
    return(true);
  }
  
  /**
   * @dev Function to get price of each token for ETH purchase
   */
  function getPriceToken() public view returns(uint256) {
    return _tokenPriceETH;
  }
  
  /**
   * @dev Function to blacklist any stake
   * @param status true/false
   * @param stakingId stake id for that particular stake
   */
  function blacklistStake(bool status,uint256 stakingId) external onlyOwner returns(bool){
    _TokenTransactionstatus[stakingId] = status;
  }

  /**
   * @dev Function to withdraw Funds by owner only
   */
  function withdrawETH() external onlyOwner returns(bool){
    msg.sender.transfer(address(this).balance);
    return true;
  }
  
  /*
  * ----------------------------------------------------------------------------------------
  * Function for Big Pay Day set, get And calculate Functionality
  * ----------------------------------------------------------------------------------------
  */

  /**
   * @dev Function to set Big Pay Day
   * @param NextDay unix time for next big pay day time
   */
  function setBigPayDay(uint256 NextDay) public onlyOwner returns(bool){
    require(NextDay > now,"Invalid Day Selected");
    _bigPayDayDate = NextDay;
    return true;
  }
  
  /**
   * @dev Function to get Big Pay Day
   */
  function getBigPayDay() public view returns(uint256){
    return _bigPayDayDate;
  }

  /**
   * @dev Function to set Big Pay Day Percentage
   * @param newPercentage Big pay day reward percentage
   */
  function setBigPayDayPercentage(uint256 newPercentage) public onlyOwner returns(bool){
    require(newPercentage > 0,"Invalid Percentage Selected");
    _bigPayDayPercentage = newPercentage;
    return true;
  }
  
  /**
   * @dev Function to get Big Pay Percentage
   */
  function getBigPayDayPercentage() public view returns(uint256){
    return _bigPayDayPercentage;
  }
  
  /**
   * @dev Funtion to calculate bigPayDay reward
   * @param amount Big pay day reward percentage
   * @param endDate End date of the stake
   */
  function calculateBigPayDayReward(uint256 amount, uint256 endDate)public view returns(uint256){
    if(endDate > _bigPayDayDate){
      return (amount * _bigPayDayPercentage)/100;
    }else {
    return 0 ;
    }
  }

  /*
  * ------------------------------------------------------------------------------------------------
  * Function for purchase Token Funtionality
  * ------------------------------------------------------------------------------------------------
  */

  /**
   * @dev Function to get purchased token
   * @param add Address of user
   */
  function getMyPurchasedTokens(address add) public view returns(uint256){
    return _myPurchasedTokens[add];
  }
  
  /**
   * @dev Function to get ETH deposit amount by address
   * @param add Address of user
   */
  function getETHAmountByAddress(address add) public view returns(uint256){
    return _ethDepositedByUser[add];
  }
  

  /**
   * @dev Function to get ETH amount of open order address
   * @param add Address of user
   */
  function getOpenOrderETHAmountByAddress(address add) public view returns(uint256){
      return _openOrderETHAmountByAddress[add];
  }
  
  /**
   * @dev Function to get total ETH
   */
  function getTotalETH() public view returns(uint256){
    return _totalETH;
  }
  /**
   * @dev Function to perform purchased token
   */
  function purchaseTokens() external failSafe payable payableCheck returns(bool){
    _myPurchasedTokens[msg.sender] = _myPurchasedTokens[msg.sender] + msg.value * _tokenPriceETH;
    _openOrderETHAmountByAddress[msg.sender] = msg.value;
    _totalETH = _totalETH +msg.value;
    _ethDepositedByUser[msg.sender] = msg.value;
    return true;
  }
  
   /**
   * @dev Funtion to withdraw purchased token 
   */
  function withdrawPurchasedToken() external failSafe returns(bool){
    require(_myPurchasedTokens[msg.sender]>0,"You do not have any purchased token");
    if(_referralWhitelist[msg.sender] == true){
      _mint(_myPurchasedTokens[msg.sender].add(_myPurchasedTokens[msg.sender].div(10)), msg.sender);

      _mint(_myPurchasedTokens[msg.sender].div(5), _ReferalList[msg.sender]);
    }
    else{
       _mint(_myPurchasedTokens[msg.sender], msg.sender);
    }
    _myPurchasedTokens[msg.sender] = 0;
    _openOrderETHAmountByAddress[msg.sender] = 0;
    return true;
  }


  /*
   * -------------------------------------------------------------------------------------
   * Functions for Staking Functionlaity
   * -------------------------------------------------------------------------------------
   */

  /**
   * @dev Function to get Final Withdraw Staked value
   * @param id stake id for the stake
   */
  function getFinalWithdrawlStake(uint256 id) public view returns(uint256){
    return _finalWithdrawlStake[id];
  }

  /**
   * @dev Function to get Staking address by id
   * @param id stake id for the stake
   */
  function getStakingAddressById(uint256 id) public view returns (address){
    require(id <= _stakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _stakerAddress[id];
  }
  
  /**
   * @dev Function to get Staking Starting time by id
   * @param id stake id for the stake
   */
  function getStakingStartTimeById(uint256 id)public view returns(uint256){
    require(id <= _stakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _stakingStartTime[id];
  }
  
  /**
   * @dev Function to get Staking Ending time by id
   * @param id stake id for the stake
   */
  function getStakingEndTimeById(uint256 id)public view returns(uint256){
    require(id <= _stakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _stakingEndTime[id];
  }

  /**
   * @dev Function to get active Staking tokens by id
   * @param id stake id for the stake
   */
  function getStakingTokenById(uint256 id)public view returns(uint256){
    require(id <= _stakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _usersTokens[id];
  }
  
  /**
   * @dev Function to get Staking tokens by id
   * @param id stake id for the stake
   */
  function getActiveStakesById(uint256 id)public view returns(address){
    return _stakerAddress[id];
  }

  /**
   * @dev Function to get Token lockstatus by id
   * @param id stake id for the stake
   */
  function getTokenLockstatus(uint256 id)public view returns(bool){
    return _TokenTransactionstatus[id];
  }

    /**
   * @dev Function to get is claim flag by id
   * @param id stake id for the stake
   */
  function getIsClaimById(uint256 id)public view returns(bool){
    require(id <= _stakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _isClaim[id];
  }
   
  /**
   * @dev Function to get staking count
   */
  function getStakingCount() public view returns(uint256){
      return _stakingCount;
  }

  /**
   * @dev Function to calculate panelty for the message sender
   * @param id stake id for the stake
   */
  function getPaneltyIfWithdrawToday(uint256 id) public view returns(uint256){
    if(_stakingEndTime[id] > now){
      return (_penaltyPercentage * _usersTokens[id] * ((_stakingEndTime[id] - now)/86400))/10000;
    } else if(_stakingEndTime[id] + 2629743 < now){
      return (_penaltyPercentage * _usersTokens[id] * ((now - _stakingEndTime[id])/86400))/10000;
      } else{
      return 0;
    }
  }

  /**
   * @dev Function to get Rewards on the stake
   * @param id stake id for the stake
   */
  function getRewardsDetailsOfUserById(uint256 id) public view returns(uint256){
      uint256 bpDay = calculateBigPayDayReward(_usersTokens[id], _stakingEndTime[id]);
      if(_stakingEndTime[id] > now){
      return (((now - _stakingStartTime[id])/86400) * (_rewardPercentage) * _usersTokens[id])/1000 + bpDay;
      } else if (_stakingEndTime[id] < now){
        return (((_stakingEndTime[id] - _stakingStartTime[id])/86400) * (_rewardPercentage) * _usersTokens[id])/1000 + bpDay;
      } else{
      return 0;
    }
  }

  /**
   * @dev Function to performs staking for user tokens for a specific period of time
   * @param tokens number of tokens
   * @param time time for total staking
   */
  function performStaking(uint256 tokens, uint256 time) public failSafe 
    validatorForStaking(tokens, time) returns(bool){
    _stakingCount = _stakingCount +1 ;
    _stakerAddress[_stakingCount] = msg.sender;
    _stakingEndTime[_stakingCount] = time;
    _stakingStartTime[_stakingCount] = now;
    _usersTokens[_stakingCount] = tokens;
    _TokenTransactionstatus[_stakingCount] = false;
    _transfer(msg.sender, _tokenPoolAddress, tokens);
    return true;
  }

  /**
   * @dev Function for withdrawing staked tokens
   * @param stakingId stake id for the stake
   */
  function withdrawStakedTokens(uint256 stakingId) public failSafe returns(bool){
    require(_stakerAddress[stakingId] == msg.sender,"No staked token found on this address and ID");
    require(_TokenTransactionstatus[stakingId] != true,"Either tokens are already withdrawn or blocked by admin");
    require(balanceOf(_tokenPoolAddress) > _usersTokens[stakingId], "Pool is dry, can not perform transaction");
    uint256 paneltyAtWithdraw = 0;
    if(_isClaim[stakingId]){
      require(now>=_stakingEndTime[stakingId], "Can only be withdrawn after an year");
    } else {
      paneltyAtWithdraw = getPaneltyIfWithdrawToday(stakingId);
    }
    _TokenTransactionstatus[stakingId] = true;
    if(paneltyAtWithdraw>=getRewardsDetailsOfUserById(stakingId)){
        _finalWithdrawlStake[stakingId] = _usersTokens[stakingId];
        _transfer(_tokenPoolAddress,msg.sender,_usersTokens[stakingId]);
    
    } else {
        _finalWithdrawlStake[stakingId] = _usersTokens[stakingId]-paneltyAtWithdraw+getRewardsDetailsOfUserById(stakingId);
        _mint(getRewardsDetailsOfUserById(stakingId)-paneltyAtWithdraw,_tokenPoolAddress);
        _transfer(_tokenPoolAddress,msg.sender,_usersTokens[stakingId]-paneltyAtWithdraw+getRewardsDetailsOfUserById(stakingId));
    }
    return true;
  }

  /*
  * ------------------------------------------------------------------------------------------------------
  * Functions for Referral Functionality
  * ------------------------------------------------------------------------------------------------------
  */

  /**
   * @dev Function to get Referral History by Address
   * @param add address of the user to check referral history
   */
  function getReferralHistory(address add)public view returns(address){
    return _ReferalList[add];
  }

  /**
   * @dev Function to withdraw referral amount
   * @param add withdraw referral with respect to the referral address
   */
  function withdrawReferral(address add) external failSafe returns(bool){
    require(_ReferalList[add] != msg.sender && _ReferalStatus[msg.sender] != true 
    && add != msg.sender,"Either already withdrawn or not valid");
    _ReferalStatus[add]=true;
    _ReferalList[msg.sender]=add;
    _referralWhitelist[msg.sender] = true;
    return true;
  }

  /*----------------------------------------------------------------------------------------------------------------*
  * Function to claim token based on Hex holdings || Check token holdings || Create locked claim || Update entries *
  *----------------------------------------------------------------------------------------------------------------*/

  mapping(address=>bool)holderAddressBlockList;
  mapping(address=>uint256)whitelistAddressesForClaim;

  address public delegateContract = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;           //Contract Address for HEX token
  uint256 public totalWhitelistedAdd = 0;

  IDelegate delegate = IDelegate(delegateContract);

  /** Functions for owner for claim */

  /**
   * @dev Whitelist addresses and amount for claim-able check
   * @param _userAddressArray array of addresses which have snapshot balance
   * @param _snapshotBalance balance of whitelisted addresses
   * @return bool response for the status of execution
   */
  function whitelistaddressForClaim(address[]  calldata _userAddressArray, uint256[] calldata  _snapshotBalance) external onlyOwner returns(bool){
    require(_userAddressArray.length == _snapshotBalance.length,"Invalid Array");
    uint256 count = _userAddressArray.length;
    for (uint256 i = 0; i < count; i++){
      whitelistAddressesForClaim[_userAddressArray[i]] = _snapshotBalance[i].mul((10**uint256(delegate.decimals())));
      totalWhitelistedAdd = totalWhitelistedAdd + 1;
    }
    return true;
  }

  /**
   * @dev modifier to check the claiming address validations
   * @param _claimingAddress address of the user claiming the token with snapshot
   */
  modifier checkBlocker(address _claimingAddress, uint256 _claimableTokens){
    require(delegate.balanceOf(_claimingAddress) >= _claimableTokens, "You do not have sufficient balance for this claim");
    require(_claimableTokens >= 5*((10**uint256(delegate.decimals()))), "Claiming should be more or equal to 5");
    require(whitelistAddressesForClaim[_claimingAddress] > 0, "User do not have any claimable tokens");
    require(holderAddressBlockList[_claimingAddress]!=true,"User has already claimed tokens, Check with another address");
    require(delegate.balanceOf(_claimingAddress) >= whitelistAddressesForClaim[_claimingAddress], "Not sufficient holdings");
    _;
  }

  /** Functions for claim tokens */

  /**
   * @dev Whitelist addresses and amount for claim-able check
   * @param _amountToClaim Amount of tokens staked in the wallet
   */
  function performClaim(uint256 _amountToClaim) external failSafe checkBlocker(msg.sender,_amountToClaim) validatorForStaking(_amountToClaim, now + 31536000) returns(bool){
    //This code will perform stake of the number of token for next 1 year of 365 days
    _stakingCount = _stakingCount +1;
    _stakerAddress[_stakingCount] = msg.sender;
    _stakingEndTime[_stakingCount] = now + 31536000;
    _stakingStartTime[_stakingCount] = now;
    _usersTokens[_stakingCount] = _amountToClaim.mul((10**uint256(_decimals))).div((10**uint256(delegate.decimals())));
    _TokenTransactionstatus[_stakingCount] = false;
    _isClaim[_stakingCount] = true;
    holderAddressBlockList[msg.sender] = true;
  }

  /**
   * @dev Function to check balance for performing stake
   * @param _claimingAddress address to check balance for claimable token
   */
  function checkNowStakesBalance(address _claimingAddress) public view returns(uint256){
   return delegate.balanceOf(_claimingAddress);
  }

  /**
   * @dev Function to check snapsot balance for a specific address
   * @param _holderAddress address to check balance at the time of snapshot
   */
  function checkHoldingBalance(address _holderAddress) public view returns(uint256){
   return whitelistAddressesForClaim[_holderAddress];
  }

}