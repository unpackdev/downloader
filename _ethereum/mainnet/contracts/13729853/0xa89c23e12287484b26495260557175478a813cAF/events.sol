// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma abicoder v2;

import "./helpers.sol";

contract Events is Helpers {
    event LogSubmit(
        Position position,
        string actionId,
        bytes32 indexed actionIdHashHash,
        address sourceDsaSender,
        uint256 sourceDsaId,
        uint256 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 indexed vnonce,
        bytes metadata
    );

    event LogSubmitSystem(
        Position position,
        string systemActionId,
        bytes32 indexed systemActionIdHash,
        address gnosisSafe,
        address indexed sender,
        uint256 indexed vnonceSystem,
        bytes metadata
    );

    event LogRebalanceSystem(
        Position position,
        string systemActionId,
        bytes32 indexed systemActionIdHash,
        address gnosisSafe,
        address indexed sender,
        uint256 indexed vnonceSystem,
        bytes metadata
    );

    event LogRevert(
        Position position,
        string actionId,
        bytes32 indexed actionIdHashHash,
        address sourceDsaSender,
        uint256 sourceDsaId,
        uint256 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 indexed vnonce,
        bytes metadata
    );
    
    event LogValidate(
        Spell[] sourceSpells,
        Position position,
        string actionId,
        bytes32 indexed actionIdHash,
        address sourceDsaSender,
        uint256 sourceDsaId,
        uint256 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 indexed vnonce,
        bytes metadata
    );

    event LogSourceRevert(
        Spell[] sourceSpells,
        Spell[] sourceRevertSpells,
        Position position,
        string actionId,
        bytes32 indexed actionIdHash,
        address sourceDsaSender,
        uint256 sourceDsaId,
        uint256 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 indexed vnonce,
        bytes metadata
    );
    
    event LogExecute(
        Spell[] sourceSpells,
        Spell[] targetSpells,
        Position position,
        string actionId,
        bytes32 indexed actionIdHash,
        address sourceDsaSender,
        uint256 sourceDsaId,
        uint256 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 indexed vnonce,
        bytes metadata
    );

    event LogTargetRevert(
        Spell[] sourceSpells,
        Position position,
        string actionId,
        bytes32 indexed actionIdHash,
        address sourceDsaSender,
        uint256 sourceDsaId,
        uint256 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 indexed vnonce,
        bytes metadata
    );

    error ErrorSourceFailed(uint256 vnonce, uint256 sourceChainId, uint256 targetChainId);
    error ErrorTargetFailed(uint256 vnonce, uint256 sourceChainId, uint256 targetChainId);
}