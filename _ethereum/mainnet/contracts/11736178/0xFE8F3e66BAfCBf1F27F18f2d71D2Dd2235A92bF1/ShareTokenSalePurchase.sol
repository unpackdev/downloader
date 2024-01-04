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

interface IBNFToken{
    function createShareHolder(address account, uint amount) external returns(bool);

    /**
    * @dev Transfer BNF token from sender to recipient when sender transfers BNU token to recipient
    */
    function shareholderTransfer(address sender, address recipient, uint amount) external returns(bool);
}

interface IShareTokenSaleData{
    /**
    * @dev Add a new purchased history of `account` and Update total purchased token amount of `account` in round `round`
    */
    function updatePurchaseData(address account, uint round, uint tokenAmount) external returns(bool);

    /**
    * @dev Get shareholder list 
    */
    function getShareholders() external view returns(address[] memory);

    /**
    * @dev Get shareholder's token balance by `round`
    */
    function getShareholderBalance(address account, uint round) external view returns(uint);
}

/**
@title Share token sale factory
@dev Process purchasing token in seed and private round
 */
contract ShareTokenSalePurchase is Context{
    using SafeMath for uint;

    IShareTokenSaleData internal _dbContract;
    IBNFToken internal _bnfTokenContract;

    function getBalance(address account, uint round) external view returns(uint){
        return _dbContract.getShareholderBalance(account, round);
    }

    function getHolders() external view returns(address[] memory){
        return _dbContract.getShareholders();
    }

    function setBnfTokenContract(address contractAddress) external onlyOwner contractActive{
        _setBnfTokenContract(contractAddress);
    }

    /**
    * @dev Set contract addresses
    * @param dbAddress new database contract address
    * @param bnfAddress new BNF contract address
    */
    function setContracts(address dbAddress, address bnfAddress) external onlyOwner contractActive{
        _setDbContract(dbAddress);
        _setBnfTokenContract(bnfAddress);
    }

    function setDbContract(address contractAddress) external onlyOwner contractActive{
        _setDbContract(contractAddress);
    }

    /**
    * @dev Process to purchase token
    * @param account account address to purchase
    * @param tokenAmount purchased amount
    * @param round round to purchase
    * 
    * Requirements:
    *   1. Can purchase
    *   2. Time to purchase is available
    *   3. Remain token amount is greater than or equals `amount`
    *
    * Implementations:
    *   1. Validate the remain token amount
    *   2. Update purchased token amount for `account`
    *   3. Create purchased history for `account`
    *   4. Reduce remain amount for this round
    *   5. Process to raise BNF fund
    *   6. Check to end current round if all tokens are sold
    *   7. Emit event
    */
    function purchase(address account, uint tokenAmount, uint round) external onlyOwner returns(bool){
        require(tokenAmount > 0, "Token amount is zero");

        require(round == 0 || round == 1, "Current round should be Seed or Private");

        //Create purchased history
        require(_dbContract.updatePurchaseData(account, round, tokenAmount),"purchase: Can not add new purchased history");

        //Raise BNF fund
        require(_bnfTokenContract.createShareHolder(account, tokenAmount), "Can not create share holder");

        //emit Events
        emit Purchase(account, tokenAmount, round);

        return true;
    }

    /**
    * @dev Set database contract address
    * @param contractAddress new database contract address
    */
    function _setDbContract(address contractAddress) internal{
        _dbContract = IShareTokenSaleData(contractAddress);
    }

    /**
    * @dev Set BNU contract address
    * @param contractAddress new BNU contract address
    */
    function _setBnfTokenContract(address contractAddress) internal{
        _bnfTokenContract = IBNFToken(contractAddress);
    }

    event EndTokenSale(uint round, uint time);
    event Purchase(address account, uint amount, uint round);
}

// SPDX-License-Identifier: MIT