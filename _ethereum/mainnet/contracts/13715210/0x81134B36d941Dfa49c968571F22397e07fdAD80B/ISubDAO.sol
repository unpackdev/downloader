// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IOrganization.sol";
import "./IProposalsManager.sol";

interface ISubDAO is IOrganization, IExternalProposalsManagerCommands {

    event Proposed(uint256 indexed modelIndex, uint256 indexed presetIndex, bytes32 indexed proposalId);

    struct SubDAOProposalModel {
        address source;
        string uri;
        bool isPreset;
        bytes[] presetValues;
        bytes32[] presetProposals;
        address creationRules;
        address triggeringRules;
        uint256 votingRulesIndex;
        address[][] canTerminateAddresses;
        address[][] validatorsAddresses;
    }

    function presetArrayMaxSize() external view returns(uint256);

    function proposalModels() external view returns(SubDAOProposalModel[] memory);
    function setProposalModels(SubDAOProposalModel[] calldata newValue) external returns(SubDAOProposalModel[] memory oldValue);

    function setInitialProposalModels(SubDAOProposalModel[] calldata newValue) external;

    function setVotingRules(uint256 modelIndex, uint256 votingRulesIndex) external returns(address[] memory oldCanTerminateAddresses, address[] memory oldValidatorsAddresses);
    function setCreationAndTriggeringRules(uint256 modelIndex, address newCreationRules, address newTriggeringRules) external returns(address oldCreationRules, address oldTriggeringRules);
    function setPresetValues(uint256 modelIndex, bytes[] calldata newPresetValues) external returns(bytes[] memory oldPresetValues, bytes32[] memory deprecatedProposalIds);

    function finalizeInit(address firstHost) external;

    function isPersistent(bytes32 proposalId) external view returns(bool result, bool isDeprecated);
}