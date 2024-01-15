// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibDiamond.sol";
import "./LibDiamondEtherscan.sol";

contract DiamondEtherscanFacet {
    function setDummyImplementation(address implementation) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamondEtherscan._setDummyImplementation(implementation);
    }

    function dummyImplementation() external view returns (address) {
        return LibDiamondEtherscan._dummyImplementation();
    }
}
