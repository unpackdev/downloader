// SPDX-License-Identifier: MIT
/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

pragma solidity 0.7.6;

import "./ERC20.sol";
import "./StandardToken.sol";
import "./UpgradeAgent.sol";


/**
 * A token upgrade mechanism where users can opt-in amount of tokens to the next smart contract revision.
 *
 * First envisioned by Golem and Lunyr projects.
 */
contract UpgradeableToken is StandardToken {
    using SafeMathLibExt for uint;

    /** Contract / person who can set the upgrade path. 
        This can be the same as team multisig wallet, as what it is with its default value. */
    address public upgradeMaster;

    /** The next contract where the tokens will be migrated. */
    UpgradeAgent public upgradeAgent;

    /** How many tokens we have upgraded by now. */
    uint256 public totalUpgraded;
    /**
    * Upgrade states.
    *
    * - NotAllowed: The child contract has not reached a condition where the upgrade can bgun
    * - WaitingForAgent: Token allows upgrade, but we don't have a new agent yet
    * - ReadyToUpgrade: The agent is set, but not a single token has been upgraded yet
    * - Upgrading: Upgrade agent is set and the balance holders can upgrade their tokens
    *
    */
    enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

    /**
    * Somebody has upgraded some of his tokens.
    */
    event Upgrade(address indexed _from, address indexed _to, uint256 _value);

    /**
    * New upgrade agent available.
    */
    event UpgradeAgentSet(address agent);

    /**
    * New upgrade master available.
    */   
    event UpgradeMasterSet(address agent);


    /**
    * Do not allow construction without upgrade master set.
    */
    constructor(address _upgradeMaster) {
        require(_upgradeMaster != address(0), "Upgrade Master cannot be Null Address");
        upgradeMaster = _upgradeMaster;
    }

    /**
    * Allow the token holder to upgrade some of their tokens to a new contract.
    */
    function upgrade(uint256 value) public {

        UpgradeState state = getUpgradeState();
        if (!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
            // Called in a bad state
            revert("Called in bad State");
        }

        // Validate input value.
        if (value == 0) revert("Invalid input value");

        balances[msg.sender] = balances[msg.sender].minus(value);

        // Take tokens out from circulation
        totalSupply = totalSupply.minus(value);
        totalUpgraded = totalUpgraded.plus(value);

        // Upgrade agent reissues the tokens
        upgradeAgent.upgradeFrom(msg.sender, value);
        emit Upgrade(msg.sender, address(upgradeAgent), value);
    }

    /**
    * Child contract can enable to provide the condition when the upgrade can begun.
    */
    function canUpgrade() public virtual returns(bool) {
        return true;
    }

    /**
    * Set an upgrade agent that handles
    */
    function setUpgradeAgent(address agent) external {
        if (!canUpgrade()) {
            // The token is not yet in a state that we could think upgrading
            revert("The token is not yet in a state that we could think upgrading");
        }

        if (agent == address(0)) revert("Cannot be Zero Address");
        // Only a master can designate the next agent
        if (msg.sender != upgradeMaster) revert("Only a master can designate the next agent");
        // Upgrade has already begun for an agent
        if (getUpgradeState() == UpgradeState.Upgrading) revert("Upgrade has already begun for an agent");

        upgradeAgent = UpgradeAgent(agent);

        // Bad interface
        if (!upgradeAgent.isUpgradeAgent()) revert("Bad interface");      

        emit UpgradeAgentSet(agent);
    }

    /**
    * Get the state of the token upgrade.
    */
    function getUpgradeState() public returns(UpgradeState) {
        if (!canUpgrade()) return UpgradeState.NotAllowed;
        else if (address(upgradeAgent) == address(0)) return UpgradeState.WaitingForAgent;
        else if (totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
        else return UpgradeState.Upgrading;
    }

    /**
    * Change the upgrade master.
    *
    * This allows us to set a new owner for the upgrade mechanism.
    */
    function setUpgradeMaster(address master) public {
        if (master == address(0)) revert("Cannot set master contract to 0");
        if (msg.sender != upgradeMaster) revert("Msg Sender not upgrade master");
        upgradeMaster = master;

        emit UpgradeMasterSet(master);
    }
}
