// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Roles {
    bytes32 constant ROLE_ADMIN = keccak256('operator.dabot.role');
    bytes32 constant ROLE_OPERATORS = keccak256('operator.dabot.role');
    bytes32 constant ROLE_TEMPLATE_CREATOR = keccak256('creator.template.dabot.role');
    bytes32 constant ROLE_BOT_CREATOR = keccak256('creator.dabot.role');
    bytes32 constant ROLE_FUND_APPROVER = keccak256('approver.fund.role');
}

library AddressBook {
    bytes32 constant ADDR_FACTORY = keccak256('factory.address');
    bytes32 constant ADDR_VICS = keccak256('vics.address');
    bytes32 constant ADDR_TAX = keccak256('tax.address');
    bytes32 constant ADDR_GOVERNANCE = keccak256('governance.address');
    bytes32 constant ADDR_GOVERNANCE_EXECUTOR = keccak256('executor.governance.address');
    bytes32 constant ADDR_BOT_MANAGER = keccak256('botmanager.address');
    bytes32 constant ADDR_VICS_EXCHANGE = keccak256('exchange.vics.address');
    bytes32 constant ADDR_TREASURY_MANAGER = keccak256('treasury-manager.address');
    bytes32 constant ADDR_CEX_FUND_MANAGER = keccak256('fund-manager.address');
    bytes32 constant ADDR_CEX_DEFAULT_MASTER_ACCOUNT = keccak256('default.master.address');
    bytes32 constant ADDR_ROBOFI_GAME = keccak256('robofi-game.address');
}

library Config {
    /// The amount of VICS that a proposer has to pay when create a new proposal
    bytes32 constant PROPOSAL_DEPOSIT = keccak256('deposit.proposal.config');

    /// The percentage of proposal creation fee distributed to the account that execute a propsal
    bytes32 constant PROPOSAL_REWARD_PERCENT = keccak256('reward.proposal.config');

    /// The minimum VICS a bot creator has to deposit to a newly created bot
    bytes32 constant CREATOR_DEPOSIT = keccak256('deposit.creator.config');

    /// The minim 
    bytes32 constant PROPOSAL_CREATOR_MININUM_POWER = keccak256('minpower.goverance.config');
    
    /// The minimum percentage of for-votes over total votes a proposal has to achieve to be passed
    bytes32 constant PROPOSAL_MINIMUM_QUORUM = keccak256('minquorum.governance.config');

    /// The minimum difference (in percentage) between for-votes and against-vote for a proposal to be passed
    bytes32 constant PROPOSAL_VOTE_DIFFERENTIAL = keccak256('differential.governance.config');

    /// The voting duration of a proposal
    bytes32 constant PROPOSAL_DURATION = keccak256('duration.goverance.config');

    /// The interval that a passed proposed is waiting in queue before being executed
    bytes32 constant PROPOSAL_EXECUTION_DELAY = keccak256('execdelay.governance.config');

    // Number of winners of RoboFi Game
    bytes32 constant GAME_NUMBER_WINNER = keccak256('num-of-winner.game.config');

    // The commit phase duration of a game
    bytes32 constant GAME_COMMIT_DURATION = keccak256('commit.game.config');

    // The reveal phase duration of a game
    bytes32 constant GAME_REVEAL_DURATION = keccak256('reveal.game.config');
}

interface IConfigurator {
    function addressOf(bytes32 addrId) external view returns(address);
    function configOf(bytes32 configId) external view returns(uint);
    function bytesConfigOf(bytes32 configId) external view returns(bytes memory);

    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
}

