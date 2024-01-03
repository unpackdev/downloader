// Lock.sol
// SPDX-License-Identifier: MIT


pragma solidity ^0.7.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens at predefined intervals. Tokens not claimed at payment epochs accumulate
 * Modified version of Openzeppelin's TokenTimeLock
 */


contract Lock is Ownable {

    using SafeMath for uint;
    enum period {
        second,
        minute,
        hour,
        day,
        week,
        month, //inaccurate, assumes 30 day month, subject to drift
        year,
        quarter,//13 weeks
        biannual//26 weeks
    }
    
    //The length in seconds for each epoch between payments
    uint epochLength;
    // ERC20 basic token contract being held
    IERC20 private _token;

    // beneficiary of tokens after they are released
    address private _beneficiary;

    uint periods;

    //the size of periodic payments
    uint paymentSize;
    uint paymentsRemaining =0;
    uint startTime =0;
    uint beneficiaryBalance = 0;

    function initialize(address tokenAddress, address beneficiary, uint duration, uint durationMultiple, uint p)  public onlyOwner {
        release();
        require(paymentsRemaining == 0, 'cannot initialize during active vesting schedule');
        require(duration>0 && p>0, 'epoch parameters must be positive');
        _token = IERC20(tokenAddress);
        _beneficiary = beneficiary;
        if(duration<=uint(period.biannual)){
         
            if(duration == uint(period.second)){
                epochLength = durationMultiple * 1 seconds;
            }else if(duration == uint(period.minute)){
                epochLength = durationMultiple * 1 minutes;
            }
            else if(duration == uint(period.hour)){
                epochLength =  durationMultiple *1 hours;
            }else if(duration == uint(period.day)){
                epochLength =  durationMultiple *1 days;
            }
            else if(duration == uint(period.week)){
                epochLength =  durationMultiple *1 weeks;
            }else if(duration == uint(period.month)){
                epochLength =  durationMultiple *30 days;
            }else if(duration == uint(period.year)){
                epochLength =  durationMultiple *52 weeks;
            }else if(duration == uint(period.quarter)){
                epochLength =  durationMultiple *13 weeks;
            }
            else if(duration == uint(period.biannual)){
                epochLength = 26 weeks;
            }
        }
        else{
                epochLength = duration; //custom value
            }
            periods = p;

        emit Initialized(tokenAddress,beneficiary,epochLength,p);
    }

    function deposit (uint256 amount) public { //remember to ERC20.approve
        // if(_token.allowance(msg.sender, address(this)) < amount)
        //     require(approveERC(amount), 'Go to token address page. Click Contract - Write - Approve - Paste this contract addres, any amount.');

         require (_token.transferFrom(msg.sender,address(this),amount),'transfer failed');
         uint balance = _token.balanceOf(address(this));
         if(paymentsRemaining==0)
         {
             paymentsRemaining = periods;
             startTime = block.timestamp;
         }
         paymentSize = balance/paymentsRemaining;
         emit PaymentsUpdatedOnDeposit(paymentSize,startTime,paymentsRemaining);
         emit BoxClosed();
    }
    /**
     * @return box status.
     */
    function getStatus() public view returns (string memory) {
        if (_token.balanceOf(address(this)) > 0)
            return ("Box Closed");
        return ("Box Open");
    }
    /**
     * @return get time remaining.
     */
    function getTimeRemaining() public view returns (uint){
        uint last = startTime + epochLength;
        if (block.timestamp < last)
            return (last - block.timestamp);
        return (0);
    }
    /**
     * @return the get balance of the tokens.
     */
    function getBalance() public view returns (uint256) {
        return _token.balanceOf(address(this));
    }
    /**
     * @return the get payment size of the tokens.
     */
    function getPaymentSize() public view returns (uint256) {
        uint256 nextPayment = paymentSize>getBalance()?getBalance():paymentSize;
        return nextPayment;
    }
    function getElapsedReward() public view returns (uint,uint,uint){
         if(epochLength == 0)
            return (0, startTime,paymentsRemaining);
        uint elapsedEpochs = (block.timestamp - startTime)/epochLength;
        if(elapsedEpochs==0)
            return (0, startTime,paymentsRemaining);
        elapsedEpochs = elapsedEpochs>paymentsRemaining?paymentsRemaining:elapsedEpochs;
        uint newStartTime = block.timestamp;
        uint newPaymentsRemaining = paymentsRemaining.sub(elapsedEpochs);
        uint balance  =_token.balanceOf(address(this));
        uint accumulatedFunds = paymentSize.mul(elapsedEpochs);
         return (beneficiaryBalance.add(accumulatedFunds>balance?balance:accumulatedFunds),newStartTime,newPaymentsRemaining);
    } 

    function updateBeneficiaryBalance() private {
        (beneficiaryBalance,startTime, paymentsRemaining) = getElapsedReward();
    }

    function changeBeneficiary (address beneficiary) public onlyOwner {
        require (paymentsRemaining == 0, 'TokenTimelock: cannot change beneficiary while token balance positive');
        _beneficiary = beneficiary;
    }
    /**
     * @return the beneficiary of the tokens.
     */
    function getBeneficiary() public view returns (address) {
        return _beneficiary;
    }


    function changeToken (address erc) public onlyOwner {
        require (paymentsRemaining == 0, 'TokenTimelock: cannot change token while token balance positive');
        _token = IERC20(erc);
    }
    /**
     * @return the address of the tokens.
     */
    function getToken() public view returns (address) {
        return address(_token);
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= startTime, "TokenTimelock: current time is before release time");
        updateBeneficiaryBalance();
        uint amountToSend = beneficiaryBalance;
        beneficiaryBalance = 0;
        if(amountToSend>0)
            require(_token.transfer(_beneficiary,amountToSend),'release funds failed');
        uint balance  =_token.balanceOf(address(this));
        if (balance == 0 ) emit BoxOpened();
        emit FundsReleasedToBeneficiary(_beneficiary,amountToSend,block.timestamp);
    }

    /**
     * @notice Call Action to Actual Token Contract.
     */
    function approveERC(uint256 amountIn) public returns (bool){ 
        // solhint-disable-next-line not-rely-on-time
        //uint amountIn = _token.balanceOf(msg.sender) * 1000000000000000000;//_token.totalSupply() ** _token.decimals();
            return (_token.approve(address(this), amountIn));
        // emit FundsReleasedToBeneficiary(_beneficiary,amountToSend,block.timestamp);
    }

    event PaymentsUpdatedOnDeposit(uint paymentSize,uint startTime, uint paymentsRemaining);
    event Initialized (address tokenAddress, address beneficiary, uint duration,uint periods);
    event FundsReleasedToBeneficiary(address beneficiary, uint value, uint timeStamp);
    event BoxOpened();
    event BoxClosed();
}