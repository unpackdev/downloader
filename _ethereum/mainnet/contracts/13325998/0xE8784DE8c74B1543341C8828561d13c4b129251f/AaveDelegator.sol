//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IGovernancePowerDelegationToken.sol";
import {Errors} from  "../utils/Errors.sol";

/** @title Aave Governance token Delegator  */
/// @author Paladin
contract AaveDelegator {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    //Variables

    /** @notice Address of the underlying token for this loan */
    address public underlying;
    /** @notice Amount of the underlying token in this loan */
    uint public amount;
    /** @notice Address of the borrower */
    address public borrower;
    /** @notice Address of the delegatee for the voting power */
    address public delegatee;
    /** @notice PalPool that created this loan */
    address payable public motherPool;
    /** @notice Amount of fees paid for this loan */
    uint public feesAmount;

    constructor(){
        //Set up initial values
        motherPool = payable(address(0xdead));
        
    }

    modifier motherPoolOnly() {
        require(msg.sender == motherPool);
        _;
    }

    /**
    * @notice Starts the Loan and Delegate the voting Power to the Delegatee
    * @dev Sets the amount values for the Loan, then delegate the voting power to the Delegatee
    * @param _delegatee Address to delegate the voting power to
    * @param _amount Amount of the underlying token for this loan
    * @param _feesAmount Amount of fees (in the underlying token) paid by the borrower
    * @return bool : Power Delagation success
    */
    function initiate(
        address _motherPool,
        address _borrower,
        address _underlying,
        address _delegatee,
        uint _amount,
        uint _feesAmount
    ) public virtual returns(bool){
        require(motherPool == address(0));

        motherPool = payable(_motherPool);
        borrower = _borrower;
        underlying = _underlying;
        //Set up the borrowed amount and the amount of fees paid
        amount = _amount;
        feesAmount = _feesAmount;
        delegatee = _delegatee;
        
        //Delegate governance power : AAVE version
        IGovernancePowerDelegationToken govToken = IGovernancePowerDelegationToken(underlying);
        govToken.delegate(_delegatee);
        return true;
    }

    /**
    * @notice Increases the amount of fees paid to expand the Loan
    * @dev Updates the feesAmount value for this Loan
    * @param _newFeesAmount new Amount of fees paid by the Borrower
    * @return bool : Expand success
    */
    function expand(uint _newFeesAmount) public virtual motherPoolOnly returns(bool){
        feesAmount = feesAmount.add(_newFeesAmount);
        return true;
    }

    /**
    * @notice Closes a Loan, and returns the non-used fees to the Borrower
    * @dev Return the non-used fees to the Borrower, the loaned tokens and the used fees to the PalPool, then destroy the contract
    * @param _usedAmount Amount of fees to be used as interest for the Loan
    */
    function closeLoan(uint _usedAmount) public virtual motherPoolOnly {
        IERC20 _underlying = IERC20(underlying);
        
        //Return the remaining amount to the borrower
        //Then return the borrowed amount and the used fees to the pool
        uint _returnAmount = feesAmount.sub(_usedAmount);
        uint _balance = _underlying.balanceOf(address(this));
        uint _keepAmount = _balance.sub(_returnAmount);
        if(_returnAmount > 0){
            _underlying.safeTransfer(borrower, _returnAmount);
        }
        _underlying.safeTransfer(motherPool, _keepAmount);

         //Destruct the contract, so it's not usable anymore
        selfdestruct(motherPool);
    }

    /**
    * @notice Kills a Loan, and reward the Killer a part of the fees of the Loan
    * @dev Send the reward fees to the Killer, then return the loaned tokens and the fees to the PalPool, and destroy the contract
    * @param _killer Address of the Loan Killer
    * @param _killerRatio Percentage of the fees to reward to the killer (scale 1e18)
    */
    function killLoan(address _killer, uint _killerRatio) public virtual motherPoolOnly {
        IERC20 _underlying = IERC20(underlying);
        
        //Send the killer reward to the killer
        //Then return the borrowed amount and the fees to the pool
        uint _killerAmount = feesAmount.mul(_killerRatio).div(uint(1e18));
        uint _balance = _underlying.balanceOf(address(this));
        uint _poolAmount = _balance.sub(_killerAmount);
        _underlying.safeTransfer(_killer, _killerAmount);
        _underlying.safeTransfer(motherPool, _poolAmount);

         //Destruct the contract, so it's not usable anymore
        selfdestruct(motherPool);
    }


    /**
    * @notice Change the voring power delegatee
    * @dev Update the delegatee and delegate him the voting power
    * @param _delegatee Address to delegate the voting power to
    * @return bool : Power Delagation success
    */
    function changeDelegatee(address _delegatee) public virtual motherPoolOnly returns(bool){
        delegatee = _delegatee;
        
        //Delegate governance power : AAVE version
        IGovernancePowerDelegationToken govToken = IGovernancePowerDelegationToken(underlying);
        govToken.delegate(_delegatee);
        return true;
    }
}