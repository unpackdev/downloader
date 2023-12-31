// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./AccessControl.sol";

contract TransferLogToken is ERC20, AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(uint256 initialSupply) ERC20("Transfer Log Token", "TLT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) onlyRole(MINTER_ROLE) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) onlyRole(MINTER_ROLE) public {
        _burn(from, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}
