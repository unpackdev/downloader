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

abstract contract BaseContractData is Context{
    address internal _tokenSaleContractAddress;

    /**
    @dev Make sure function can be called only be _tokenSaleContractAddress
     */
    modifier onlyTokenSaleContract{
        require(_tokenSaleContractAddress != address(0), "Token sale contract address has not been initialized yet");
        require(_msgSender() == _tokenSaleContractAddress, "Only token sale contract can process this");
        _;
    }

    /**
    @dev Set _tokenSaleContractAddress
    */
    function setTokenSaleContractAddress(address contractAddress) external onlyOwner{
        _setTokenSaleContractAddress(contractAddress);
    }

    function _setTokenSaleContractAddress(address contractAddress) internal virtual{
        _tokenSaleContractAddress = contractAddress;
    }
}

/**
@title Share token sale data
@dev Stores all data of seed and private round
 */
contract ShareTokenSaleBalanceData is BaseContractData{
    using SafeMath for uint;

    address public _transferContractAddress;
    modifier onlyTransferContract{
        require(_transferContractAddress != address(0), "Transfer contract address has not been initialized yet");
        require(_msgSender() == _transferContractAddress,"Only transfer contract can execute");
        _;
    }

    /**
    * @dev Shareholder list
    */
    address[] internal _shareholders;

    /**
    * @dev Stores shareholders' balances for each round
    * Mapping: Round => (shareholder address => shareholder balance)
    */
    mapping(uint => mapping(address => uint)) internal _shareholderBalances;

    /**
    * @dev Set transfer contract address
    */
    function setTransferContractAddress (address contractAddress) external onlyOwner returns(bool){
        _transferContractAddress = contractAddress;
        return true;
    }

    /**
    @dev Update all related data for purchasing
    *
    * Implementations:
    *   1. Create purchase history
    *   2. Decrease remained token for `round`
    *   3. Increase shareholder's balance
     */
    function updatePurchaseData(address account, uint round, uint tokenAmount) external onlyTokenSaleContract returns(bool){
        require(round == 0 || round == 1, "Round is invalid");

        //Add share holder balance for round
        _increaseShareholderBalance(account, tokenAmount, round);

        //Save new shareholder if not existed
        require(_saveShareholder(account),"ShareTokenSaleData.updatePurchaseData: Can not create new shareholder");

        return true;
    }

    /**
    @dev Update all transfer data when a transfer request is maked
    *
    * Implementations
    *   1. Add transfer history
    *   2. Update transfer balance
    *   3. Update share holder balance
    */
    function updateTransferData(address from, address to, uint amount, uint round) external onlyTransferContract returns(bool){
        require(round == 0 || round == 1, "ShareTokenSaleData.addTransferHistoryAndBalance: Round is invalid");

        //Update shareholder balance
        _decreaseShareholderBalance(from, amount, round);
        _increaseShareholderBalance(to, amount, round);

        //Save new shareholder if not existed
        require(_saveShareholder(to),"ShareTokenSaleData.updateShareholderTransferData: Can not save new shareholder");

        return true;
    }

    /**
    * @dev Get share holder's token balance
    */
    function getShareholderBalance(address account, uint round) external view returns(uint){
        return _shareholderBalances[round][account];
    }

    /**
    * @dev Get shareholder list 
    */
    function getShareholders() external view returns(address[] memory){
        return _shareholders;
    }

    /**
    * @dev Increase shareholder balance with `amount` of BNU for round `round`
    */
    function _increaseShareholderBalance(address account, uint amount, uint round) internal{
        _shareholderBalances[round][account] = _shareholderBalances[round][account].add(amount);
    }

    /**
    * @dev Decrease shareholder balance with `amount` of BNU for round `round`
    */
    function _decreaseShareholderBalance(address account, uint amount, uint round) internal{
        _shareholderBalances[round][account] = _shareholderBalances[round][account].sub(amount);
    }

    /**
    * @dev Save new shareholder to _shareholders
    *
    * Requirements: `account` should be not address zero
    */
    function _saveShareholder(address account) internal returns(bool){
        //Requirements
        require(account != address(0),"Shareholder is address zero");
        for(uint index = 0; index < _shareholders.length; index++){
            if(_shareholders[index] == account)
                return true;
        }
        _shareholders.push(account);

        return true;
    }
}

// SPDX-License-Identifier: MIT