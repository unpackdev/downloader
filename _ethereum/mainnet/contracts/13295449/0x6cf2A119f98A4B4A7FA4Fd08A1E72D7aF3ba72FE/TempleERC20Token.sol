pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later

import "./ERC20.sol";
import "./IERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./AccessControl.sol";

contract TempleERC20Token is ERC20, ERC20Burnable, Pausable, Ownable, AccessControl {
    bytes32 public constant CAN_MINT = keccak256("CAN_MINT");

    constructor() ERC20("Temple", "TEMPLE") {
        _setupRole(DEFAULT_ADMIN_ROLE, owner());
    }

    /**
     * For use in emergencies to pause all token transfers
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * Revert back to normal operations once P0 which caused pause has been
     * triaged and fixed.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) external {
      require(hasRole(CAN_MINT, msg.sender), "Caller cannot mint");
      _mint(to, amount);
    }

    function addMinter(address account) external onlyOwner {
        grantRole(CAN_MINT, account);
    }

    function removeMinter(address account) external onlyOwner {
        revokeRole(CAN_MINT, account);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}