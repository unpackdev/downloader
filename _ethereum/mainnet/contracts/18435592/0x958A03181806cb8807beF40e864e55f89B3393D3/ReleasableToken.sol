// SPDX-License-Identifier: MIT
/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

pragma solidity 0.7.6;

import "./Ownable.sol";
import "./StandardToken.sol";


  /**
  * Define interface for releasing the token transfer after a successful crowdsale.
  */
contract ReleasableToken is StandardToken, Ownable {
    
    event ReleaseAgentSet(address caller, address agent);
    event TransferAgentSet(address callet, address agent, bool set);
    
    /* The finalizer contract that allows unlift the transfer limits on this token */
    address public releaseAgent;

    /** A crowdsale contract can release us to the wild if ICO success. 
        If false we are are in transfer lock up period.*/
    bool public released = false;

    /** Map of agents that are allowed to transfer tokens regardless of the lock down period. 
        These are crowdsale contracts and possible the team multisig itself. */
    mapping (address => bool) public transferAgents;

    

    /**
    * Limit token transfer until the crowdsale is over.
    *
    */
    modifier canTransfer(address _sender) {

        if (!released) {
            if (!transferAgents[_sender]) {
                revert("Not A Transfer Agent");
            }
        }
        _;
    }

    /**
    * Set the contract that can call release and make the token transferable.
    *
    * Design choice. Allow reset the release agent to fix fat finger mistakes.
    */
    function setReleaseAgent(address addr) public onlyOwner inReleaseState(false) {
        require(addr != address(0), "Release Agent cannot be Null Address");
        // We don't do interface check here as we might want to a normal wallet address to act as a release agent
        releaseAgent = addr;

        emit ReleaseAgentSet(msg.sender, addr);
    }

    /**
    * Owner can allow a particular address (a crowdsale contract) to transfer tokens despite the lock up period.
    */
    function setTransferAgent(address addr, bool state) public onlyOwner inReleaseState(false) {
        transferAgents[addr] = state;

        emit TransferAgentSet(msg.sender, addr, state);
    }

    /**
    * One way function to release the tokens to the wild.
    *
    * Can be called only from the release agent that is the final ICO contract. 
    * It is only called if the crowdsale has been success (first milestone reached).
    */
    function releaseTokenTransfer() public virtual onlyReleaseAgent {
        released = true;
    }

    /** The function can be called only before or after the tokens have been releasesd */
    modifier inReleaseState(bool releaseState) {
        if (releaseState != released) {
            revert("Not in released state");
        }
        _;
    }

    /** The function can be called only by a whitelisted release agent. */
    modifier onlyReleaseAgent() {
        if (msg.sender != releaseAgent) {
            revert("Not release agent");
        }
        _;
    }

    function transfer(address _to, uint _value) public virtual override canTransfer(msg.sender) returns (bool success) {
        // Call StandardToken.transfer()
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public virtual override canTransfer(_from) returns (bool success) {
        // Call StandardToken.transferForm()
        return super.transferFrom(_from, _to, _value);
    }

}
