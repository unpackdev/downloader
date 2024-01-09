//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PausableCrowdsale.sol";
import "./Disabable.sol";


 contract DisabableCrowdsale is PausableCrowdsale, Disabable {

    constructor( uint256 __ethRate, address payable wallet, IERC20 gauf)
    PausableCrowdsale( __ethRate, wallet, gauf)
    {}

    /** 
    * @dev Implements the clean up before disabling the whole contract
    * after this, the whole crowdsale is totally useless, there should no
    * remain any kind of assets in the contract, and each public function 
    * should revert.
    * 
    * Note: there is no way to enable a contract again (turning disabled = true)
    * so this operation is irreversible
    */
   function disable() public onlyOwner {
    //Get the amount of tokens remaining in the contract
    IERC20 _token = token();
    uint256 amount = _token.balanceOf(address(this));

    //return the amount of tokens left to the wallet if any
    if(amount > 0){
   address _owner = owner(); 
    _deliverTokens(_owner, amount);
    }

    //Finally we disable the whole smart contract
    _disable();
    }

    /**
     * @dev Implementation of set address of Keeper contract
     * Ownable functionality implemented to restrict access
     */
    function setKeeper(address __keeper) public override isNotDisabled onlyOwner {
        super.setKeeper(__keeper);
    }

    /**
     * @dev Public implementation of _pause function from Pausable. 
     * Ownable functionality implemented to restrict access
     */
    function pause() public override isNotDisabled onlyOwner{
        super.pause();
    }

    /**
     * @dev Public implementation of _unpause function from Pausable. 
     * Ownable functionality implemented to restrict access
     */
    function unpause() public override isNotDisabled onlyOwner{
        super.unpause();
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use super to concatenate validations.
     * Adds the validation that the crowdsale must not be paused.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) override virtual internal view isNotDisabled {
        return super._preValidatePurchase(_beneficiary, _weiAmount);
    }


 }