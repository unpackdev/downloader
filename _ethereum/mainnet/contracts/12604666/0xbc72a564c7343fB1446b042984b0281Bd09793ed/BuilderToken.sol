// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./Pausable.sol";

/**
* @title AccessList
* @dev AccessList contract manages a whitelist for users exempt from pause
 */
interface AccessList{
    function isApproved(address)external returns(bool);
}

/**
* @title Builder Toke
* @author Carson Case (carsonpcase@gmail.com)
* @notice Pausable ERC20 token. Where transfers are not possible when paused with the exception of the owner
 */
contract BuilderToken is ERC20, Ownable, Pausable{

    address accessListAddress;
    /**
    * @notice Constructor
    * @param _name ERC20 name
    * @param _symbol ERC20 symbol
    * @param _supply FIXED. Initial supply to mint to contract deployer
     */
    constructor(
    string memory _name,
    string memory _symbol,
    address _dev,
    uint _supply,
    address _accessList
    )
    ERC20(_name, _symbol)
    Ownable()
    Pausable()
    {
        accessListAddress = _accessList;
        transferOwnership(_dev);
        _mint(_dev, _supply);
    }

    /**
    * @notice Only for owner to call. Toggles pause
     */
    function togglePause() external onlyOwner{
        if(paused()){
            _unpause();
        }else{
            _pause();
        }
    }

    /**
    * @notice anyone can burn tokens
    * @param ammount to burn
     */
    function burn(uint ammount)external{
        _burn(msg.sender,ammount);
    }

    /**
    * @dev ERC20 transfer hook handles pauses
    * NOTE: If you are not using an AccessList the owner is the only one transactions are exempt for,
    * but that logic is not applied for AccessLists. If you are using a custom Access List, owner will not be exempt
    * from the transfer pause unless the owner is exempt in the AccessList.
     */
    function _beforeTokenTransfer(address from, address to, uint amount) internal override{
        //If no Access List given
        if(accessListAddress == address(0)){
            require(
                !paused() ||
                from == owner() ||
                to ==owner(),
                "When paused transfers must be to/from owner"
            );
        }
        //If a Access List is given
        else{
            AccessList AL = AccessList(accessListAddress);
            require(
                !paused() ||
                AL.isApproved(from) ||
                AL.isApproved(to),
                "When paused transfers must be to/from someone approved on the Access List"
            );
        }
    }

}