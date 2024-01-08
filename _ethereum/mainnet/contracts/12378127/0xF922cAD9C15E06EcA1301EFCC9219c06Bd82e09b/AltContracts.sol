// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;
import "./Nutmeg.sol";

// @notice This contract is a version of Nutmeg that contains additional
// interfaces for testing

contract NutmegAltA is Nutmeg {
    //@notice output version string
    function getVersionString()
    external virtual pure returns (string memory) {
        return "nutmegalta";
   }
}

contract NutmegAltB is Nutmeg {
    //@notice output version string
    function getVersionString()
    external virtual pure returns (string memory) {
        return "nutmegaltb";
   }
}

import "./NutDistributor.sol";
import "./SafeERC20.sol";

// @notice This contract is a version of NutDistributor that allows
// the epoch intervals to be changed for testing

contract NutDistributorAltA is NutDistributor {
    //@notice output version string
    function getVersionString()
    external virtual pure override returns (string memory) {
        return "nutdistributoralta";
   }
}

contract NutDistributorAltB is NutDistributor {
    //@notice output version string
    function getVersionString()
    external virtual pure override returns (string memory) {
        return "nutdistributoraltb";
   }
}

import "./MockERC20.sol";

contract MockERC20AltA is
MockERC20("MockERC20AltA", "MOCKERC20ALTA", 18) {
}

contract MockERC20AltB is
MockERC20("MockERC20AltB", "MOCKERC20ALTB", 18) {
}

contract MockERC20AltC is
MockERC20("MockERC20AltC", "MOCKERC20ALTC", 6) {
}

import "./MockCERC20.sol";

contract MockCERC20AltA is MockCERC20Base {
    constructor(address tokenAddr)
    MockCERC20Base(tokenAddr, "MockCERC20 AltA", "MOCKCERC20ALTA", 18) {
    }
}
contract MockCERC20AltB is MockCERC20Base {
    constructor(address tokenAddr)
    MockCERC20Base(tokenAddr, "MockCERC20 AltB", "MOCKCERC20ALTB", 18) {
    }
}
contract MockCERC20AltC is MockCERC20Base {
    constructor(address tokenAddr)
    MockCERC20Base(tokenAddr, "MockCERC20 AltC", "MOCKCERC20ALTC", 6) {
    }
}

import "./CompoundAdapter.sol";
import "./INutmeg.sol";
contract CompoundAdapterAltA is CompoundAdapter {
    constructor(INutmeg nutmegAddr) CompoundAdapter(nutmegAddr) {
    }
}

contract CompoundAdapterAltB is CompoundAdapter {
    constructor(INutmeg nutmegAddr) CompoundAdapter(nutmegAddr) {
    }
}
