// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./AccessControl.sol";
import "./ERC20.sol";

contract Brew is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("OrcS Brew Token", "BREW") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function mint(address to, uint256 amount) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC20PresetMinterPauser: must have minter role to mint"
        );
        _mint(to, amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
