//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Crowdsale.sol";
import "./Pausable.sol";
import "./Ownable.sol";



/**
 * @title PausableCrowdsale
 * @dev Extension of Crowdsale contract where purchases can be paused and unpaused by the pauser role.
 */
contract PausableCrowdsale is Crowdsale, Pausable, Ownable {

    address private _keeper;

    constructor(uint256 rate, address payable wallet, IERC20 token) Crowdsale(rate, wallet, token) {

    }
    modifier onlyKeeper(){
       require(msg.sender == _keeper, 'onlyKeeper: Sender is not keeper'); 
       _;
    }

    /**
     * @dev Implementation of set address of Keeper contract
     * Ownable functionality implemented to restrict access
     */
    function setKeeper(address __keeper) public virtual onlyOwner {
        _keeper = __keeper;
    }

    /**
     * @dev Public implementation to get keeper address
     */
    function keeper() public view returns(address){
        return _keeper;
    }

    /**
     * @dev Public implementation of _pause function from Pausable. 
     * Ownable functionality implemented to restrict access
     */
    function pause() public virtual onlyOwner{
        _pause();
    }

    /**
     * @dev Public implementation of _unpause function from Pausable. 
     * Ownable functionality implemented to restrict access
     */
    function unpause() public virtual onlyOwner{
        _unpause();
    }

    /**
     * @dev Public implementation of _setNewEthRate from Crowdsale
     * onlyKeeperfunctionality implemented to restrict access
     * @param __newEthRate New rate of how many token units a buyer gets per wei.
     */
    function setNewEthRate(uint256 __newEthRate) public onlyKeeper {
        super._setNewEthRate(__newEthRate);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use super to concatenate validations.
     * Adds the validation that the crowdsale must not be paused.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) override virtual internal view whenNotPaused {
        return super._preValidatePurchase(_beneficiary, _weiAmount);
    }

}