// SPDX-License-Identifier: BUSL-1.1
// @author cSigma Finance Inc., a Delaware company, for its Real World Credit tokenization protocol
pragma solidity ^0.8.0;

import "./AccessControlFacet.sol";

library MetadataLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("csigma.metadata.storage");

    struct MetadataState {
        string baseURI;
    }

    function diamondStorage() internal pure returns (MetadataState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function getBaseURI() internal view returns (string memory) {
        MetadataState storage metadataState = diamondStorage();
        return metadataState.baseURI;
    }

    function updateBaseURI(string calldata _baseURI) internal {
        AccessControlLib.enforceIsConfigManager();
        MetadataState storage metadataState = diamondStorage();
        metadataState.baseURI = _baseURI;
    }    
}

contract MetadataFacet {
    event UpdateBaseURI(string prevBaseURI, string newBaseURI);

    function getBaseURI() external view returns (string memory) {
        return MetadataLib.getBaseURI();
    }

    function updateBaseURI(string calldata _baseURI) external {
        string memory _prevBaseURI = MetadataLib.getBaseURI();
        MetadataLib.updateBaseURI(_baseURI);
        emit UpdateBaseURI(_prevBaseURI, _baseURI);
    }
}