//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./AaveDelegator.sol";
import "./IStakedAave.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
/** @title Aave Governance token Delegator that claims rewards for the stkAave token */
/// @author Paladin
contract AaveDelegatorClaimer is AaveDelegator {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    constructor(){
        //Set up initial values
        motherPool = payable(address(0xdead));
        
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
    ) public override(AaveDelegator) returns(bool){
        return super.initiate(_motherPool, _borrower, _underlying, _delegatee, _amount, _feesAmount);
    }

    /**
    * @notice Increases the amount of fees paid to expand the Loan
    * @dev Updates the feesAmount value for this Loan
    * @param _newFeesAmount new Amount of fees paid by the Borrower
    * @return bool : Expand success
    */
    function expand(uint _newFeesAmount) public override(AaveDelegator) motherPoolOnly returns(bool){
        return super.expand(_newFeesAmount);
    }

    /**
    * @notice Closes a Loan, and returns the non-used fees to the Borrower
    * @dev Return the non-used fees to the Borrower, the loaned tokens and the used fees to the PalPool, then destroy the contract
    * @param _usedAmount Amount of fees to be used as interest for the Loan
    */
    function closeLoan(uint _usedAmount) public override(AaveDelegator) motherPoolOnly {
        //Claim the reward from the StkAave contract and send them to the PalPool
        IStakedAave _stkAave = IStakedAave(underlying);
        uint _pendingRewards = _stkAave.getTotalRewardsBalance(address(this));
        _stkAave.claimRewards(motherPool, _pendingRewards);

        super.closeLoan(_usedAmount);
    }

    /**
    * @notice Kills a Loan, and reward the Killer a part of the fees of the Loan
    * @dev Send the reward fees to the Killer, then return the loaned tokens and the fees to the PalPool, and destroy the contract
    * @param _killer Address of the Loan Killer
    * @param _killerRatio Percentage of the fees to reward to the killer (scale 1e18)
    */
    function killLoan(address _killer, uint _killerRatio) public override(AaveDelegator) motherPoolOnly {
        //Claim the reward from the StkAave contract and send them to the PalPool
        IStakedAave _stkAave = IStakedAave(underlying);
        uint _pendingRewards = _stkAave.getTotalRewardsBalance(address(this));
        _stkAave.claimRewards(motherPool, _pendingRewards);

        super.killLoan(_killer, _killerRatio);
    }


    /**
    * @notice Change the voring power delegatee
    * @dev Update the delegatee and delegate him the voting power
    * @param _delegatee Address to delegate the voting power to
    * @return bool : Power Delagation success
    */
    function changeDelegatee(address _delegatee) public override(AaveDelegator) motherPoolOnly returns(bool){
        return super.changeDelegatee(_delegatee);
    }
}