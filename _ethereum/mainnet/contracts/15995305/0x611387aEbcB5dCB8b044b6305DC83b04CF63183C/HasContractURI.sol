// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract HasContractURI {

    string public contractURI;

    constructor(string memory _contractURI) {
        contractURI = _contractURI;
    }

    /**
     * @dev Internal function to set the contract URI
     * @param _contractURI string URI prefix to assign
     */
    function _setContractURI(string memory _contractURI) internal {
        contractURI = _contractURI;
    }
}
