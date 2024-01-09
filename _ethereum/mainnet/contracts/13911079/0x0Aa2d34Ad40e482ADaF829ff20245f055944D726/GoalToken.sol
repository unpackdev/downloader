//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Snapshot.sol";
import "./ERC20Pausable.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";
import "./ERC20Burnable.sol";


contract GoalToken is ERC20, AccessControl, ERC20Snapshot, ERC20Pausable, ERC20Burnable {
    // Create a new role identifier for the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant SNAP_ROLE = keccak256("SNAP_ROLE");
    
    uint256 public constant INITIAL_SUPPLY = uint248(1e7 ether);                    // 10,000,000 initial

    constructor(address admin) ERC20("Goal", "GOAL") {
        // temp hard code this address, manually override before invoking mint.
        // address multiSIGAddress = 0x8B63834ffaA7868d71db9dC3b7dEbb71Bdcbaa19;
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MINTER_ROLE, admin);
        _mint(admin, INITIAL_SUPPLY);
    }

    function mint(address to, uint256 amount) public {
        // Check that the calling account has the minter role
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(to, amount);
    }

    function pause() public {
        require(hasRole(PAUSER_ROLE, msg.sender), "Caller is not a pauser");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function snapshot() public {
        require(hasRole(SNAP_ROLE, msg.sender), "Caller is not a snapshoter");
        _snapshot();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
    }
}