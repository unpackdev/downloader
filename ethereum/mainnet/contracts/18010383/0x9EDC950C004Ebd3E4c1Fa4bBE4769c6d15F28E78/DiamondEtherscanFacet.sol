// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./OwnableInternal.sol";
import "./LibDiamondEtherscan.sol";

contract DiamondEtherscanFacet is OwnableInternal {
    event Upgraded(address indexed implementation);

    function setDummyImplementation(address _implementation) external onlyOwner {
        LibDiamondEtherscan._setDummyImplementation(_implementation);
    }

    function implementation() external view returns (address) {
        return LibDiamondEtherscan._dummyImplementation();
    }
}
