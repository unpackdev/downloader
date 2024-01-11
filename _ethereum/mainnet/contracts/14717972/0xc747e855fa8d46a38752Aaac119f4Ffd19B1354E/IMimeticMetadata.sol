// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IMimeticMetadata { 
    struct Generation {
        bool enabled;
        bool loaded;
        bool locked;
        bool sticky;
        string baseURI;
    }

    event GenerationChange(uint256 _layerId, uint256 _tokenId);

    function loadGeneration(uint256 _layerId, bool _enabled, bool _locked, bool _sticky, string memory _baseURI) external;

    function toggleGeneration(uint256 _layerId) external;
}
