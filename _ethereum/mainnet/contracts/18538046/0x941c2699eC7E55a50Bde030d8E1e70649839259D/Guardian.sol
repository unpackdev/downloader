// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IGovernorMills {
    function cancel(uint proposalId) external;
}

contract Guardian {

    IGovernorMills public immutable governorMills;
    address public deployer;
    address public pendingDeployer;
    address public rwg;
    address public pendingRwg;
    mapping (uint => bool) public cancellableProposals;

    constructor(IGovernorMills _governorMills, address _rwg) {
        governorMills = _governorMills;
        rwg = _rwg;
        deployer = msg.sender;
    }

    function allowCancel(uint proposalId, bool decision) external {
        require(msg.sender == deployer, "Guardian: not deployer");
        cancellableProposals[proposalId] = decision;
    }

    function executeCancel(uint proposalId) external {
        require(msg.sender == rwg, "Guardian: not rwg");
        require(cancellableProposals[proposalId], "Guardian: not cancellable");
        governorMills.cancel(proposalId);
    }

    function setPendingRwg(address _rwg) external {
        require(msg.sender == rwg, "Guardian: not rwg");
        pendingRwg = _rwg;
    }

    function claimRwg() external {
        require(msg.sender == pendingRwg, "Guardian: not pending rwg");
        rwg = pendingRwg;
        pendingRwg = address(0);
    }

    function setPendingDeployer(address _deployer) external {
        require(msg.sender == deployer, "Guardian: not deployer");
        pendingDeployer = _deployer;
    }

    function claimDeployer() external {
        require(msg.sender == pendingDeployer, "Guardian: not pending deployer");
        deployer = pendingDeployer;
        pendingDeployer = address(0);
    }
}