// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./ISubDAO.sol";
import "./Organization.sol";
import "./IProposalsManager.sol";
import "./GeneralUtilities.sol";
import "./KnowledgeBase.sol";

contract SubDAO is ISubDAO, Organization {
    using ReflectionUtilities for address;
    using Getters for IOrganization;
    using Bytes32Utilities for bytes32;
    using AddressUtilities for address;

    mapping(bytes32 => bytes) private _ballotData;
    mapping(bytes32 => bytes32) private _ballotOptions;

    SubDAOProposalModel[] private _proposalModels;

    uint256 public override presetArrayMaxSize;

    bool private _initToBeFinalized;

    bool internal _firstProposalSet;

    mapping(bytes32 => bool) private _persistent;
    mapping(bytes32 => bool) private _deprecated;

    constructor(bytes memory lazyInitData) Organization(lazyInitData) {
    }

    function _dynamicMetadataElementLazyInit(bytes memory lazyInitData) internal virtual override returns(bytes memory lazyInitResponse) {
        (_initToBeFinalized, presetArrayMaxSize, lazyInitResponse) = abi.decode(lazyInitData, (bool, uint256, bytes));
        require(!_initToBeFinalized || host == address(0), "Init to be finalized");
        SubDAOProposalModel[] memory models;
        (models, lazyInitResponse) = abi.decode(lazyInitResponse, (SubDAOProposalModel[], bytes));
        if(models.length > 0) {
            _setProposalModels(models);
        }
        lazyInitResponse = abi.encode(_set(abi.decode(lazyInitResponse, (Component[]))));
    }

    function _dynamicMetadataElementSupportsInterface(bytes4 interfaceId) internal virtual pure override returns(bool) {
        return
            interfaceId == type(ISubDAO).interfaceId ||
            interfaceId == this.proposalModels.selector ||
            interfaceId == this.setProposalModels.selector ||
            interfaceId == this.setVotingRules.selector ||
            super._dynamicMetadataElementSupportsInterface(interfaceId);
    }

    function finalizeInit(address firstHost) external override authorizedOnly {
        _initToBeFinalized = false;
        host = firstHost;
        emit Host(address(0), host);
    }

    function proposalModels() external view override returns(SubDAOProposalModel[] memory) {
        return _proposalModels;
    }

    function setProposalModels(SubDAOProposalModel[] calldata newValue) external override authorizedOnly returns(SubDAOProposalModel[] memory oldValue) {
        return _setProposalModels(newValue);
    }

    function setInitialProposalModels(SubDAOProposalModel[] calldata newValue) external override {
        require(!_firstProposalSet, "already done");
        require(msg.sender == initializer, "unauthorized");
        _setProposalModels(newValue);
    }

    function setVotingRules(uint256 modelIndex, uint256 votingRulesIndex) external override authorizedOnly returns(address[] memory oldCanTerminateAddresses, address[] memory oldValidatorsAddresses) {
        require(modelIndex < _proposalModels.length, "index");
        SubDAOProposalModel storage proposalModel = _proposalModels[modelIndex];
        require(votingRulesIndex < proposalModel.canTerminateAddresses.length, "Invalid rule");
        oldCanTerminateAddresses = proposalModel.canTerminateAddresses[votingRulesIndex];
        oldValidatorsAddresses = proposalModel.validatorsAddresses[votingRulesIndex];
        proposalModel.votingRulesIndex = votingRulesIndex;
    }

    function setCreationAndTriggeringRules(uint256 modelIndex, address newCreationRules, address newTriggeringRules) external override authorizedOnly returns(address oldCreationRules, address oldTriggeringRules) {
        SubDAOProposalModel storage proposalModel = _proposalModels[modelIndex];

        oldCreationRules = proposalModel.creationRules;
        oldTriggeringRules = proposalModel.triggeringRules;

        proposalModel.creationRules = newCreationRules;
        proposalModel.triggeringRules = newTriggeringRules;
    }

    function setPresetValues(uint256 modelIndex, bytes[] memory newPresetValues) external override authorizedOnly returns(bytes[] memory oldPresetValues, bytes32[] memory deprecatedProposalIds) {
        SubDAOProposalModel storage proposalModel = _proposalModels[modelIndex];

        require(proposalModel.isPreset, "Not preset");

        oldPresetValues = proposalModel.presetValues;
        deprecatedProposalIds = proposalModel.presetProposals;

        for(uint256 i = 0; i < deprecatedProposalIds.length; i++) {
            bytes32 proposalId = deprecatedProposalIds[i];
            if(proposalId != bytes32(0)) {
                _deprecated[proposalId] = true;
            }
        }

        proposalModel.presetValues = newPresetValues;
        proposalModel.presetProposals = new bytes32[](newPresetValues.length);
    }

    function isPersistent(bytes32 proposalId) public override view returns(bool result, bool isDeprecated) {
        result = _persistent[proposalId];
        isDeprecated = _deprecated[proposalId];
    }

    function createProposalCodeSequence(bytes32 proposalId, IProposalsManager.ProposalCode[] memory codeSequenceInput, address) external authorizedOnly override virtual returns (address[] memory codeSequence, IProposalsManager.ProposalConfiguration memory localConfiguration) {

        uint256 modelIndex = uint160(codeSequenceInput[0].location);
        bytes memory lazyInitData = codeSequenceInput[0].bytecode;

        require(modelIndex < _proposalModels.length, "Invalid model");

        SubDAOProposalModel storage proposalModel = _proposalModels[modelIndex];

        uint256 presetIndex = 0;
        if(proposalModel.isPreset) {
            require((presetIndex = abi.decode(lazyInitData, (uint256))) < proposalModel.presetValues.length, "Invalid preset");
            require(proposalModel.presetProposals[presetIndex] == bytes32(0), "Preset created");
            proposalModel.presetProposals[presetIndex] = proposalId;
            _persistent[proposalId] = true;
            lazyInitData = proposalModel.presetValues[presetIndex];
        }

        emit Proposed(modelIndex, presetIndex, proposalId);

        codeSequence = proposalModel.source.clone().asSingletonArray();
        lazyInitData = ILazyInitCapableElement(codeSequence[0]).lazyInit(abi.encode(proposalModel.uri, lazyInitData));

        (address[] memory collections, uint256[] memory objectIds, uint256[] memory weights) = lazyInitData.length == 0 ? (new address[](0), new uint256[](0), new uint256[](0)) : abi.decode(lazyInitData, (address[], uint256[], uint256[]));
        localConfiguration = IProposalsManager.ProposalConfiguration(
            collections,
            objectIds,
            weights,
            proposalModel.creationRules,
            proposalModel.triggeringRules,
            proposalModel.canTerminateAddresses[proposalModel.votingRulesIndex],
            proposalModel.validatorsAddresses[proposalModel.votingRulesIndex]
        );
    }

    function proposalCanBeFinalized(bytes32 proposalId, IProposalsManager.Proposal memory, bool validationPassed, bool result) external override view virtual returns (bool) {
        (bool persistent, bool deprecated) = isPersistent(proposalId);
        require(!persistent || !deprecated, "deprecated");
        return !persistent && (!validationPassed || result);
    }

    function isVotable(bytes32 proposalId, IProposalsManager.Proposal memory, address, address, bool) external override view returns (bytes memory) {
        return _persistent[proposalId] ? abi.encode(true) : bytes("");
    }

    function _setProposalModels(SubDAOProposalModel[] memory newValue) private returns(SubDAOProposalModel[] memory oldValue) {
        oldValue = _proposalModels;
        delete _proposalModels;
        for(uint256 i = 0; i < newValue.length; i++) {
            SubDAOProposalModel memory proposalModel = newValue[i];
            proposalModel.presetProposals = new bytes32[](proposalModel.isPreset ? proposalModel.presetValues.length : 0);
            require(proposalModel.isPreset || proposalModel.presetValues.length == 0, "Not preset");
            require(presetArrayMaxSize == 0 || proposalModel.presetValues.length <= presetArrayMaxSize, "Preset length");
            require(proposalModel.canTerminateAddresses.length == 0 || proposalModel.votingRulesIndex < proposalModel.canTerminateAddresses.length, "Voting Rules");
            require(proposalModel.canTerminateAddresses.length == proposalModel.validatorsAddresses.length, "Voting Rules");
            _proposalModels.push(proposalModel);
        }
        _firstProposalSet = true;
    }

    function _subjectIsAuthorizedFor(address subject, address location, bytes4 selector, bytes calldata, uint256) internal virtual override view returns(bool, bool) {
        if(location == address(this) && subject == host ) {
            return (true, true);
        }
        if(location == address(this) && selector == this.finalizeInit.selector) {
            return (true, (host == address(0) && _initToBeFinalized));
        }
        return (true, isActive(subject));
    }
}