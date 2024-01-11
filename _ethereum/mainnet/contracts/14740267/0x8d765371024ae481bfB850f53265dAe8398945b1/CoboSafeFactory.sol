// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.7.6;

import "Pausable.sol";

import "Ownable.sol";
import "CoboSafeModule.sol";

contract CoboSafeFactory is TransferOwnable, Pausable {
    string public constant NAME = "Cobo Safe Factory";
    string public constant VERSION = "0.3.0";

    address[] public modules;
    mapping(address => address) public safeToModule;

    event NewModule(
        address indexed safe,
        address indexed module,
        address indexed sender
    );

    function modulesSize() public view returns (uint256) {
        return modules.length;
    }

    function createModule(address _safe)
        external
        whenNotPaused
        returns (address _module)
    {
        require(safeToModule[_safe] == address(0), "Module already created");
        bytes memory bytecode = type(CoboSafeModule).creationCode;
        bytes memory creationCode = abi.encodePacked(
            bytecode,
            abi.encode(_safe)
        );
        uint256 moduleIndex = modulesSize();
        bytes32 salt = keccak256(abi.encodePacked(address(this), moduleIndex));

        assembly {
            _module := create2(
                0,
                add(creationCode, 32),
                mload(creationCode),
                salt
            )
        }
        require(_module != address(0), "Failed to create module");
        modules.push(_module);
        safeToModule[_safe] = _module;

        emit NewModule(_safe, _module, _msgSender());
    }

    function setPaused(bool paused) external onlyOwner {
        if (paused) _pause();
        else _unpause();
    }
}
