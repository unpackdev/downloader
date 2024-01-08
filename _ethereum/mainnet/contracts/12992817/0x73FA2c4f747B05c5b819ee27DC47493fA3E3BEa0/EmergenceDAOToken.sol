//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./AccessControl.sol";

import "./ERC20Snapshot.sol";
import "./ERC20Pausable.sol";

contract EmergenceDAOToken is ERC20, AccessControl, ERC20Pausable, ERC20Snapshot {

    bytes32 public constant SNAP_ROLE = keccak256("SNAP_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    

    constructor(address admin) ERC20("EmergenceDAO", "EMG") {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MINTER_ROLE, admin);
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Permission denied: MINTER_ROLE");
        _mint(to, amount);
    }

    function snapshot() public {
      require(hasRole(SNAP_ROLE, msg.sender), "Permission denied: SNAP_ROLE");
      _snapshot();
    }

    function pause() public {
      require(hasRole(PAUSER_ROLE, msg.sender), "Permission denied: PAUSER_ROLE");
      _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
    }


}