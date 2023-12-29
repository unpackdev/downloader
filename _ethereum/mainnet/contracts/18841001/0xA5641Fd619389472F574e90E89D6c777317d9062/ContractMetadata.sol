// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IContractMetadata.sol";

abstract contract ContractMetadata is IContractMetadata {
    string public override contractURI;
    string public contractURI2;

    function setContractURI(string memory _uri) external override {
        if (!_canSetContractURI()) {
            revert("Not authorized");
        }

        _setupContractURI(_uri);
    }

    function setContractURI2(string memory _uri) external {
        if (!_canSetContractURI()) {
            revert("Not authorized");
        }

        _setupContractURI2(_uri);
    }

    function _setupContractURI(string memory _uri) internal {
        string memory prevURI = contractURI;
        contractURI = _uri;

        emit ContractURIUpdated(prevURI, _uri);
    }
    function _setupContractURI2(string memory _uri) internal {
        string memory prevURI = contractURI2;
        contractURI2 = _uri;

        emit ContractURIUpdated(prevURI, _uri);
    }

    function _canSetContractURI() internal view virtual returns (bool);
}
