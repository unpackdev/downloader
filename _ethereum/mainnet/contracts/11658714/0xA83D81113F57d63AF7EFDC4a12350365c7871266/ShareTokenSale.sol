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

/**
@title Share token sale BNU interface
 */
interface IBNUStore{
    /**
    * @dev Transfer BNU token from contract to `recipient`
    */
    function transfer(address recipient, uint amount) external returns(bool);
}

interface IERC20Token{
    function burnTokenSale(address account, uint amount) external returns(bool);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

interface IShareTokenSaleData{
    /**
    * @dev Add a new purchased history of `account` and Update total purchased token amount of `account` in round `round`
    */
    function updatePurchaseData(address account, uint round, uint tokenAmount) external returns(bool);

    /**
    * @dev Update properties for end round
     */
    function end(uint round, uint time) external returns(bool);

    /**
    * @dev Get the next time can be released for this round
    */
    function getNextReleaseTime(uint round) external view returns(uint);

    /**
    * @dev Get release count by round
    */
    function getReleasedCountByRound(uint round) external view returns(uint);

    /**
    * @dev Get release count by round and holder
    */
    function getReleasedCountByRoundAndHolder(uint round, address account) external view returns(uint);

    /**
    * @dev Get release count by round
    */
    function getReleasedPercentByRound(uint round) external view returns(uint);

    /**
    * @dev Get total count can be released by round `round`
    */
    function getTotalCanReleaseCountByRound(uint round) external view returns(uint);

    /**
    * @dev Update released data when releasing
    */
    function updateReleasedData(uint round) external returns(bool);

    /**
    * @dev Update released data when releasing
    */
    function updateWithdrawData(address account, uint round) external returns(bool);

    /**
    * @dev Get the state to check whether shareholders can transfer BNU or not
    */
    function getShareholderCanTransfer() external view returns(bool);

    /**
    * @dev Get shareholder list 
    */
    function getShareholders() external view returns(address[] memory);

    /**
    * @dev Set the state to check whether shareholders can transfer BNU or not
    */
    function setShareholderCanTransfer(bool value) external;

    /**
    @dev Update all transfer data when a transfer request is maked
    *
    */
    function updateShareholderTransferData(address from, address to, uint amount, uint round) external returns(bool);

    /**
    * @dev Get shareholder's token balance by `round`
    */
    function getShareholderBalance(address account, uint round) external view returns(uint);

    /**
    * @dev Get end time of `round` 
    */
    function getTokenSaleEndTime(uint round)  external view returns(uint);
}

/**
@title Base contract for contract to interact with BNU Store contract
 */
contract BaseBNUStoreClient is Context{
    IBNUStore internal _bnuStoreContract;

    function setBNUStoreContract(address contractAddress) external onlyOwner contractActive{
        _setBNUStoreContract(contractAddress);
    }

    function _setBNUStoreContract(address contractAddress) internal{
        _bnuStoreContract = IBNUStore(contractAddress);
    }
}

contract ShareTokenSale is BaseBNUStoreClient{
    using SafeMath for uint;

    IShareTokenSaleData internal _dbContract;
    IBNFToken internal _bnfTokenContract;

    function setBnfTokenContract(address contractAddress) external onlyOwner contractActive{
        _setBnfTokenContract(contractAddress);
    }

    /**
    * @dev Set contract addresses
    * @param dbAddress new database contract address
    * @param bnuStoreAddress new BNU contract address
    * @param bnfAddress new BNF contract address
    */
    function setContracts(address dbAddress, address bnuStoreAddress, address bnfAddress) external onlyOwner contractActive{
        _setDbContract(dbAddress);
        _setBNUStoreContract(bnuStoreAddress);
        _setBnfTokenContract(bnfAddress);
    }

    function setDbContract(address contractAddress) external onlyOwner contractActive{
        _setDbContract(contractAddress);
    }

    /**
    * @dev End current round
    * Requirements
    *   Current round should be Seed or Private
    *
    * Implementations
    *   1. Validate requirements
    *   2. Update _canPurchase property
    *   3. Burn all remain tokens of this round
    *   4. Call to dbContract to end current round
    */
    function end(uint round, uint time) external onlyOwner returns(bool){
        uint endTime = _dbContract.getTokenSaleEndTime(round);
        require(endTime == 0, "ShareTokenSaleFactory.end: This round has been ended before");

        //Update end round stage and emit event
        _end(round, time);

        return true;
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
    * @dev Get the state to check whether shareholders can transfer BNU or not
    */
    function getShareholderCanTransfer() external view returns(bool){
        return _getShareholderCanTransfer();
    }

    /**
    * @dev Set the state to check whether shareholders can transfer BNU or not
    */
    function setShareholderCanTransfer(bool value) external onlyOwner{
        _dbContract.setShareholderCanTransfer(value);
    }

    /**
    * @dev Transfer BNU between shareholders
    * @param from shareholder sender
    * @param to shareholder receiver
    * @param amount BNU token amount to transfer
    * @param round Seed or Private round
    * 
    * Requirements
    *   1. Can transfer BNU now
    *   1. `from` and `to` is not zero address
    *   2. `amount` is greater than zero
    *   3. `from` has enough `amount` token in `round`
    *
    * Implementations
    *   1. Validate requirements
    *   2. Update from and to BNU amount: Decrease from BNU token amount and increase to BNU token amount
    *   3. Update from and to BNF amount: Decrease from BNF token amount and increase to BNF token amount
    *   4. emit Events
    */
    function shareholderTransfer(address from, address to, uint amount, uint round) external onlyOwner returns(bool){
        require(_getShareholderCanTransfer(),"ShareTokenSaleFactory.shareHolderTransfer: Can not transfer now");
        //Requirements
        require(from != address(0) && to != address(0), "ShareTokenSaleFactory.shareHolderTransfer: From or to is address zero");
        require(from != to, "ShareTokenSaleFactory.shareHolderTransfer: Sender and recipient are the same");
        require(amount > 0, "ShareTokenSaleFactory.shareHolderTransfer: amount is zero");
        require(_getShareholderBalance(from, round) >= amount, "ShareTokenSaleFactory.shareHolderTransfer: Balance is not enough");

        //Update transfer data: Create transfer history, Update shareholder balance
        require(_dbContract.updateShareholderTransferData(from, to, amount, round),"ShareTokenSaleFactory.shareHolderTransfer: Can not update transfer data");

        //Update BNF for sender and receiver
        require(_bnfTokenContract.shareholderTransfer(from, to, amount), "ShareTokenSaleFactory.shareHolderTransfer: Can not update shareholders' BNF balances");

        return true;
    }

    /**
    * @dev Get shareholder's token balance by `round`
    */
    function getShareholderBalance(address account, uint round) external view returns(uint){
        return _getShareholderBalance(account, round);
    }

    /**
    * @dev Release token for each stage of specific round
    *
    * @param round Round to release token
    *
    * Requirements:
    *   1. Round should be Seed or Private
    *   2. Processing round percent should be less than or equals 100%
    *
    * Implementations:
    *   1. Get all shareholders to process
    *   2. For each shareholder, calculate released token and pay
    *   3. Create released history
    *   4. Increase total release percent
    */
    function release(uint round) external onlyOwner returns(bool){
        require(round == 0 || round == 1, "Round should be Seed or Private round");

        uint releaseCountByRound = _dbContract.getReleasedCountByRound(round);
        //Can release more
        require(releaseCountByRound <  _dbContract.getTotalCanReleaseCountByRound(round), "All token has been released");

        //Enough time to release
        require(_now() >= _dbContract.getNextReleaseTime(round),"ShareTokenSaleFactory.release: Can not release this time");

        uint releasePercent = _dbContract.getReleasedPercentByRound(round);

        address[] memory shareholders = _getShareholders();

        bool result = false;
        if(shareholders.length > 0){
            for(uint index = 0; index < shareholders.length; index++){
                if(_getReleasedCountByRoundAndHolder(round, shareholders[index]) <= releaseCountByRound){
                    require(
                        _processRelease(shareholders[index], _getShareholderBalance(shareholders[index], round).mul(releasePercent).div(1000), round),
                        "Can not process token releasing");

                    result = true;
                }
            }

            //Update total release percent of round
            require(_dbContract.updateReleasedData(round),"Can not update release data");
        }

        return result;
    }

    /**
    * @dev Holders can withdraw released token for each round in released time
    */
    function withdraw(uint round) external returns(bool){
        address account = _msgSender();
        require(round == 0 || round == 1, "Round should be Seed or Private round");

        uint releaseCountByRound = _dbContract.getReleasedCountByRound(round);
        //Can release more
        require(releaseCountByRound <  _dbContract.getTotalCanReleaseCountByRound(round), "All token has been released");

        //Enough time to release
        require(_now() >= _dbContract.getNextReleaseTime(round),"ShareTokenSaleFactory.release: Can not release this time");

        if(_getReleasedCountByRoundAndHolder(round, account) <= releaseCountByRound){
            uint releasePercent = _dbContract.getReleasedPercentByRound(round);
            require(_processRelease(account, _getShareholderBalance(account, round).mul(releasePercent).div(1000), round), "Can not process token releasing");

            return true;
        }

        return false;
    }

    /**
    * @dev Process releasing tokens after validating
     */
    function _processRelease(address recipient, uint amount, uint round) internal returns(bool){
        require(_bnuStoreContract.transfer(recipient, amount), "_processRelease: Can not transfer token to receiver");

        //Update total release percent of round
        require(_dbContract.updateWithdrawData(recipient, round),"Can not update withdraw data");

        //Emit event
        emit Release(recipient, amount);
        return true;
    }

    /**
    * @dev Get shareholder's token balance by `round`
    */
    function _getShareholderBalance(address account, uint round) internal view returns(uint){
        return _dbContract.getShareholderBalance(account, round);
    }

    /**
    * @dev End current round after validating all requirements
    */
    function _end(uint round, uint time) internal {
        //Call db contract to end
        require(_dbContract.end(round, time), "ShareTokenSaleFactory._end: Can not end current round");

        //emit event
        emit EndTokenSale(round, time);
    }

    function _getReleasedCountByRoundAndHolder(uint round, address account) internal view returns(uint){
        return _dbContract.getReleasedCountByRoundAndHolder(round, account);
    }

    /**
    * @dev Get shareholder list 
    */
    function _getShareholders() internal view returns(address[] memory){
        return _dbContract.getShareholders();
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

    function _getShareholderCanTransfer() internal view returns(bool){
        return _dbContract.getShareholderCanTransfer();
    }

    event EndTokenSale(uint round, uint time);
    event Purchase(address account, uint amount, uint round);
    event Release(address account, uint amount);
}

//SPDX-License-Identifier: MIT