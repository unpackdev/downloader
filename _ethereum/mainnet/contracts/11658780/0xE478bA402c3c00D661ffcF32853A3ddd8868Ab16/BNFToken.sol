pragma solidity ^0.7.1;

/**
 * @title Context
 * @dev Provide context functions
 */
abstract contract Context {
    address public owner;            //Contract owner address
    bool public isContractActive;           //Make sure this contract can be used or not
    
    /**
     * Make sure the sender is the owner of contract
     */ 
    modifier onlyOwner{
        require(_msgSender() == owner, "Only owner can process");
        _;
    }
    
    /**
     * Make sure the contract is active to execute
    */ 
    modifier contractActive{
        require(isContractActive, "This contract is deactived");
        _;
    }

    /**
    * @dev Constructor
    * 
    * Implementations:
    *   1. Set the owner of contract
    *   2. Set contract is active
    */
    constructor(){
       owner = _msgSender();           //Set owner address when contract is created
       isContractActive = true;        //Contract is active when it is created
    }

    /**
     * Get sender address
     */ 
    function _msgSender() internal view returns(address){
        return msg.sender;
    }

    /**
     * Get current time in unix timestamp
     */
    function _now() internal view returns(uint){
        return block.timestamp;
    }

    /**
    * Update contract status to make sure this contract can be executed or not
     */
    function setContractStatus(bool status) external onlyOwner{
        require(isContractActive != status,"The current contract's status is the same with updating status");
        isContractActive = status;
    }

    /**
    * @dev Change contract's owner
    * @return If success return true; else return false
    * 
    * Requirements:
    *   1. Only current owner can execute
    *   2. `newOwner` is not zero address
    *   3. `newOwner` is not current owner
    * 
    * Implementations:
    *   1. Validate requirements
    *   2. Set current owner is newOwner
    *   3. Emit Events
    *   4. Return result
    */
    function setOwner(address newOwner) external onlyOwner returns(bool){
        require(newOwner != address(0), "New owner is zero address");
        require(newOwner != owner, "New owner is current owner");

        owner = newOwner;

        emit OwnerChanged(owner);
        return true;
    }

    /**
    * @dev Event that notifies contract's owner has been changed to `newOwner` 
    */
    event OwnerChanged(address newOwner);
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
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
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
    function sub(uint a, uint b) internal pure returns (uint) {
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
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

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
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
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
    function div(uint a, uint b) internal pure returns (uint) {
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
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b > 0, errorMessage);
        uint c = a / b;
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
    function mod(uint a, uint b) internal pure returns (uint) {
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
    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20Token {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    /** 
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function burn(address account, uint amount) external;

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
}

abstract contract ERC20Token is IERC20Token, Context {
    using SafeMath for uint;
    
    mapping (address => mapping (address => uint)) internal _allowances;
    mapping (address => uint) internal _balances;
    uint internal _totalSupply;
    
    string public name;
    string public symbol;
    uint public decimals;
    
    function totalSupply() external view override virtual returns (uint){
        return _totalSupply;
    }
    
    function balanceOf(address account) external override virtual view returns (uint){
        return _balances[account];
    }
    
    function transfer(address _to, uint _value) public override virtual contractActive returns(bool){
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public virtual contractActive override returns(bool) {
        return _transferFrom(sender, recipient, amount);
    }

    function approve(address spender, uint value) public virtual override returns(bool) {
        return _approve(_msgSender(), spender, value);
    }

    function allowance(address owner, address spender) public virtual view override returns (uint) {
        return _allowance(owner, spender);
    }

    function burn(address account, uint amount) external virtual override onlyOwner {
        _burn(account, amount);
    }
    
    /**
     * @dev Withdraw ERC-20 token of this contract
     */ 
    function withdrawToken(address tokenAddress) external onlyOwner contractActive{
        require(tokenAddress != address(0), "Contract address is zero address");
        require(tokenAddress != address(this), "Can not transfer self token");
        
        IERC20Token tokenContract = IERC20Token(tokenAddress);
        uint tokenBalance = tokenContract.balanceOf(address(this));
        require(tokenBalance > 0, "Balance is zero");
        
        tokenContract.transfer(owner, tokenBalance);
    }
    
    function _transfer(address sender, address recipient, uint amount) internal {
        require(amount > 0, "Transfer amount should be greater than zero");
        require(_balances[sender] >= amount);
        
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function _transferFrom(address sender, address recipient, uint amount) internal returns(bool) {
        require(_allowance(sender, _msgSender()) >= amount, "Allowance is not enough");
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowance(sender, _msgSender()).sub(amount));
        return true;
    }
    
    function _approve(address owner, address spender, uint value) internal returns (bool){
        require(value >= 0,"Approval value can not be negative");
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
        return true;
    }
    
    function _allowance(address owner, address spender) internal view returns (uint) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint amount) internal virtual returns(bool){
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);

        return true;
    }
}

interface IBNFToken{
    function createShareHolder(address account, uint amount) external returns(bool);

    /**
    * @dev Transfer BNF token from sender to recipient when sender transfers BNU token to recipient
    */
    function shareholderTransfer(address sender, address recipient, uint amount) external returns(bool);
}

contract BNFToken is ERC20Token, IBNFToken {
    using SafeMath for uint;
    
    modifier onlyTokenSaleContract{
        require(_msgSender() == _tokenSaleContractAddress, "BNFToken: Only factory contract can process");
        _;
    }
    
    address public _tokenSaleContractAddress;
    uint public _byteNextPercent;
    address public _bnfSwapContractAddress;
    address public _byteNextFundAddress;
    
    address [] _holderAddresses;

    /**
     * @dev Generate token information
    */
    constructor () {
        name = 'ByteNext Fund';
        symbol = 'BNF';
        decimals = 18;
        _totalSupply = 0;
        
        _byteNextPercent = 20;
        _byteNextFundAddress = 0x77f42723192B4e9D76f752F3404Fff46Dc535ade;
        _tokenSaleContractAddress = 0xA83D81113F57d63AF7EFDC4a12350365c7871266;
    }
    
    /**
     * @dev Set factory contract address
     */ 
    function setTokenSaleContractAddress(address contractAddress) external onlyOwner{
        _tokenSaleContractAddress = contractAddress;
    }
    
    /**
     * @dev Set BNF swap contract address
     */ 
    function setBNFSwapContractAddress(address contractAddress) external onlyOwner{
        _bnfSwapContractAddress = contractAddress;
    }
    
    /**
     * Token can not be transfered directly between holders
     */ 
    function transfer(address to, uint value) public pure override returns(bool){
        revert("The transfer function is disabled");
    }
    
    /**
     * @dev Token can only transfered between holders via swap contract
    */ 
    function transferFrom(address sender, address recipient, uint amount) public override returns(bool){
        require(_msgSender() == _bnfSwapContractAddress, "BNF token can be only transferred by BNF swap contract");
        return _transferFrom(sender, recipient, amount);
    }
    
    /**
     * @dev Create amount BNF token to account and increase totalSupply
     * 
     * Details: 
     *      When an investor purchases BNT token in seed or private round of token sale times,
     *      an new BNF token will be issued to make sure that investor's share
     *      Note that: ByteNext always takes _byteNextPercent of this funds 
     *      so that another BNF token amount will be also issued and added to ByteNext address
     * Implementations
     * 1. Make sure: This funtion can be only called from BNT token address and this contract should be active to process
     * 2. Validate account address
     * 3. Increase total supply of BNF token, issue more token and add to account address
     * 4. Add account to list of holders
     * 5. Calculate to issue token amount for ByteNext to make sure taking _byteNextPercent of this fund
     * 6. emit Event
     */ 
    function createShareHolder(address account, uint amount) external override onlyTokenSaleContract contractActive returns(bool){
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        
        if(!_isHolderExisted(account))
            _holderAddresses.push(account);
        
        _calculateByteNextBNF(amount);
        
        emit Transfer(address(0), account, amount);
        emit Issue(account, amount);
        return true;
    }
    
    /**
     * @dev Check whether holder exists or not
     */ 
    function _isHolderExisted(address account) internal view returns(bool){
        for(uint index = 0; index < _holderAddresses.length; index++){
            if(_holderAddresses[index] == account)
                return true;
        }
        return false;
    }
    
    /**
     * @dev Withdraw share
     * When an investors makes a withdrawal request, their BNF will be converted to ETH
     * Investors will pay token to take ETH
     * 
     * Implementations 
     * 1. Validate amount should be greater than or equals sender balance
     * 2. Calculate percentage of share holder to calculate ETH to pay
     * 3. Reduce sender token balance and token supply balance
     * 4. emit Event
     */
    function withdrawShare(uint amount) external returns(bool){
        address payable sender = payable(_msgSender());
        uint tokenBalance = _balances[sender];
        require(tokenBalance >= amount, "BNF token balance is not enough");
        
        uint ethBalance = address(this).balance;
        require(ethBalance > 0, "This fund has had no profit yet");
        
        _totalSupply = _totalSupply.sub(amount);
        _balances[sender] = _balances[sender].sub(amount);

        uint ethReceive = amount.mul(ethBalance).div(_totalSupply);
        sender.transfer(ethReceive);
        
        emit WithdrawShare(sender, amount);
        return true;
    }
    
    /**
     *@dev withdraw all ETH of this contract
     *
     * When all investors withdrawed 100% share,
     * the owner of contract can withdarw all ETH of this contract if ETH is transfered
     * 
     */ 
    function withdrawETH() external onlyOwner{
        require(_totalSupply == 0,"Can only withdraw all ETH when contract has no shareholder");
        uint balance = address(this).balance;
        require(balance > 0, "Balance is zero");
        
        msg.sender.transfer(balance);
        emit WithdrawETH(_msgSender(), balance);
    }
    
    /**
     * @dev 
     *      Pay profit for all shareholders base on shareholders' percentage and ETH balance percentage
     *      This function can be called any time
     * 
     * Implements
     * MAKE SURE: This function can be only called by contract's owner
     * 1. Validate ETH balance
     * 2. Calculate ETH to payProfit
     * 3. Calculate and pay annual profit for shareholders
     * 4. emit Event
     */ 
    function payAnnualProfit(uint percentage) external onlyOwner contractActive{
        require(percentage > 0 && percentage < 100, "Percentage should be greater than zero and less than 100");
        uint ethBalance = address(this).balance;
        require(ethBalance > 0, "Balance is zero");
        
        require(_holderAddresses.length > 0, "No shareholder found");
        
        uint totalEthToPay = ethBalance.mul(100).div(percentage);
        for(uint index = 0; index < _holderAddresses.length; index++){
            address holderAddress = _holderAddresses[index];
            uint ethToPay = _balances[holderAddress].mul(totalEthToPay).div(_totalSupply);
            
            payable(holderAddress).transfer(ethToPay);
        }
        
        emit PayAnnualProfit(_now());
    }

    /**
    * @dev Transfer BNF token from sender to recipient when sender transfers BNU token to recipient
    *
    * Implementations:
    *   1. Add recipent to shareholder list if does not exists
    *   2. Transfer `amount` BNF token from `sender` to `recipient`
    */
    function shareholderTransfer(address sender, address recipient, uint amount) external override onlyTokenSaleContract contractActive returns(bool){
        if(!_isHolderExisted(recipient))
            _holderAddresses.push(recipient);
        _transfer(sender, recipient, amount);
        return true;
    }
    
    /**
     * @dev Calculate ByteNext BNF amount when BNF token minted
     */
    function _calculateByteNextBNF(uint investAmount) internal{
        uint investorPercent = uint(100).sub(_byteNextPercent);
        
        //Calculate token to minted for ByteNext to remain _byteNextPercent%;
        uint amountToMint = investAmount.mul(_byteNextPercent).div(investorPercent);
        
        //Total supply
        _totalSupply = _totalSupply.add(amountToMint);
        _balances[_byteNextFundAddress] = _balances[_byteNextFundAddress].add(amountToMint);
        
        if(!_isHolderExisted(_byteNextFundAddress))
            _holderAddresses.push(_byteNextFundAddress);
        
        emit Issue(_byteNextFundAddress, amountToMint);
        emit Transfer(address(0), _byteNextFundAddress, amountToMint);
    }

    /**
    * @dev Enable to receive ETH
     */
    receive () external payable{}

    event Issue(address account, uint amount);
    event WithdrawShare(address account, uint amount);
    event WithdrawETH(address account, uint amount);
    event PayAnnualProfit(uint time);
}

//SPDX-License-Identifier: MIT