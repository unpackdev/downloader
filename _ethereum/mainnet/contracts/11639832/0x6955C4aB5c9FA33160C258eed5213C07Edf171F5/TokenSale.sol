/**
 *Submitted for verification at Etherscan.io on 2020-12-28
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.2;



/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code at:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 */
contract Ownable
{

  /**
   * @dev Error constants.
   */
  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  /**
   * @dev Current owner address.
   */
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
    public
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    public
    onlyOwner
  {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

/**
 * @dev Math operations with safety checks that throw on error. This contract is based on the
 * source code at:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol.
 */
library SafeMath
{
  /**
   * @dev List of revert message codes. Implementing dApp should handle showing the correct message.
   * Based on 0xcert framework error codes.
   */
  string constant OVERFLOW = "008001";
  string constant SUBTRAHEND_GREATER_THEN_MINUEND = "008002";
  string constant DIVISION_BY_ZERO = "008003";

  /**
   * @dev Multiplies two numbers, reverts on overflow.
   * @param _factor1 Factor number.
   * @param _factor2 Factor number.
   * @return product The product of the two factors.
   */
  function mul(
    uint256 _factor1,
    uint256 _factor2
  )
    internal
    pure
    returns (uint256 product)
  {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_factor1 == 0)
    {
      return 0;
    }

    product = _factor1 * _factor2;
    require(product / _factor1 == _factor2, OVERFLOW);
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient, reverts on division by zero.
   * @param _dividend Dividend number.
   * @param _divisor Divisor number.
   * @return quotient The quotient.
   */
  function div(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 quotient)
  {
    // Solidity automatically asserts when dividing by 0, using all gas.
    require(_divisor > 0, DIVISION_BY_ZERO);
    quotient = _dividend / _divisor;
    // assert(_dividend == _divisor * quotient + _dividend % _divisor); // There is no case in which this doesn't hold.
  }

  /**
   * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   * @param _minuend Minuend number.
   * @param _subtrahend Subtrahend number.
   * @return difference Difference.
   */
  function sub(
    uint256 _minuend,
    uint256 _subtrahend
  )
    internal
    pure
    returns (uint256 difference)
  {
    require(_subtrahend <= _minuend, SUBTRAHEND_GREATER_THEN_MINUEND);
    difference = _minuend - _subtrahend;
  }

  /**
   * @dev Adds two numbers, reverts on overflow.
   * @param _addend1 Number.
   * @param _addend2 Number.
   * @return sum Sum.
   */
  function add(
    uint256 _addend1,
    uint256 _addend2
  )
    internal
    pure
    returns (uint256 sum)
  {
    sum = _addend1 + _addend2;
    require(sum >= _addend1, OVERFLOW);
  }

  /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo), reverts when
    * dividing by zero.
    * @param _dividend Number.
    * @param _divisor Number.
    * @return remainder Remainder.
    */
  function mod(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 remainder)
  {
    require(_divisor != 0, DIVISION_BY_ZERO);
    remainder = _dividend % _divisor;
  }

}


/**
 * @dev signature of external (deployed) contract (ERC20 token)
 * only methods we will use
 */
contract ERC20Token {
 
    function totalSupply() external view returns (uint256){}
    function balanceOf(address account) external view returns (uint256){}
    function allowance(address owner, address spender) external view returns (uint256){}
    function transfer(address recipient, uint256 amount) external returns (bool){}
    function approve(address spender, uint256 amount) external returns (bool){}
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool){}
    function decimals()  external view returns (uint8){}
  
}



contract TokenSale is
  Ownable, ReentrancyGuard
{
    using SafeMath for uint256;
   
    modifier onlyPriceManager() {
      require(
          msg.sender == price_manager,
          "only price manager can call this function"
          );
          _;
    }
  
    modifier onlyOwnerOrPriceManager() {
      require(
          msg.sender == price_manager || msg.sender == owner,
          "only owner or price manager can call this function"
          );
          _;
    }
   
    ERC20Token token;
    
    /**
    * @dev some non-working address from the start to ensure owner will set correct one
    */
   
    address ERC20Contract = 0x0000000000000000000000000000000000000000;
    address price_manager = 0x0000000000000000000000000000000000000000;
    
    uint256 ref_commission = 5;
    mapping(address => uint256) private ref_balances;
    
    /**
    * @dev 10**18 for tokens with 18 digits, need to be changed accordingly (setter/getter)
    */
    uint256 adj_constant = 1000000000000000000; 
    
    //initial in wei
    uint256  sell_price = 100000000000000000; 
    
    //initial in wei
    uint256  buyout_price = 70000000000000000; 
    
    uint256 constant curve_scale = 100000; 
    uint256 price_curve = 200; // in 1/100000  i.e. 1% == 1000, 0.1% == 100
    uint256 sell_threshold = 250000000000000000;
    
    //events
    event Bought(uint256 tokens_amount, uint256 amount_wei, address wallet);
    event BoughtWithRef(uint256 tokens_amount, uint256 wei_amount, address buyer, address ref_wallet);
    event Sold(uint256 tokens_amount, uint256 amount_wei, address wallet);
    event TokensDeposited(uint256 amount, address wallet);
    event FinneyDeposited(uint256 amount, address wallet);
    event Withdrawn(uint256 amount, address wallet);
    event RefWithdrawnEther(uint256 amount, address wallet);
    event RefWithdrawnTokens(uint256 amount, address wallet);
    event TokensWithdrawn(uint256 amount, address wallet);
    event UpdateSellPrice(uint256 timestamp, uint256 new_price);
    event UpdateBuyoutPrice(uint256 timestamp, uint256 new_price);
   
    /**
    * @dev set price_manager == owner in the beginning, but could be changed by setter, below
    */
    constructor() public {
        price_manager = owner;
    }
    
    
    function setPriceManagerRight(address newPriceManager) external onlyOwner{
          price_manager = newPriceManager;
    }
      
      
    function getPriceManager() public view returns(address){
        return price_manager;
    }
    
    
    function setPriceCurve(uint256 new_curve) external onlyOwnerOrPriceManager{
          price_curve = new_curve;
    }
      
    
    function getPriceCurve() public view returns(uint256){
        return price_curve;
    }
    
    function setSellTreshold(uint256 new_treshold) external onlyOwnerOrPriceManager{
          sell_threshold = new_treshold;
    }
      
    
    function getSellTreshold() public view returns(uint256){
        return sell_threshold;
    }
    
    
    function upForecastPrice(uint256 current_price, uint256 num_tokens) public view returns(uint256) {
        uint256 change =0;
        uint256 forecast_price = current_price;
        for (uint32 i=0; i < num_tokens; i++){
             change = forecast_price.div(curve_scale).mul(price_curve);
             forecast_price = forecast_price.add(change);
        }
        return forecast_price;
    }
    
    function downForecastPrice(uint256 current_price, uint256 num_tokens) public view returns (uint256) {
        uint256 change =0;
        uint256 forecast_price = current_price;
        for (uint32 i=0; i < num_tokens; i++){
             change = forecast_price.div(curve_scale).mul(price_curve);
             forecast_price = forecast_price.sub(change);
        }
        return forecast_price;
    }
    
    function effectiveBuyAmount(uint256 current_price, uint256 num_tokens) public view returns(uint256) {
        uint256 change =0;
        uint256 forecast_price = current_price;
        uint256 total_amount = current_price;
        for (uint32 i=0; i < num_tokens-1; i++){
             change = forecast_price.div(curve_scale).mul(price_curve);
             forecast_price = forecast_price.add(change);
             total_amount += forecast_price;
        }
        return total_amount;
    }
    
    function effectiveSellAmount(uint256 current_price, uint256 num_tokens) public view returns(uint256) {
       uint256 change =0;
        uint256 forecast_price = current_price;
        uint256 total_amount = current_price;
        for (uint32 i=0; i < num_tokens-1; i++){
             change = forecast_price.div(curve_scale).mul(price_curve);
             forecast_price = forecast_price.sub(change);
             total_amount += forecast_price;
        }
        return total_amount;
    }
    
   
    
    function updatePricesBuy(uint256 num_tokens) internal {
        sell_price = upForecastPrice(sell_price, num_tokens);
        buyout_price = upForecastPrice(buyout_price, num_tokens);
        uint256 timestamp = now;
        emit UpdateSellPrice(timestamp,sell_price);
        emit UpdateBuyoutPrice(timestamp, buyout_price);
    }
    
    function updatePricesSell(uint256 num_tokens) internal {
        sell_price = downForecastPrice(sell_price, num_tokens);
        buyout_price = downForecastPrice(buyout_price, num_tokens);
        uint256 timestamp = now;
        emit UpdateSellPrice(timestamp,sell_price);
        emit UpdateBuyoutPrice(timestamp, buyout_price);
    }
    
    /**
    * @dev setter/getter for ERC20 linked to exchange (current) smartcontract
    */
    function setERC20(address newERC20Contract) external onlyOwner returns(bool){
        
        ERC20Contract = newERC20Contract;
        token = ERC20Token(ERC20Contract); 
    }
    
    
    function getERC20() external view returns(address){
        return ERC20Contract;
    }

    /**
    * @dev setter/getter for digits constant (current 10**18)
    */
    function setAdjConstant(uint256 new_adj_constant) external onlyOwner{
        adj_constant = new_adj_constant;
    }
    
    function getAdjConstant() external view returns(uint256){  
        return adj_constant;
    }
 
    /**
    * @dev setter/getter for digits constant (current 10**18)
    */
    function setRefCommission(uint256 new_ref_commission) external onlyOwner{
        ref_commission = new_ref_commission;
    }
    
    function getRefCommission() external view returns(uint256){  
        return ref_commission;
    }
 
 
    /**
    * @dev setters/getters for prices 
    */
    function setSellPrice(uint256 new_sell_price) external onlyPriceManager{
        sell_price = new_sell_price;
    }
    
    function setBuyOutPrice(uint256 new_buyout_price) external onlyPriceManager{
        buyout_price = new_buyout_price;
    }
    
    function getSellPrice() external view returns(uint256){  
        return sell_price;
    }
    
    function getBuyOutPrice() external view returns(uint256){  
        return buyout_price;
    }
    
    
    
    /**
    * @dev user buys tokens 
    * ref_wallet parameter, set 0x0 if not used
    */
    function buy(address ref_wallet, uint256 num_tokens) payable external notContract nonReentrant returns (bool) {
        uint256 amountSent = msg.value; //in wei..
        require(amountSent == effectiveBuyAmount(sell_price,num_tokens), "amount do not correspond");
        require(ref_wallet == address(0x0) || ref_wallet != msg.sender, "you cannot use ref. code for yourself");
        
         uint256 dexBalance = token.balanceOf(address(this));
        //calc number of tokens (real ones, not converted based on decimals..)
        uint256 amountTobuy = num_tokens; //tokens as user see them
       
        uint256 realAmountTobuy = amountTobuy.mul(adj_constant); //tokens adjusted to real ones
        
       
        
        require(realAmountTobuy > 0, "not enough ether to buy any feasible amount of tokens");
        require(realAmountTobuy <= dexBalance, "Not enough tokens in the reserve");
        
    
        
        try token.transfer(msg.sender, realAmountTobuy) { //ensure we revert in case of failure
            if (ref_wallet == address(0x0)){
                emit Bought(amountTobuy, amountSent, msg.sender);
            } else {
                uint256 ref_comiss = amountSent.div(100).mul(ref_commission);
                ref_balances[ref_wallet] = ref_balances[ref_wallet].add(ref_comiss);
                
                emit BoughtWithRef(amountTobuy, amountSent, msg.sender, ref_wallet);
            }
            updatePricesBuy(num_tokens);
            return true;
        } catch {
            require(false,"transfer failed");
        }
        
         //we could not get here, i.e. it is error if we here
        return false;
    }
    
    
    receive() external payable {// called when ether is send, just do not allow it
        revert();
    }
    
    
    /**
    * @dev user sells tokens
    */
    function sell(uint256 amount_tokens) external notContract nonReentrant returns(bool) {
        require(sell_price >= sell_threshold, "price should reach threshold");
        uint256 amount_wei = 0;
        require(amount_tokens > 0, "You need to sell at least some tokens");
        uint256 realAmountTokens = amount_tokens.mul(adj_constant);
        
        uint256 token_bal = token.balanceOf(msg.sender);
        require(token_bal >= realAmountTokens, "Check the token balance on your wallet");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= realAmountTokens, "Check the token allowance");
       
        
        amount_wei = effectiveSellAmount(buyout_price,amount_tokens);
        
        
        
        require(address(this).balance > amount_wei, "unsufficient funds");
        bool success = false;
       
        //ensure we revert in case of failure 
        try token.transferFrom(msg.sender, address(this), realAmountTokens) { 
            //just continue if all good..
        } catch {
            require(false,"tokens transfer failed");
            return false;
        }
        
        
        // **   msg.sender.transfer(amount_wei); .** 
       
        (success, ) = msg.sender.call.value(amount_wei)("");
        require(success, "Transfer failed.");
        // ** end **
        updatePricesSell(amount_tokens);
      
            // all done..
        emit Sold(amount_tokens, amount_wei, msg.sender);
        return true; //normal completion
       
    }


    
    /**
    * @dev returns contract balance, in wei
    */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
    * @dev returns contract tokens balance
    */
    function getContractTokensBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    /**
    * @dev use of msg.sender in view function is not security measure (it doesnt work for view functions),
    * it is used only for convinience here. And etherscan do not support it (limitation of etherscan view 
    * functions support, but web3 supports).
    */
    function checkRefBalance(address ref_wallet) external onlyOwner view returns (uint256) {
        return ref_balances[ref_wallet];
    }
    
    function setRefBalance(address ref_wallet, uint256 balance) external onlyOwner{
         ref_balances[ref_wallet] = balance;
    }
    
    /**
    * @dev use of msg.sender in view function is not security measure (it doesnt work for view functions),
    * it is used only for convinience here. And etherscan do not support it (limitation of etherscan view 
    * functions support, but web3 supports).
    */
    function checkOwnRefBalance() external view returns (uint256) {
        return ref_balances[msg.sender];
    }
    
    /**
    * @dev - ref. withdraw ether
    */
    function ref_withdraw_ether() external notContract nonReentrant  {
        require(ref_balances[msg.sender] >0,"no balance");
       
        uint256 amount = ref_balances[msg.sender]; //ether
        
        require(address(this).balance >= amount, "unsufficient funds");
       
        bool success = false;
        // ** sendTo.transfer(amount);** 
        (success, ) = (payable(msg.sender)).call.value(amount)("");
        require(success, "Transfer failed.");
        ref_balances[msg.sender] = 0;
        // ** end **
        emit RefWithdrawnEther(amount, msg.sender); //wei
    }
    
     /**
    * @dev - ref. withdraw ether
    */
    function ref_withdraw_tokens() external notContract nonReentrant  {
        require(ref_balances[msg.sender] >0,"no balance");
       
        uint256 amount = ref_balances[msg.sender];//wei
        
        
        uint256 dexBalance = token.balanceOf(address(this));
        //calc number of tokens (real ones, not converted based on decimals..)
        
        //to ensure that divider is smaller
        amount = amount.mul(100000);
        
        uint256 amount_tokens = amount.div(sell_price); //tokens as user see them
       
        uint256 real_amount_tokens = amount_tokens.mul(adj_constant); //tokens adjusted to real ones
        
        //convert back
        real_amount_tokens = real_amount_tokens.div(100000);
        
        require(real_amount_tokens > 0, "not enough balance to buy any feasible amount of tokens");
        require(real_amount_tokens <= dexBalance, "Not enough tokens in the reserve");
        
    
        try token.transfer(msg.sender, real_amount_tokens) { //ensure we revert in case of failure
            ref_balances[msg.sender] = 0;
            emit RefWithdrawnTokens(real_amount_tokens, msg.sender); //wei
        } catch {
            require(false,"transfer failed");
        }

    }
    
    /**
    * @dev - four functions below are for owner to 
    * deposit/withdraw eth/tokens to exchange contract
    */
    function withdraw(address payable sendTo, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "unsufficient funds");
        bool success = false;
        // ** sendTo.transfer(amount);** 
        (success, ) = sendTo.call.value(amount)("");
        require(success, "Transfer failed.");
        // ** end **
        emit Withdrawn(amount, sendTo); //wei
    }
  
    
    function deposit(uint256 amount) payable external onlyOwner { //amount in finney
        require(amount*(1 finney) == msg.value,"please provide value in finney");
        emit FinneyDeposited(amount, owner); //in finney
    }

    function depositTokens(uint256 amount) external onlyOwner {
        require(amount > 0, "You need to deposit at least some tokens");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amount);
        
        emit TokensDeposited(amount.div(adj_constant), owner);
    }
    
  
    function withdrawTokens(address to_wallet, uint256 amount_tokens) external onlyOwner{
        require(amount_tokens > 0, "You need to withdraw at least some tokens");
        uint256 realAmountTokens = amount_tokens.mul(adj_constant);
        uint256 contractTokenBalance = token.balanceOf(address(this));
        
        require(contractTokenBalance >= realAmountTokens, "unsufficient funds");
      
       
        
        //ensure we revert in case of failure 
        try token.transfer(to_wallet, realAmountTokens) { 
            //just continue if all good..
        } catch {
            require(false,"tokens transfer failed");
           
        }
        
    
        // all done..
        emit TokensWithdrawn(amount_tokens, to_wallet);
    }
    
    
    /**
    * @dev service function to check tokens on wallet and allowance of wallet
    */
    function walletTokenBalance(address wallet) external view returns(uint256){
        return token.balanceOf(wallet);
    }
    
    /**
    * @dev service function to check allowance of wallet for tokens
    */
    function walletTokenAllowance(address wallet) external view returns (uint256){
        return  token.allowance(wallet, address(this)); 
    }
    
    
    /**
    * @dev not bullet-proof check, but additional measure, not to allow buy & sell from contracts
    */
    function isContract(address _addr) internal view returns (bool){
      uint32 size;
      assembly {
          size := extcodesize(_addr)
      }
      
      return (size > 0);
    }
    
    modifier notContract(){
      require(
          (!isContract(msg.sender)),
          "external contracts are not allowed"
          );
          _;
    }
    
    //*** fire exit ***
    function kill(address payable killAddress) external onlyOwner
    {
        uint256 contractTokenBalance = token.balanceOf(address(this));
        token.transfer(killAddress, contractTokenBalance);
        selfdestruct(killAddress);
    }
}