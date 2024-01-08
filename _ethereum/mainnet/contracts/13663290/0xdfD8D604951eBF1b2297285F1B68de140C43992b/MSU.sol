// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC20PresetFixedSupply.sol";
import "./ERC20Burnable.sol";
import "./AccessControlEnumerable.sol";
import "./Pausable.sol";

contract MSU is ERC20, ERC20Burnable, Pausable, AccessControlEnumerable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(
        string memory name,
        string memory symbol,
        address to
    ) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _mint(to, 500000000 * 10**decimals());
    }

    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "MSU: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "MSU: must have pauser role to unpause"
        );
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "MSU: token transfer while paused");
    }
}
