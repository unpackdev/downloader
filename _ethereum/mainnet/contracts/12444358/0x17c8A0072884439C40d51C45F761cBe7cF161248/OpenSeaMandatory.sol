// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableOperatorControl.sol";

/**
 * Functions required by OpenSea to get contract level metadata and collection Owner
 */
contract OpenSeaMandatory is OwnableOperatorControl {
    string private _contractURI;
    address public proxyRegistryAddress;

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory contractURI_) public onlyOwner {
        _contractURI = contractURI_;
    }
}
