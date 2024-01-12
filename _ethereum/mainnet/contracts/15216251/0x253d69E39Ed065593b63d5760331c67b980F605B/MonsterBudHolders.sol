// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.12;

import "./OwnableUpgradeable.sol";

abstract contract MonsterBudHolders is OwnableUpgradeable{
    
    // mapping of ppp address with their status
    mapping(address => bool) public holders;

    /**
     * @dev Emitted when `ppp user address` status is set to true.
    */
    event AddHolder(address pppUser, bool status);

    /**
     * @dev adds 484 ppp users at one time.
     * @param _pppUser array of address to be added.
     * @param _status status in boolean.
     *
     * Requirements
     * - array must have 484 address.
     * - only owner must call this method.
     *
     * Emits a {AddHolder} event.
    */
    
    function addPPPUserStatus(address[484] calldata _pppUser, bool _status) onlyOwner external {
        for(uint i = 0; i < 484; i++){
            holders[_pppUser[i]] = _status;
            emit AddHolder(_pppUser[i], _status);        
        }
    }

    /**
     * @dev checks where user address can use free mint.
     * @param _pppUser user address.
     *
     * Returns
     * - status in boolean.
    */

    function checkPPPUser(address _pppUser) external view returns(bool){
        require(_pppUser != address(0x00), "$MONSTERBUDS: zero address can not be ppp user");
        return holders[_pppUser];
    }

    /**
     * @dev It destroy the contract and returns all balance of this contract to owner.
     *
     * Returns
     * - only owner can call this method.
    */ 

    function selfDestruct() 
        public 
        onlyOwner{
    
        payable(owner()).transfer(address(this).balance);
        //selfdestruct(payable(address(this)));
    }


}
