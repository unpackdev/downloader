// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Interface for a Bitgem staking pool
 */
interface IProposal {
    enum ProposalType {CREATE_POOL, FUND_PROJECT, CHANGE_FEE, UPDATE_ALLOWLIST}

    enum ProposalStatus {NOT_FUNDED, ACTIVE, PASSED, FAILED, EXECUTED, CLOSED}

    event ProposalCreated(address creator, address pool, uint256 proposalHash);

    event ProposalExecuted(uint256 proposalHash);

    event ProposalClosed(uint256 proposalHash);

    function creator() external view returns (address);

    function title() external view returns (string memory);

    function funder() external view returns (address);

    function expiration() external view returns (uint256);

    function status() external view returns (ProposalStatus);

    function proposalData() external view returns (address);

    function proposalType() external view returns (ProposalType);

    function setMultiToken(address token) external;

    function setGovernor(address gov) external;

    function fund() external payable;

    function execute() external;

    function close() external;

    function initialize(
        address,
        string memory,
        address,
        ProposalType
    ) external;
}
