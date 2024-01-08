// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IArmorMaster.sol";
import "./Ownable.sol";
import "./Bytes32.sol";

/**
 * @dev Each arCore contract is a module to enable simple communication and interoperability. ArmorMaster.sol is master.
**/
contract ArmorModule {
    IArmorMaster internal _master;

    using Bytes32 for bytes32;

    modifier onlyOwner() {
        require(msg.sender == Ownable(address(_master)).owner(), "only owner can call this function");
        _;
    }

    modifier doKeep() {
        _master.keep();
        _;
    }

    modifier onlyModule(bytes32 _module) {
        string memory message = string(abi.encodePacked("only module ", _module.toString()," can call this function"));
        require(msg.sender == getModule(_module), message);
        _;
    }

    /**
     * @dev Used when multiple can call.
    **/
    modifier onlyModules(bytes32 _moduleOne, bytes32 _moduleTwo) {
        string memory message = string(abi.encodePacked("only module ", _moduleOne.toString()," or ", _moduleTwo.toString()," can call this function"));
        require(msg.sender == getModule(_moduleOne) || msg.sender == getModule(_moduleTwo), message);
        _;
    }

    function initializeModule(address _armorMaster) internal {
        require(address(_master) == address(0), "already initialized");
        require(_armorMaster != address(0), "master cannot be zero address");
        _master = IArmorMaster(_armorMaster);
    }

    function changeMaster(address _newMaster) external onlyOwner {
        _master = IArmorMaster(_newMaster);
    }

    function getModule(bytes32 _key) internal view returns(address) {
        return _master.getModule(_key);
    }
}
