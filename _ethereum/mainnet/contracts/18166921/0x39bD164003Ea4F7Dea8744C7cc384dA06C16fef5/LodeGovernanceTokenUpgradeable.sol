//SPDX-License-Identifier: MIT.
pragma solidity ^0.8.0;

import "./AccessControlEnumerableUpgradeable.sol";
import "./Initializable.sol";
import "./ERC20VotesUpgradeable.sol";

contract LodeGovernanceTokenUpgradeable is Initializable, ERC20VotesUpgradeable, AccessControlEnumerableUpgradeable {

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    uint256 public constant TIMELOCK = 2 days;

    struct Proposal {
        address account;
        bytes32 role;
        uint256 timestamp;
        bool grant;
        bool executed;
    }

    uint256 private _proposals;

    mapping(uint256 => Proposal) public roleProposals;

    event RoleProposed(uint256 proposal, address account, bytes32 role, bool grant);

    function initialize(uint256 _totalSupply, address _recipient, address _owner) public initializer {
        __ERC20Votes_init();
        __ERC20Permit_init("Lode Permit");
        __ERC20_init("LODE Token", "LODE");
        __Context_init();
        __AccessControlEnumerable_init();
        __AccessControl_init();

        super._grantRole(OWNER_ROLE, _owner);
        super._setRoleAdmin(OWNER_ROLE, OWNER_ROLE);

        ERC20VotesUpgradeable._mint(_recipient, _totalSupply);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        return super.transferFrom(from, to, amount); //Check
    } 


    /*********** ROLE-SETTER METHODS ***********/
    function grantRoleProposal(bytes32 role, address _account) external onlyRole(OWNER_ROLE) {
        _roleProposal(role, _account, true);
    }
    
    function revokeRoleProposal(bytes32 role, address _account) external onlyRole(OWNER_ROLE) {
        _roleProposal(role, _account, false);
    }

    function grantRoleExecution(uint256 _proposal) external onlyRole(OWNER_ROLE) {
        _roleExecution(_proposal, true); 
    }

    function revokeRoleExecution(uint256 _proposal) external onlyRole(OWNER_ROLE) {
        _roleExecution(_proposal, false); 
    }

    function _roleProposal(bytes32 role, address _account, bool grant) internal {
        require(role == OWNER_ROLE, "Error: Role does not exist");
        require(_account != address(0), "Error: Account is the null address");

        roleProposals[_proposals] = Proposal(_account, role, block.timestamp, grant, false);

        emit RoleProposed(_proposals, _account, role, grant);

        _proposals += 1;
    }

    function _roleExecution(uint256 _proposal, bool grant) internal {
        Proposal memory proposal = roleProposals[_proposal];

        require(proposal.executed == false, "Error: Proposal already executed");
        require(proposal.account != address(0), "Error: Invalid proposal");
        require(proposal.timestamp + TIMELOCK <= block.timestamp, "Error: Binding timelock");

        if(grant) {
            require(proposal.grant, "Error: Revoke proposal");
            super._grantRole(proposal.role, proposal.account);
        } else {
            require(!proposal.grant, "Error: Grant proposal");
            super._revokeRole(proposal.role, proposal.account);     
        }

        proposal.executed = true;
    }

    function grantRole(bytes32 role, address _account) public override onlyRole(OWNER_ROLE) {
        revert("Error: Deprecated method");
    }

    function revokeRole(bytes32 role, address _account) public override onlyRole(OWNER_ROLE) {
        revert("Error: Deprecated method");
    }
}